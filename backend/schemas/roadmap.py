"""Pydantic schemas for Roadmap endpoints."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class RoadmapCreate(BaseModel):
    title: str
    description: Optional[str] = None


class RoadmapUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None


class RoadmapResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: Optional[str]
    created_at: datetime
    updated_at: datetime
