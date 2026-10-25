"""FastAPI router for Local Textbook & Paper PDF Q&A with RAG."""

import re
import json
import math
from typing import List, Optional, Tuple, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from database import get_db
from models.document import Document, DocumentChunk
from models.topic import Topic
from models.roadmap import Roadmap
from routers.ai_planner import check_ollama_connection, call_ollama_generate
from schemas.document_rag import (
    DocumentCreate,
    DocumentResponse,
    DocumentDetailResponse,
    DocumentChunkResponse,
    Citation,
    RAGQueryRequest,
    RAGQueryResponse,
)

router = APIRouter(prefix="/documents", tags=["documents"])


# ── Text Chunking and Tokenization Utilities ──────────────────────────────────

STOP_WORDS = {
    "what", "is", "are", "the", "a", "an", "in", "on", "of", "at", "to", "for",
    "and", "or", "as", "by", "with", "from", "it", "this", "that", "these", "those",
    "how", "why", "who", "when", "where", "can", "could", "would", "should", "do", "does", "did"
}

def _tokenize(text: str) -> List[str]:
    """Extract lowercased alphanumeric tokens with length >= 2."""
    return [w.lower() for w in re.findall(r"\b[A-Za-z0-9_\-]{2,40}\b", text)]


def _extract_snippet(content: str, query_tokens: List[str], max_len: int = 180) -> str:
    """Extract a representative snippet around the most relevant query tokens."""
    content_clean = content.replace("\n", " ").strip()
    if len(content_clean) <= max_len:
        return content_clean

    substantive = [t for t in query_tokens if t not in STOP_WORDS and len(t) >= 3]
    tokens = substantive if substantive else [t for t in query_tokens if len(t) >= 2]

    sentences = re.split(r"(?<=[.!?])\s+", content_clean)
    if sentences:
        best_sentence = max(sentences, key=lambda s: sum(1 for t in tokens if t in s.lower()))
        if any(t in best_sentence.lower() for t in tokens):
            if len(best_sentence) <= max_len:
                return best_sentence
            # If the sentence itself is longer than max_len, center around primary matched keyword
            pos = -1
            b_lower = best_sentence.lower()
            for t in sorted(tokens, key=len, reverse=True):
                p = b_lower.find(t)
                if p != -1:
                    pos = p
                    break
            start = max(0, pos - 20)
            end = min(len(best_sentence), start + max_len)
            snip = best_sentence[start:end].strip()
            return f"...{snip}..." if start > 0 else f"{snip}..."

    return content_clean[:max_len - 3] + "..."


def _build_term_vector(tokens: List[str]) -> Dict[str, float]:
    """Compute normalized term frequencies for a token sequence."""
    if not tokens:
        return {}
    counts: Dict[str, int] = {}
    for t in tokens:
        counts[t] = counts.get(t, 0) + 1
    total = len(tokens)
    return {k: round(v / total, 5) for k, v in counts.items()}


def _split_into_chunks(raw_text: str, target_chunk_size: int = 500, overlap: int = 80) -> List[Tuple[int, str, int]]:
    """
    Split document text into structured overlapping chunks.
    Returns list of tuples: (chunk_index, chunk_content, estimated_page_number).
    """
    # Check for explicit page markers like '--- Page 1 ---' or 'Page 1'
    page_splits = re.split(r"(?:^|\n)\s*---+\s*(?:Page\s*(\d+)|p\.?\s*(\d+))\s*---+", raw_text, flags=re.IGNORECASE)

    chunks = []
    chunk_index = 0

    if len(page_splits) > 1:
        cur_page = 1
        i = 0
        while i < len(page_splits):
            part = page_splits[i]
            if not part:
                i += 1
                continue
            if part.isdigit():
                cur_page = int(part)
                i += 1
                continue

            cleaned = part.strip()
            if cleaned:
                sub_chunks = _slice_text_with_overlap(cleaned, target_chunk_size, overlap)
                for sc in sub_chunks:
                    chunks.append((chunk_index, sc, cur_page))
                    chunk_index += 1
            i += 1
    else:
        # Standard sliding window with paragraph awareness
        paragraphs = re.split(r"\n\s*\n+", raw_text)
        current_buffer = []
        current_len = 0
        cur_page = 1

        for para in paragraphs:
            p_strip = para.strip()
            if not p_strip:
                continue

            if current_len + len(p_strip) > target_chunk_size and current_buffer:
                chunk_text = "\n\n".join(current_buffer)
                chunks.append((chunk_index, chunk_text, cur_page))
                chunk_index += 1

                # Overlap: keep the last paragraph or a tail slice if possible
                overlap_text = current_buffer[-1] if len(current_buffer[-1]) < target_chunk_size // 2 else current_buffer[-1][-overlap:]
                current_buffer = [overlap_text, p_strip]
                current_len = len(overlap_text) + len(p_strip)
            else:
                current_buffer.append(p_strip)
                current_len += len(p_strip)

            # Estimate ~1500 chars per page
            cur_page = max(1, math.ceil((len(" ".join([c[1] for c in chunks])) + current_len) / 1500))

        if current_buffer:
            chunk_text = "\n\n".join(current_buffer)
            chunks.append((chunk_index, chunk_text, cur_page))

    # Fallback if no chunks formed
    if not chunks and raw_text.strip():
        chunks.append((0, raw_text.strip(), 1))

    return chunks


