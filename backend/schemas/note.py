"""Pydantic schemas for Note endpoints."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class NoteUpsert(BaseModel):
    """Create or update a note — content only, topic_id in URL."""
    content: str


class NoteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    topic_id: int
    content: str
    updated_at: datetime
