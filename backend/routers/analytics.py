import calendar
import math
from collections import defaultdict
from datetime import date, timedelta
from typing import Dict, List, Optional, Set
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func

from database import get_db
from models.roadmap import Roadmap
from models.phase import Phase
from models.goal import Goal
from models.study_session import StudySession
from models.schedule_block import ScheduleBlock
from models.topic import Topic
from utils.progress_calculator import compute_roadmap_progress
from schemas.analytics import (
    StreakSummaryResponse,
    DayConsistencyItem,
    PhaseBurndownItem,
    DailyVelocityItem,
    RoadmapBurndownResponse,
    DayStudyHourItem,
    TopicStudyHourItem,
    WeekdayStudyHourItem,
    MonthlyStudyHoursResponse,
)

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


@router.get("/burndown/{roadmap_id}", response_model=RoadmapBurndownResponse)
def get_roadmap_burndown(roadmap_id: int, db: Session = Depends(get_db)):
    """Compute Phase Burndown and Learning Velocity metrics for a roadmap."""
    roadmap = (
        db.query(Roadmap)
        .options(joinedload(Roadmap.phases).joinedload(Phase.topics))
        .filter(Roadmap.id == roadmap_id)
        .first()
    )
    if not roadmap:
        raise HTTPException(status_code=404, detail="Roadmap not found")

    today = date.today()
    progress = compute_roadmap_progress(roadmap.phases)
    total_topics = progress["total_topics"]
    completed_topics = progress["completed_topics"]
    remaining_topics = progress["remaining_topics"]
    progress_percent = progress["progress_percent"]

    # Goal & required velocity
    goal = (
        db.query(Goal)
        .filter(Goal.roadmap_id == roadmap_id)
        .order_by(Goal.updated_at.desc())
        .first()
    )
    target_date_str = None
    days_remaining = None
    required_velocity = 0.0

    if goal:
        target_date_str = goal.target_date.isoformat()
        days_remaining = (goal.target_date - today).days
        if days_remaining <= 0:
            required_velocity = float(remaining_topics)
        else:
            required_velocity = round(remaining_topics / days_remaining, 2)

    # Topic IDs in this roadmap
    all_topic_ids = [t.id for p in roadmap.phases for t in p.topics]
    seven_days_ago = today - timedelta(days=6)

    # Topics completed in last 7 days
    recent_completed_count = 0
    recent_study_seconds = 0
    if all_topic_ids:
        recent_completed_count = (
            db.query(func.count(Topic.id))
            .filter(Topic.id.in_(all_topic_ids))
            .filter(Topic.is_completed == True)
            .filter(func.date(Topic.completed_at) >= seven_days_ago)
            .scalar()
            or 0
        )
        recent_study_seconds = (
            db.query(func.sum(StudySession.duration_seconds))
            .filter(StudySession.topic_id.in_(all_topic_ids))
            .filter(StudySession.logged_date >= seven_days_ago)
            .scalar()
            or 0
        )

    current_velocity_7d = round(recent_completed_count / 7.0, 2)
    current_study_hours_7d = round((recent_study_seconds / 3600.0) / 7.0, 2)

    # Status & Trajectory
    projected_completion_date = None
    if remaining_topics == 0 and total_topics > 0:
        status = "completed"
        status_label = "Roadmap Completed 🎉"
    elif not goal:
        status = "no_goal"
        status_label = "No Deadline Set"
        if current_velocity_7d > 0:
            days_needed = math.ceil(remaining_topics / current_velocity_7d)
            projected_completion_date = (today + timedelta(days=days_needed)).isoformat()
    else:
        if days_remaining is not None and days_remaining < 0:
            status = "behind"
            status_label = "Overdue ⚠️"
        elif current_velocity_7d >= required_velocity * 1.25 and required_velocity > 0:
            status = "ahead"
            status_label = "Ahead of Pace 🚀"
        elif current_velocity_7d >= required_velocity and required_velocity > 0:
            status = "on_track"
            status_label = "On Track 🟢"
        elif current_velocity_7d > 0:
            status = "behind"
            status_label = "Needs Attention 🟡"
        else:
            status = "behind"
            status_label = "Behind Schedule 🔴"

        if current_velocity_7d > 0:
            days_needed = math.ceil(remaining_topics / current_velocity_7d)
            projected_completion_date = (today + timedelta(days=days_needed)).isoformat()

    # Phase-by-phase burndown
    phases_burndown: List[PhaseBurndownItem] = []
    for phase in sorted(roadmap.phases, key=lambda p: p.order_index):
        total_p = len(phase.topics)
        comp_p = sum(1 for t in phase.topics if t.is_completed)
        rem_p = total_p - comp_p
        pct_p = round((comp_p / total_p * 100) if total_p > 0 else 0, 1)

        est_days = None
        if current_velocity_7d > 0 and rem_p > 0:
            est_days = round(rem_p / current_velocity_7d, 1)
        elif rem_p == 0:
            est_days = 0.0

        phases_burndown.append(
            PhaseBurndownItem(
                phase_id=phase.id,
                phase_title=phase.title,
                order_index=phase.order_index,
                total_topics=total_p,
                completed_topics=comp_p,
                remaining_topics=rem_p,
                progress_percent=pct_p,
                estimated_days_to_complete=est_days,
            )
        )

    # 7-day velocity breakdown
    day_labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    recent_velocity: List[DailyVelocityItem] = []
    for i in range(7):
        d = seven_days_ago + timedelta(days=i)
        day_completed = 0
        day_study_sec = 0
        if all_topic_ids:
            day_completed = (
                db.query(func.count(Topic.id))
                .filter(Topic.id.in_(all_topic_ids))
                .filter(Topic.is_completed == True)
                .filter(func.date(Topic.completed_at) == d)
                .scalar()
                or 0
            )
            day_study_sec = (
                db.query(func.sum(StudySession.duration_seconds))
                .filter(StudySession.topic_id.in_(all_topic_ids))
                .filter(StudySession.logged_date == d)
                .scalar()
                or 0
            )

        recent_velocity.append(
            DailyVelocityItem(
                date=d.isoformat(),
                day_label=day_labels[d.weekday()],
                topics_completed=day_completed,
                study_seconds=day_study_sec,
            )
        )

    return RoadmapBurndownResponse(
        roadmap_id=roadmap.id,
        roadmap_title=roadmap.title,
        total_topics=total_topics,
        completed_topics=completed_topics,
        remaining_topics=remaining_topics,
        progress_percent=progress_percent,
        target_date=target_date_str,
        days_remaining=days_remaining,
        required_velocity=required_velocity,
        current_velocity_7d=current_velocity_7d,
        current_study_hours_7d=current_study_hours_7d,
        status=status,
        status_label=status_label,
        projected_completion_date=projected_completion_date,
        phases=phases_burndown,
        recent_velocity=recent_velocity,
    )


