"""Pydantic schemas for Study Analytics & Consistency Streaks."""

from datetime import date
from typing import List
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
