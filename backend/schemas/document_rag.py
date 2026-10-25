"""Pydantic schemas for Local Document Intelligence and RAG Q&A."""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class DocumentCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=255, description="Document title")
    doc_type: str = Field(default="paper", description="Document type: textbook, paper, documentation, notes")
    content: str = Field(..., min_length=10, description="Full text content to index into chunks")
    file_path: Optional[str] = Field(default=None, max_length=500, description="Local file path if uploaded")
    topic_id: Optional[int] = Field(default=None, description="Optional linked topic ID")
    roadmap_id: Optional[int] = Field(default=None, description="Optional linked roadmap ID")


class DocumentChunkResponse(BaseModel):
    id: int
    document_id: int
    chunk_index: int
    page_number: int
    content: str
    word_count: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class DocumentResponse(BaseModel):
    id: int
    roadmap_id: Optional[int] = None
    topic_id: Optional[int] = None
    topic_title: Optional[str] = None
    roadmap_title: Optional[str] = None
    title: str
    doc_type: str
    file_path: Optional[str] = None
    total_pages: int
    total_chunks: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class DocumentDetailResponse(DocumentResponse):
    chunks: List[DocumentChunkResponse] = []


class Citation(BaseModel):
    document_id: int
    document_title: str
    chunk_index: int
    page_number: int
    snippet: str
    relevance_score: float = Field(..., description="Similarity score between 0.0 and 1.0")


class RAGQueryRequest(BaseModel):
    query: str = Field(..., min_length=3, max_length=500, description="Question to answer using document context")
    document_ids: Optional[List[int]] = Field(default=None, description="Optional document IDs to scope search")
    top_k: int = Field(default=3, ge=1, le=10, description="Number of top chunks to retrieve")
    model: Optional[str] = Field(default=None, description="Optional Ollama model name")


class RAGQueryResponse(BaseModel):
    query: str
    answer_markdown: str
    citations: List[Citation] = []
    model_used: str
    retrieval_count: int
