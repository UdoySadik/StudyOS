"""Calendar Router — aggregates goals, schedule blocks, and study sessions for calendar views."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from database import get_db
from models.goal import Goal
from models.roadmap import Roadmap
from models.schedule_block import ScheduleBlock
from models.study_session import StudySession
from models.topic import Topic
from schemas.calendar import (
    CalendarGoalItem,
    CalendarScheduleItem,
    CalendarStudyItem,
    CalendarMonthEventsResponse,
)
from datetime import date
import calendar

router = APIRouter(prefix="/calendar", tags=["calendar"])


@router.get("/events", response_model=CalendarMonthEventsResponse)
def get_month_events(
    year: int = Query(..., ge=2000, le=2100),
    month: int = Query(..., ge=1, le=12),
    db: Session = Depends(get_db),
):
    _, last_day = calendar.monthrange(year, month)
    start_date = date(year, month, 1)
    end_date = date(year, month, last_day)

    # 1. Goals in month
    goals_query = (
        db.query(Goal, Roadmap.title)
        .join(Roadmap, Goal.roadmap_id == Roadmap.id)
        .filter(Goal.target_date >= start_date, Goal.target_date <= end_date)
        .all()
    )
    goal_items = [
        CalendarGoalItem(
            id=g.id,
            roadmap_id=g.roadmap_id,
            roadmap_title=rm_title,
            target_date=g.target_date,
        )
        for g, rm_title in goals_query
    ]

    # 2. Schedule blocks in month
    blocks_query = (
        db.query(ScheduleBlock)
        .filter(ScheduleBlock.scheduled_date >= start_date, ScheduleBlock.scheduled_date <= end_date)
        .order_by(ScheduleBlock.start_time.asc())
        .all()
    )
    schedule_items = [
        CalendarScheduleItem(
            id=b.id,
            title=b.title,
            scheduled_date=b.scheduled_date,
            start_time=b.start_time,
            end_time=b.end_time,
            is_completed=b.is_completed,
        )
        for b in blocks_query
    ]

    # 3. Study sessions in month
    sessions_query = (
        db.query(StudySession, Topic.title)
        .join(Topic, StudySession.topic_id == Topic.id)
        .filter(StudySession.logged_date >= start_date, StudySession.logged_date <= end_date)
        .order_by(StudySession.created_at.desc())
        .all()
    )
    study_items = [
        CalendarStudyItem(
            id=s.id,
            topic_id=s.topic_id,
            topic_title=tp_title,
            logged_date=s.logged_date,
            duration_seconds=s.duration_seconds,
        )
        for s, tp_title in sessions_query
    ]

    return CalendarMonthEventsResponse(
        year=year,
        month=month,
        goals=goal_items,
        schedule_blocks=schedule_items,
        study_sessions=study_items,
    )