def _slice_text_with_overlap(text: str, size: int, overlap: int) -> List[str]:
    """Helper to slice continuous string with fixed sliding overlap."""
    if len(text) <= size:
        return [text]
    results = []
    start = 0
    while start < len(text):
        end = min(start + size, len(text))
        slice_str = text[start:end].strip()
        if slice_str:
            results.append(slice_str)
        if end >= len(text):
            break
        start += (size - overlap)
    return results


def _compute_relevance_score(
    query_tokens: List[str],
    chunk_tokens: List[str],
    chunk_term_vec: Dict[str, float],
    query_text: str,
    chunk_text: str,
) -> float:
    """
    Compute hybrid relevance score between query and document chunk.
    Combines exact phrase matching, substantive token overlap ratio, and vector dot product.
    """
    if not query_tokens or not chunk_tokens:
        return 0.0

    # 1. Exact phrase boost
    phrase_score = 0.0
    if query_text.lower() in chunk_text.lower():
        phrase_score = 0.40

    # 2. Token overlap ratio (prioritize substantive non-stopwords)
    substantive_query = [t for t in query_tokens if t not in STOP_WORDS]
    eval_tokens = substantive_query if substantive_query else query_tokens

    matched_tokens = set(eval_tokens).intersection(set(chunk_tokens))
    token_score = len(matched_tokens) / len(set(eval_tokens))

    # 3. Vector similarity
    dot_product = 0.0
    for t in matched_tokens:
        dot_product += chunk_term_vec.get(t, 0.0)

    # Composite weighted score
    raw_score = (phrase_score * 0.35) + (token_score * 0.45) + (min(dot_product * 5.0, 1.0) * 0.20)
    return max(0.01, min(0.99, round(raw_score, 3)))


# ── Document CRUD Endpoints ──────────────────────────────────────────────────

