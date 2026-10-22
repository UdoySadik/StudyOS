"""Pydantic schemas for Calendar month events."""

from datetime import date
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class CalendarGoalItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    roadmap_id: int
    roadmap_title: str
    target_date: date


class CalendarScheduleItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    scheduled_date: date
    start_time: str
    end_time: str
    is_completed: bool


class CalendarStudyItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    topic_id: int
    topic_title: str
    logged_date: date
    duration_seconds: int


class CalendarMonthEventsResponse(BaseModel):
    year: int
    month: int
    goals: List[CalendarGoalItem]
    schedule_blocks: List[CalendarScheduleItem]
    study_sessions: List[CalendarStudyItem]
