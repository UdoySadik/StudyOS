"""Pydantic schemas for Topic endpoints."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class TopicCreate(BaseModel):
    phase_id: int
    title: str
    order_index: Optional[int] = 0


class TopicUpdate(BaseModel):
    title: Optional[str] = None
    order_index: Optional[int] = None


class TopicCompleteToggle(BaseModel):
    is_completed: bool


class TopicResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    phase_id: int
    title: str
    is_completed: bool
    order_index: int
    completed_at: Optional[datetime]
    created_at: datetime
