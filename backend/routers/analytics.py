"""Analytics router for Study Streaks and Consistency Metrics."""

from datetime import date, timedelta
from typing import Dict, List, Set
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from database import get_db
from models.study_session import StudySession
from models.schedule_block import ScheduleBlock
from models.topic import Topic
from schemas.analytics import StreakSummaryResponse, DayConsistencyItem

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/streak", response_model=StreakSummaryResponse)
def get_streak_summary(db: Session = Depends(get_db)):
    today = date.today()

    # 1. Dates with logged study sessions (> 0 seconds)
    session_rows = (
        db.query(
            StudySession.logged_date,
            func.sum(StudySession.duration_seconds).label("total_seconds"),
        )
        .group_by(StudySession.logged_date)
        .all()
    )
    study_seconds_by_date: Dict[date, int] = {
        row[0]: int(row[1] or 0) for row in session_rows if row[0] is not None
    }

    # 2. Dates with completed schedule blocks
    block_rows = (
        db.query(
            ScheduleBlock.scheduled_date,
            func.count(ScheduleBlock.id).label("completed_count"),
        )
        .filter(ScheduleBlock.is_completed == True)
        .group_by(ScheduleBlock.scheduled_date)
        .all()
    )
    completed_blocks_by_date: Dict[date, int] = {
        row[0]: int(row[1] or 0) for row in block_rows if row[0] is not None
    }

    # 3. Completed topics by date (using completed_at date if completed)
    topic_rows = (
        db.query(func.date(Topic.completed_at))
        .filter(Topic.is_completed == True)
        .filter(Topic.completed_at.isnot(None))
        .distinct()
        .all()
    )
    topic_dates: Set[date] = set()
    for row in topic_rows:
        if row[0]:
            try:
                if isinstance(row[0], str):
                    topic_dates.add(date.fromisoformat(row[0]))
                elif isinstance(row[0], date):
                    topic_dates.add(row[0])
            except Exception:
                pass

    # All unique active dates where study happened
    active_dates: Set[date] = (
        set(study_seconds_by_date.keys())
        | set(completed_blocks_by_date.keys())
        | topic_dates
    )

    is_active_today = today in active_dates

    # 4. Compute Current Streak
    current_streak = 0
    if is_active_today:
        current_streak = 1
        check_date = today - timedelta(days=1)
        while check_date in active_dates:
            current_streak += 1
            check_date -= timedelta(days=1)
    else:
        # If today not active yet, check if yesterday was active
        yesterday = today - timedelta(days=1)
        if yesterday in active_dates:
            current_streak = 1
            check_date = yesterday - timedelta(days=1)
            while check_date in active_dates:
                current_streak += 1
                check_date -= timedelta(days=1)
        else:
            current_streak = 0

    # 5. Compute Longest Streak All-Time
    sorted_dates = sorted(active_dates)
    longest_streak = 0
    if sorted_dates:
        cur_run = 1
        longest_streak = 1
        for i in range(1, len(sorted_dates)):
            if sorted_dates[i] == sorted_dates[i - 1] + timedelta(days=1):
                cur_run += 1
            elif sorted_dates[i] > sorted_dates[i - 1] + timedelta(days=1):
                cur_run = 1
            if cur_run > longest_streak:
                longest_streak = cur_run

    longest_streak = max(longest_streak, current_streak)

    # 6. Weekly Consistency (Monday to Sunday of current week)
    start_of_week = today - timedelta(days=today.weekday())
    day_labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    weekly_consistency: List[DayConsistencyItem] = []

    for i in range(7):
        d = start_of_week + timedelta(days=i)
        is_act = d in active_dates
        weekly_consistency.append(
            DayConsistencyItem(
                date=d.isoformat(),
                day_label=day_labels[i],
                is_active=is_act,
                study_seconds=study_seconds_by_date.get(d, 0),
                completed_blocks=completed_blocks_by_date.get(d, 0),
                is_today=(d == today),
            )
        )

    # 7. Active dates in last 30 days
    thirty_days_ago = today - timedelta(days=30)
    active_last_30 = [
        d.isoformat()
        for d in sorted_dates
        if d >= thirty_days_ago and d <= today
    ]

    return StreakSummaryResponse(
        current_streak=current_streak,
        longest_streak=longest_streak,
        total_active_days=len(active_dates),
        is_active_today=is_active_today,
        weekly_consistency=weekly_consistency,
        active_dates_last_30_days=active_last_30,
    )
