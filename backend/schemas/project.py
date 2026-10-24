"""Pydantic schemas for Practice Project Tracker with GitHub links."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class ProjectBase(BaseModel):
    title: str
    description: Optional[str] = None
    github_url: Optional[str] = None
    live_url: Optional[str] = None
    status: str = "not_started"  # not_started, in_progress, completed, on_hold
    difficulty: str = "medium"   # beginner, medium, advanced
    tech_stack: Optional[str] = None


class ProjectCreate(ProjectBase):
    roadmap_id: int
    topic_id: Optional[int] = None


class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    github_url: Optional[str] = None
    live_url: Optional[str] = None
    status: Optional[str] = None
    difficulty: Optional[str] = None
    tech_stack: Optional[str] = None
    topic_id: Optional[int] = None


class ProjectStatusUpdate(BaseModel):
    status: str


class ProjectResponse(ProjectBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    roadmap_id: int
    topic_id: Optional[int] = None
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    roadmap_title: Optional[str] = None
    topic_title: Optional[str] = None
