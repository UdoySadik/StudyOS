"""Pydantic schemas for StudySession endpoints."""

from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict


class StudySessionCreate(BaseModel):
    topic_id: int
    duration_seconds: int
    logged_date: Optional[date] = None
    notes: Optional[str] = None


class StudySessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    topic_id: int
    duration_seconds: int
    logged_date: date
    notes: Optional[str] = None
    created_at: datetime


class TopicStudyStats(BaseModel):
    topic_id: int
    topic_title: Optional[str] = None
    total_seconds: int
    session_count: int


class StudySummaryResponse(BaseModel):
    total_seconds_today: int
    total_seconds_all_time: int
    total_sessions_count: int
    topic_stats: List[TopicStudyStats]
