"""Pydantic schemas for Subtopic endpoints."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class SubtopicCreate(BaseModel):
    topic_id: int
    title: str
    order_index: Optional[int] = 0


class SubtopicUpdate(BaseModel):
    title: Optional[str] = None
    is_completed: Optional[bool] = None
    order_index: Optional[int] = None


class SubtopicResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    topic_id: int
    title: str
    is_completed: bool
    order_index: int
    created_at: datetime