@router.get("/", response_model=List[DocumentResponse])
def list_documents(
    roadmap_id: Optional[int] = Query(None),
    topic_id: Optional[int] = Query(None),
    q: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """List indexed documents with optional roadmap, topic, or keyword search."""
    query = db.query(Document)
    if roadmap_id is not None:
        query = query.filter(Document.roadmap_id == roadmap_id)
    if topic_id is not None:
        query = query.filter(Document.topic_id == topic_id)
    if q and q.strip():
        term = f"%{q.strip()}%"
        query = query.filter(Document.title.ilike(term))

    docs = query.order_by(Document.created_at.desc()).all()

    # Hydrate topic and roadmap titles
    results = []
    for d in docs:
        topic_title = None
        roadmap_title = None
        if d.topic_id:
            t = db.query(Topic).filter(Topic.id == d.topic_id).first()
            if t:
                topic_title = t.title
        if d.roadmap_id:
            rm = db.query(Roadmap).filter(Roadmap.id == d.roadmap_id).first()
            if rm:
                roadmap_title = rm.title

        results.append(DocumentResponse(
            id=d.id,
            roadmap_id=d.roadmap_id,
            topic_id=d.topic_id,
            topic_title=topic_title,
            roadmap_title=roadmap_title,
            title=d.title,
            doc_type=d.doc_type,
            file_path=d.file_path,
            total_pages=d.total_pages,
            total_chunks=d.total_chunks,
            created_at=d.created_at,
        ))
    return results


@router.get("/{document_id}", response_model=DocumentDetailResponse)
def get_document(document_id: int, db: Session = Depends(get_db)):
    """Get full document details along with all indexed chunks."""
    doc = db.query(Document).filter(Document.id == document_id).first()
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")

    topic_title = None
    roadmap_title = None
    if doc.topic_id:
        t = db.query(Topic).filter(Topic.id == doc.topic_id).first()
        if t:
            topic_title = t.title
    if doc.roadmap_id:
        rm = db.query(Roadmap).filter(Roadmap.id == doc.roadmap_id).first()
        if rm:
            roadmap_title = rm.title

    chunks_data = [
        DocumentChunkResponse(
            id=c.id,
            document_id=c.document_id,
            chunk_index=c.chunk_index,
            page_number=c.page_number,
            content=c.content,
            word_count=c.word_count,
            created_at=c.created_at,
        )
        for c in doc.chunks
    ]

    return DocumentDetailResponse(
        id=doc.id,
        roadmap_id=doc.roadmap_id,
        topic_id=doc.topic_id,
        topic_title=topic_title,
        roadmap_title=roadmap_title,
        title=doc.title,
        doc_type=doc.doc_type,
        file_path=doc.file_path,
        total_pages=doc.total_pages,
        total_chunks=doc.total_chunks,
        created_at=doc.created_at,
        chunks=chunks_data,
    )


@router.post("/", response_model=DocumentDetailResponse, status_code=status.HTTP_201_CREATED)
def create_document(doc_in: DocumentCreate, db: Session = Depends(get_db)):
    """Upload / Index a document into searchable RAG chunks."""
    if doc_in.topic_id and not db.query(Topic).filter(Topic.id == doc_in.topic_id).first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Topic {doc_in.topic_id} not found.")
    if doc_in.roadmap_id and not db.query(Roadmap).filter(Roadmap.id == doc_in.roadmap_id).first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Roadmap {doc_in.roadmap_id} not found.")

    chunk_tuples = _split_into_chunks(doc_in.content)
    max_page = max([c[2] for c in chunk_tuples], default=1)

    new_doc = Document(
        roadmap_id=doc_in.roadmap_id,
        topic_id=doc_in.topic_id,
        title=doc_in.title.strip(),
        doc_type=doc_in.doc_type,
        file_path=doc_in.file_path,
        total_pages=max_page,
        total_chunks=len(chunk_tuples),
    )
    db.add(new_doc)
    db.flush()

    chunks_to_create = []
    for c_idx, content_str, page_num in chunk_tuples:
        tokens = _tokenize(content_str)
        term_vec = _build_term_vector(tokens)
        chunk_obj = DocumentChunk(
            document_id=new_doc.id,
            chunk_index=c_idx,
            page_number=page_num,
            content=content_str,
            word_count=len(tokens),
            embedding_json=json.dumps(term_vec),
        )
        chunks_to_create.append(chunk_obj)

    db.add_all(chunks_to_create)
    db.commit()
    db.refresh(new_doc)

    return get_document(new_doc.id, db)


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(document_id: int, db: Session = Depends(get_db)):
    """Delete a document and all its indexed chunks."""
    doc = db.query(Document).filter(Document.id == document_id).first()
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")
    db.delete(doc)
    db.commit()


# ── RAG Retrieval and Question Answering ─────────────────────────────────────

@router.post("/query", response_model=RAGQueryResponse)
def query_documents_rag(req: RAGQueryRequest, db: Session = Depends(get_db)):
    """
    Perform local Retrieval-Augmented Generation (RAG):
    1. Hybrid retrieval over document chunks to find top matching context passages.
    2. Synthesize answers with citations using local Ollama or built-in offline extractor.
    """
    query_text = req.query.strip()
    query_tokens = _tokenize(query_text)
    if not query_tokens:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Query contains no valid keywords.")

    # Base query for chunks
    chunk_query = db.query(DocumentChunk, Document.title).join(Document, DocumentChunk.document_id == Document.id)
    if req.document_ids:
        chunk_query = chunk_query.filter(DocumentChunk.document_id.in_(req.document_ids))

    all_chunks = chunk_query.all()
    if not all_chunks:
        return RAGQueryResponse(
            query=query_text,
            answer_markdown="### ⚠️ No Documents Indexed\n\nPlease add or index at least one study paper, textbook, or document before asking questions.",
            citations=[],
            model_used="builtin-offline",
            retrieval_count=0,
        )

    # Score each chunk
    scored_candidates = []
    for chunk_obj, doc_title in all_chunks:
        try:
            term_vec = json.loads(chunk_obj.embedding_json or "{}")
        except Exception:
            term_vec = {}
        c_tokens = _tokenize(chunk_obj.content)
        score = _compute_relevance_score(
            query_tokens=query_tokens,
            chunk_tokens=c_tokens,
            chunk_term_vec=term_vec,
            query_text=query_text,
            chunk_text=chunk_obj.content,
        )
        if score > 0.05:
            scored_candidates.append((score, chunk_obj, doc_title))

    # Sort descending by score
    scored_candidates.sort(key=lambda x: x[0], reverse=True)
    top_candidates = scored_candidates[:req.top_k]

    if not top_candidates:
        # If no chunk met threshold, take top 1 with minimal score
        top_candidates = [(0.10, all_chunks[0][0], all_chunks[0][1])]

    # Build citations list
    citations = []
    for score, c_obj, doc_title in top_candidates:
        snippet_text = _extract_snippet(c_obj.content, query_tokens, 180)

        citations.append(Citation(
            document_id=c_obj.document_id,
            document_title=doc_title,
            chunk_index=c_obj.chunk_index,
            page_number=c_obj.page_number,
            snippet=snippet_text,
            relevance_score=score,
        ))

    # Synthesis via Ollama or Offline Engine
    model_used = "builtin-offline"
    answer_markdown = ""

    ollama_ok, models = check_ollama_connection()
    if ollama_ok and models:
        chosen_model = req.model if req.model in models else models[0]
        context_passages = []
        for idx, (score, c_obj, doc_title) in enumerate(top_candidates, start=1):
            context_passages.append(
                f"[Source {idx}: '{doc_title}', Page {c_obj.page_number}]\n{c_obj.content}"
            )
        combined_context = "\n\n---\n\n".join(context_passages)

        prompt = (
            f"You are a technical research mentor and academic study assistant.\n"
            f"Answer the user's question based strictly on the provided textbook/paper passages below.\n"
            f"Cite the relevant passages using [Source N] when stating facts.\n\n"
            f"Context Passages:\n{combined_context}\n\n"
            f"Question: {query_text}\n\n"
            f"Provide an informative, structured Markdown answer:"
        )
        ollama_resp = call_ollama_generate(prompt=prompt, model=chosen_model, timeout=25.0)
        if ollama_resp and len(ollama_resp.strip()) > 30:
            answer_markdown = ollama_resp.strip()
            model_used = f"ollama:{chosen_model}"

    # Fallback deterministic offline answer synthesis
    if not answer_markdown:
        top_chunk = top_candidates[0][1]
        top_doc_title = top_candidates[0][2]
        top_page = top_chunk.page_number

        # Extract best matching sentences
        sentences = re.split(r"(?<=[.!?])\s+", top_chunk.content)
        matched_sentences = []
        for s in sentences:
            s_clean = s.strip()
            if any(q_tok in s_clean.lower() for q_tok in query_tokens):
                if s_clean not in matched_sentences:
                    matched_sentences.append(s_clean)

        if not matched_sentences and sentences:
            matched_sentences = sentences[:2]

        direct_answer = " ".join(matched_sentences[:3])

        evidence_items = []
        for idx, (sc, c_obj, d_title) in enumerate(top_candidates, start=1):
            evidence_items.append(
                f"- **[Source {idx}: {d_title} (p. {c_obj.page_number})]** (Relevance: {int(sc * 100)}%)\n"
                f"  > *\"{c_obj.content[:160].replace(chr(10), ' ').strip()}...\"*"
            )

        answer_markdown = f"""### 📖 Answer to: "{query_text}"

{direct_answer}

#### 🔍 Supporting Evidence & Citations
{chr(10).join(evidence_items)}

---
*Generated via StudyOS Local Document Intelligence ({model_used})*
"""

    return RAGQueryResponse(
        query=query_text,
        answer_markdown=answer_markdown,
        citations=citations,
        model_used=model_used,
        retrieval_count=len(citations),
    )
