"""Pydantic schemas for Goal endpoints."""

from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class GoalCreate(BaseModel):
    roadmap_id: int
    target_date: date


class GoalUpdate(BaseModel):
    target_date: date


class GoalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    roadmap_id: int
    target_date: date
    created_at: datetime
    updated_at: datetime
