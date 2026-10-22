"""Pydantic schemas for Study Analytics & Consistency Streaks."""

from datetime import date
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class DayConsistencyItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    date: str
    day_label: str
    is_active: bool
    study_seconds: int
    completed_blocks: int
    is_today: bool


class StreakSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    current_streak: int
    longest_streak: int
    total_active_days: int
    is_active_today: bool
    weekly_consistency: List[DayConsistencyItem]
    active_dates_last_30_days: List[str]


class PhaseBurndownItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    phase_id: int
    phase_title: str
    order_index: int
    total_topics: int
    completed_topics: int
    remaining_topics: int
    progress_percent: float
    estimated_days_to_complete: Optional[float] = None


class DailyVelocityItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    date: str
    day_label: str
    topics_completed: int
    study_seconds: int


class RoadmapBurndownResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    roadmap_id: int
    roadmap_title: str
    total_topics: int
    completed_topics: int
    remaining_topics: int
    progress_percent: float
    target_date: Optional[str] = None
    days_remaining: Optional[int] = None
    required_velocity: float
    current_velocity_7d: float
    current_study_hours_7d: float
    status: str  # "on_track", "ahead", "behind", "completed", "no_goal"
    status_label: str
    projected_completion_date: Optional[str] = None
    phases: List[PhaseBurndownItem]
    recent_velocity: List[DailyVelocityItem]
