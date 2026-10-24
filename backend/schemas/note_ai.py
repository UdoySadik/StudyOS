"""Pydantic schemas for AI Note Summarizer and Concept Explainer."""

from typing import List, Optional
from pydantic import BaseModel, Field


class NoteSummarizeRequest(BaseModel):
    topic_id: Optional[int] = Field(default=None, description="Topic ID to read notes from")
    note_content: Optional[str] = Field(default=None, description="Direct Markdown notes to summarize")
    summary_style: str = Field(
        default="key_takeaways",
        description="Style of summary: 'key_takeaways', 'executive', 'bullet_points', 'cheat_sheet'",
    )
    max_bullets: int = Field(default=5, ge=2, le=15, description="Max bullet points for bulleted styles")
    model: Optional[str] = Field(default=None, description="Specific Ollama model name to use if available")


class NoteSummarizeResponse(BaseModel):
    summary_markdown: str = Field(..., description="The generated Markdown summary")
    key_takeaways: List[str] = Field(default_factory=list, description="Extracted key takeaways")
    model_used: str = Field(..., description="Model or engine used: 'ollama:<name>' or 'builtin-offline'")
    word_count: int = Field(default=0, description="Word count of summary")
    reading_time_minutes: float = Field(default=0.0, description="Estimated reading time in minutes")


class ConceptExplainRequest(BaseModel):
    concept: str = Field(..., min_length=2, max_length=150, description="The concept or term to explain")
    context: Optional[str] = Field(default=None, description="Optional surrounding notes context")
    depth: str = Field(
        default="intermediate",
        description="Depth of explanation: 'beginner', 'intermediate', 'expert', 'analogies'",
    )
    model: Optional[str] = Field(default=None, description="Specific Ollama model name to use if available")


class ConceptExplainResponse(BaseModel):
    concept: str = Field(..., description="The concept explained")
    depth: str = Field(..., description="Depth level used")
    explanation_markdown: str = Field(..., description="Full structured Markdown explanation")
    key_points: List[str] = Field(default_factory=list, description="Key takeaways or summary points")
    analogy: Optional[str] = Field(default=None, description="Real-world analogy if generated")
    example_snippet: Optional[str] = Field(default=None, description="Code or diagram snippet if applicable")
    model_used: str = Field(..., description="Model or engine used")
