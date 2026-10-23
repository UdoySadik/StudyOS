"""Pydantic schemas for Topic Learning Resources (books, course URLs, PDFs, docs, etc.)."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class ResourceBase(BaseModel):
    title: str
    resource_type: str = "article"  # "book", "video", "article", "course", "pdf", "doc", "github"
    url: Optional[str] = None
    notes: Optional[str] = None


class ResourceCreate(ResourceBase):
    topic_id: int


class ResourceUpdate(BaseModel):
    title: Optional[str] = None
    resource_type: Optional[str] = None
    url: Optional[str] = None
    notes: Optional[str] = None
    is_completed: Optional[bool] = None


class ResourceCompleteToggle(BaseModel):
    is_completed: bool


class ResourceResponse(ResourceBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    topic_id: int
    is_completed: bool
    created_at: Optional[datetime] = None
