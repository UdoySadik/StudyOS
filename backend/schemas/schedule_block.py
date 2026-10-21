"""Pydantic schemas for ScheduleBlock endpoints."""

from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class ScheduleBlockCreate(BaseModel):
    scheduled_date: date
    start_time: str
    end_time: str
    title: str
    topic_id: Optional[int] = None
    notes: Optional[str] = None


class ScheduleBlockUpdate(BaseModel):
    scheduled_date: Optional[date] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    title: Optional[str] = None
    topic_id: Optional[int] = None
    is_completed: Optional[bool] = None
    notes: Optional[str] = None


class ScheduleBlockResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    scheduled_date: date
    start_time: str
    end_time: str
    title: str
    topic_id: Optional[int] = None
    is_completed: bool
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
