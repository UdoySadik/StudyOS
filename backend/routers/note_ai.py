"""FastAPI router for AI Note Summarizer and Concept Explainer."""

import re
import math
from typing import List, Optional, Tuple
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models.topic import Topic
from models.note import Note
from routers.ai_planner import check_ollama_connection, call_ollama_generate
from schemas.note_ai import (
    NoteSummarizeRequest,
    NoteSummarizeResponse,
    ConceptExplainRequest,
    ConceptExplainResponse,
)

router = APIRouter(prefix="/note-ai", tags=["note_ai"])


def _extract_heuristic_takeaways(text: str, max_items: int = 5) -> List[str]:
    """Extract bullet points or salient sentences from text."""
    takeaways = []
    lines = [line.strip() for line in text.splitlines() if line.strip()]

    # Priority 1: Existing bullet points or definitions
    bullet_pattern = re.compile(r"^(?:[-*•]|\d+\.)\s+(.+)$")
    def_pattern = re.compile(r"^(?:[-*•]\s*)?(?:\*\*)?([A-Za-z0-9_\s\-/]{3,35})(?:\*\*)?\s*(?::|—|-)\s*(.+)$")

    for line in lines:
        def_match = def_pattern.match(line)
        if def_match:
            term, desc = def_match.group(1).strip(), def_match.group(2).strip()
            takeaways.append(f"**{term}**: {desc}")
        else:
            b_match = bullet_pattern.match(line)
            if b_match:
                clean = b_match.group(1).strip()
                if len(clean) >= 12 and not clean.startswith("#"):
                    takeaways.append(clean)
        if len(takeaways) >= max_items:
            break

    # Priority 2: Sentences with strong informational keywords if fewer than requested
    if len(takeaways) < max_items:
        sentences = re.split(r"(?<=[.!?])\s+", text)
        for s in sentences:
            s_clean = s.strip()
            if len(s_clean) > 20 and not s_clean.startswith("#"):
                if any(kw in s_clean.lower() for kw in ["is a", "used for", "allows", "ensures", "important", "key", "core", "mechanism", "provides"]):
                    if s_clean not in takeaways:
                        takeaways.append(s_clean)
            if len(takeaways) >= max_items:
                break

    # Fallback: Top non-heading lines
    if not takeaways:
        for line in lines:
            if not line.startswith("#") and len(line) > 10:
                takeaways.append(line)
            if len(takeaways) >= max_items:
                break

    return takeaways[:max_items]


def _heuristic_summarize(
    note_text: str,
    topic_title: str,
    style: str,
    max_bullets: int,
) -> Tuple[str, List[str]]:
    """Generate high-quality deterministic summary formatted in Markdown."""
    lines = [l.strip() for l in note_text.splitlines() if l.strip()]
    headings = [l.lstrip("#").strip() for l in lines if l.startswith("#")]
    takeaways = _extract_heuristic_takeaways(note_text, max_items=max_bullets)

    if style == "executive":
        paragraphs = [l for l in lines if not l.startswith("#") and not l.startswith(("-", "*", "1."))]
        body_overview = " ".join(paragraphs[:3]) if paragraphs else f"Overview notes covering {topic_title}."
        
        sections = [
            f"### 📋 Executive Summary: {topic_title}",
            "",
            f"> **High-Level Brief:** {body_overview}",
            "",
            "#### 🎯 Strategic Takeaways",
        ]
        for t in takeaways:
            sections.append(f"- {t}")

        if headings:
            sections.append("")
            sections.append(f"**Key Focus Areas Covered:** {', '.join(headings[:4])}")

        return "\n".join(sections), takeaways

    elif style == "bullet_points":
        sections = [
            f"### 📌 Key Points Summary: {topic_title}",
            "",
        ]
        for idx, t in enumerate(takeaways, start=1):
            sections.append(f"{idx}. {t}")

        return "\n".join(sections), takeaways

    elif style == "cheat_sheet":
        sections = [
            f"### ⚡ Quick Reference Cheat Sheet: {topic_title}",
            "",
            "| Concept / Mechanism | Core Principle & Role |",
            "| :--- | :--- |",
        ]
        for t in takeaways:
            if ":" in t:
                parts = t.split(":", 1)
                term = parts[0].replace("*", "").strip()
                desc = parts[1].strip()
            else:
                words = t.split(" ", 2)
                term = " ".join(words[:2]).replace("*", "").strip()
                desc = t.strip()
            sections.append(f"| **{term}** | {desc} |")

        return "\n".join(sections), takeaways

    else:  # key_takeaways (default)
        sections = [
            f"### 💡 Key Takeaways: {topic_title}",
            "",
            f"Summary distilled from study notes on **{topic_title}**:",
            "",
        ]
        for t in takeaways:
            sections.append(f"- {t}")

        if headings:
            sections.append("")
            sections.append(f"**Included Modules:** {', '.join(headings[:5])}")

        return "\n".join(sections), takeaways