@router.get("/study-hours", response_model=MonthlyStudyHoursResponse)
def get_monthly_study_hours(
    year: Optional[int] = Query(None, description="Year (e.g. 2026)"),
    month: Optional[int] = Query(None, description="Month (1-12)"),
    roadmap_id: Optional[int] = Query(None, description="Optional filter by roadmap ID"),
    db: Session = Depends(get_db),
):
    """Retrieve monthly study hours distribution, daily histogram, weekday patterns, and topic breakdowns."""
    today = date.today()
    target_year = year if year is not None else today.year
    target_month = month if month is not None else today.month

    if target_month < 1 or target_month > 12:
        raise HTTPException(status_code=400, detail="Month must be between 1 and 12")

    if roadmap_id is not None:
        roadmap = db.query(Roadmap).filter(Roadmap.id == roadmap_id).first()
        if not roadmap:
            raise HTTPException(status_code=404, detail="Roadmap not found")

    _, num_days = calendar.monthrange(target_year, target_month)
    start_date = date(target_year, target_month, 1)
    end_date = date(target_year, target_month, num_days)

    query = (
        db.query(StudySession)
        .options(joinedload(StudySession.topic).joinedload(Topic.phase))
        .filter(StudySession.logged_date >= start_date)
        .filter(StudySession.logged_date <= end_date)
    )

    if roadmap_id is not None:
        query = query.join(Topic).join(Phase).filter(Phase.roadmap_id == roadmap_id)

    sessions = query.all()

    total_seconds = sum(s.duration_seconds for s in sessions)
    total_hours = round(total_seconds / 3600.0, 2)
    total_sessions = len(sessions)

    # Daily aggregation
    daily_map = defaultdict(lambda: {"seconds": 0, "count": 0})
    for s in sessions:
        if s.logged_date:
            daily_map[s.logged_date]["seconds"] += s.duration_seconds
            daily_map[s.logged_date]["count"] += 1

    daily_distribution: List[DayStudyHourItem] = []
    day_abbrs = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    for day in range(1, num_days + 1):
        d = date(target_year, target_month, day)
        sec = daily_map[d]["seconds"]
        cnt = daily_map[d]["count"]
        daily_distribution.append(
            DayStudyHourItem(
                date=d.isoformat(),
                day_of_month=day,
                day_label=day_abbrs[d.weekday()],
                study_seconds=sec,
                study_hours=round(sec / 3600.0, 2),
                session_count=cnt,
            )
        )

    active_days_count = sum(1 for d in daily_distribution if d.study_seconds > 0)
    daily_avg = round(total_hours / active_days_count, 2) if active_days_count > 0 else 0.0

    peak_day = max(daily_distribution, key=lambda x: x.study_seconds, default=None)
    peak_day_date = peak_day.date if (peak_day and peak_day.study_seconds > 0) else None
    peak_day_hours = peak_day.study_hours if (peak_day and peak_day.study_seconds > 0) else 0.0

    # Topic aggregation
    topic_map = defaultdict(lambda: {"title": "", "phase": "", "seconds": 0})
    for s in sessions:
        t = s.topic
        if t:
            topic_map[t.id]["title"] = t.title
            topic_map[t.id]["phase"] = t.phase.title if t.phase else "General"
            topic_map[t.id]["seconds"] += s.duration_seconds

    topic_distribution: List[TopicStudyHourItem] = []
    for t_id, t_info in sorted(topic_map.items(), key=lambda item: item[1]["seconds"], reverse=True):
        sec = t_info["seconds"]
        pct = round((sec / total_seconds * 100.0), 1) if total_seconds > 0 else 0.0
        topic_distribution.append(
            TopicStudyHourItem(
                topic_id=t_id,
                topic_title=t_info["title"],
                phase_title=t_info["phase"],
                study_seconds=sec,
                study_hours=round(sec / 3600.0, 2),
                percentage=pct,
            )
        )

    # Weekday aggregation
    weekday_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    weekday_map = {i: {"seconds": 0, "count": 0} for i in range(7)}
    for s in sessions:
        if s.logged_date:
            w = s.logged_date.weekday()
            weekday_map[w]["seconds"] += s.duration_seconds
            weekday_map[w]["count"] += 1

    weekday_distribution: List[WeekdayStudyHourItem] = []
    for i in range(7):
        sec = weekday_map[i]["seconds"]
        weekday_distribution.append(
            WeekdayStudyHourItem(
                weekday_index=i,
                day_name=weekday_names[i],
                total_seconds=sec,
                total_hours=round(sec / 3600.0, 2),
                session_count=weekday_map[i]["count"],
            )
        )

    month_name = f"{calendar.month_name[target_month]} {target_year}"

    return MonthlyStudyHoursResponse(
        year=target_year,
        month=target_month,
        month_name=month_name,
        roadmap_id=roadmap_id,
        total_seconds=total_seconds,
        total_hours=total_hours,
        total_sessions=total_sessions,
        active_days_count=active_days_count,
        total_days_in_month=num_days,
        daily_average_hours=daily_avg,
        peak_day_date=peak_day_date,
        peak_day_hours=peak_day_hours,
        daily_distribution=daily_distribution,
        topic_distribution=topic_distribution,
        weekday_distribution=weekday_distribution,
    )


