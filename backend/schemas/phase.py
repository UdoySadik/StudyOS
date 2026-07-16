"""Pydantic schemas for Phase endpoints."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class PhaseCreate(BaseModel):
    roadmap_id: int
    title: str
    order_index: Optional[int] = 0


class PhaseUpdate(BaseModel):
    title: Optional[str] = None
    order_index: Optional[int] = None


class PhaseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    roadmap_id: int
    title: str
    order_index: int
    created_at: datetime