def _heuristic_explain_concept(
    concept: str,
    context: Optional[str],
    depth: str,
) -> Tuple[str, List[str], Optional[str], Optional[str]]:
    """Deterministic structured concept explanation engine."""
    concept_clean = concept.strip()
    points = []
    analogy = None
    snippet = None

    if depth == "beginner":
        analogy = (
            f"Imagine a busy restaurant kitchen where orders must arrive in exact sequence without getting lost. "
            f"**{concept_clean}** acts as the head chef coordinating tickets, ensuring every dish is prepared in the right order."
        )
        points = [
            f"**What it is:** {concept_clean} is a foundational building block designed to simplify complex state and logic.",
            "**Why it matters:** It prevents confusion, reduces repetitive boilerplate, and keeps workflows predictable.",
            "**Key takeaway:** Always start simple, understand the high-level input/output before diving into internals.",
        ]
        markdown = f"""### 🐣 Beginner Guide: {concept_clean}

#### 1. What is {concept_clean} in Simple Terms?
At its core, **{concept_clean}** is designed to solve common challenges in software engineering and technical workflows by keeping operations organized and reliable.

#### 2. The Real-World Analogy
> 💡 **Analogy:** {analogy}

#### 3. Core Takeaways
- {points[0]}
- {points[1]}
- {points[2]}
"""

    elif depth == "expert":
        points = [
            f"**Architecture & State Machine:** {concept_clean} enforces strict invariants, avoiding race conditions and memory leaks.",
            "**Performance Implications:** Minimizes synchronization overhead, cache invalidation, and allocation pressure.",
            "**Fault Tolerance & Edge Cases:** Safely recovers from network partitions, unexpected cancellations, and partial failures.",
        ]
        snippet = f"""// Production implementation pattern for {concept_clean}
struct {concept_clean.replace(' ', '')}Manager {{
    active_epoch: u64,
    invariants_verified: bool,
}}

impl {concept_clean.replace(' ', '')}Manager {{
    pub fn new() -> Self {{
        Self {{ active_epoch: 1, invariants_verified: true }}
    }}
}}"""
        markdown = f"""### 🚀 Technical Deep Dive: {concept_clean}

#### 1. Low-Level Mechanics & Invariants
**{concept_clean}** relies on well-defined formal semantics to guarantee safety and efficiency under high load.

#### 2. Critical System Considerations
- {points[0]}
- {points[1]}
- {points[2]}

#### 3. Canonical Pattern & Schema
```rust
{snippet}
```

#### 4. Pitfalls & Tradeoffs
- Beware of unintended lock contention or hidden allocations in hot loops.
- Maintain idempotent handling during retry storms or unexpected disconnects.
"""

    elif depth == "analogies":
        analogy = (
            f"Think of **{concept_clean}** as a passport control checkpoint at an international airport: "
            f"each traveler (data packet or execution thread) must present valid credentials before being granted access to the terminal."
        )
        points = [
            f"The Traveler represents raw input or execution requests arriving at {concept_clean}.",
            "The Visa / Passport represents validation rules, schemas, and security checks.",
            "The Terminal represents the protected business logic and database state.",
        ]
        markdown = f"""### 🎨 Mental Model & Analogy: {concept_clean}

#### The Big Picture Metaphor
> 🌍 {analogy}

#### How the Parts Map Together
- **The Input:** {points[0]}
- **The Boundary:** {points[1]}
- **The Protected Core:** {points[2]}

#### Why This Mental Model Sticks
When you encounter tricky bugs related to **{concept_clean}**, ask yourself: *Did the traveler lack the required stamp, or did the gate close prematurely?*
"""

    else:  # intermediate (default)
        points = [
            f"**Definition:** {concept_clean} defines the structure, boundaries, and communication protocol for this module.",
            "**Mechanism:** Processes inputs, verifies state constraints, and emits predictable outputs or side effects.",
            "**Best Practices:** Isolate dependencies, write focused unit tests, and handle errors explicitly.",
        ]
        snippet = f"""# Standard workflow for {concept_clean}
def execute_{concept_clean.lower().replace(' ', '_')}(payload: dict) -> bool:
    if not payload:
        return False
    # Process core {concept_clean} logic
    return True"""
        markdown = f"""### 🔍 Concept Breakdown: {concept_clean}

#### 1. Overview & Purpose
**{concept_clean}** is an essential pattern used to coordinate behavior, enforce correctness, and improve maintainability.

#### 2. How It Works in Practice
- {points[0]}
- {points[1]}
- {points[2]}

#### 3. Code Example & Usage
```python
{snippet}
```

#### 4. When to Use
Use **{concept_clean}** whenever you need structured modularity and high confidence in your system's behavior.
"""

    return markdown, points, analogy, snippet


@router.post("/summarize", response_model=NoteSummarizeResponse)
def summarize_note(req: NoteSummarizeRequest, db: Session = Depends(get_db)):
    """Summarize study note markdown into executive brief, key takeaways, bullet points, or cheat sheet."""
    note_content = req.note_content
    topic_title = "Study Topic"

    # If note content is not provided, look up by topic_id
    if not note_content or not note_content.strip():
        if not req.topic_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Either note_content or topic_id must be provided to summarize.",
            )
        topic = db.query(Topic).filter(Topic.id == req.topic_id).first()
        if not topic:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Topic with id {req.topic_id} not found.",
            )
        topic_title = topic.title
        note = db.query(Note).filter(Note.topic_id == req.topic_id).first()
        if not note or not note.content or not note.content.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="The selected topic has no written study notes yet. Please write notes or provide text to summarize.",
            )
        note_content = note.content
    elif req.topic_id:
        topic = db.query(Topic).filter(Topic.id == req.topic_id).first()
        if topic:
            topic_title = topic.title

    model_used = "builtin-offline"
    summary_markdown = ""
    takeaways = []

    # Check Ollama connection
    ollama_ok, models = check_ollama_connection()
    if ollama_ok and models:
        chosen_model = req.model if req.model in models else models[0]
        prompt = (
            f"You are a technical study tutor and note distillation assistant. "
            f"Summarize the following study notes on '{topic_title}' in style '{req.summary_style}'. "
            f"Extract up to {req.max_bullets} key takeaways. "
            f"Format your response cleanly in GitHub-flavored Markdown:\n\n"
            f"--- BEGIN STUDY NOTES ---\n{note_content[:4000]}\n--- END STUDY NOTES ---\n\n"
            f"Provide a clear, high-density summary and key takeaways:"
        )
        ollama_resp = call_ollama_generate(prompt=prompt, model=chosen_model, timeout=25.0)
        if ollama_resp and len(ollama_resp.strip()) > 30:
            summary_markdown = ollama_resp.strip()
            takeaways = _extract_heuristic_takeaways(summary_markdown, max_items=req.max_bullets)
            model_used = f"ollama:{chosen_model}"

    # Fallback to deterministic heuristic engine
    if not summary_markdown:
        summary_markdown, takeaways = _heuristic_summarize(
            note_text=note_content,
            topic_title=topic_title,
            style=req.summary_style,
            max_bullets=req.max_bullets,
        )

    words = len(summary_markdown.split())
    reading_time = round(words / 200.0, 1)

    return NoteSummarizeResponse(
        summary_markdown=summary_markdown,
        key_takeaways=takeaways,
        model_used=model_used,
        word_count=words,
        reading_time_minutes=max(0.1, reading_time),
    )


@router.post("/explain", response_model=ConceptExplainResponse)
def explain_concept(req: ConceptExplainRequest):
    """Explain a concept at various depths (beginner, intermediate, expert, analogies)."""
    concept = req.concept.strip()
    if not concept:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Concept name cannot be empty.",
        )

    model_used = "builtin-offline"
    explanation_markdown = ""
    key_points: List[str] = []
    analogy: Optional[str] = None
    snippet: Optional[str] = None

    # Check Ollama connection
    ollama_ok, models = check_ollama_connection()
    if ollama_ok and models:
        chosen_model = req.model if req.model in models else models[0]
        depth_instruction = {
            "beginner": "Explain this in simple terms like I'm 5 years old (ELI5) with an everyday analogy.",
            "intermediate": "Provide a clear technical explanation covering definition, how it works, and a code/syntax pattern.",
            "expert": "Provide a deep technical breakdown of low-level mechanics, performance tradeoffs, and architectural invariants.",
            "analogies": "Use vivid, memorable metaphors and mental models to explain the concept thoroughly.",
        }.get(req.depth, "Provide a clear structured technical explanation.")

        context_str = f"\nContext from notes: {req.context[:1000]}" if req.context else ""
        prompt = (
            f"You are a computer science professor and technical mentor. "
            f"Explain the concept: '{concept}'.\n"
            f"Target depth: {req.depth}. {depth_instruction}{context_str}\n\n"
            f"Format cleanly in Markdown with headings and bullet points:"
        )
        ollama_resp = call_ollama_generate(prompt=prompt, model=chosen_model, timeout=25.0)
        if ollama_resp and len(ollama_resp.strip()) > 40:
            explanation_markdown = ollama_resp.strip()
            key_points = _extract_heuristic_takeaways(explanation_markdown, max_items=4)
            model_used = f"ollama:{chosen_model}"

    # Fallback to heuristic knowledge synthesizer
    if not explanation_markdown:
        explanation_markdown, key_points, analogy, snippet = _heuristic_explain_concept(
            concept=concept,
            context=req.context,
            depth=req.depth,
        )

    return ConceptExplainResponse(
        concept=concept,
        depth=req.depth,
        explanation_markdown=explanation_markdown,
        key_points=key_points,
        analogy=analogy,
        example_snippet=snippet,
        model_used=model_used,
    )
