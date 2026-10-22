"""Study sessions & topic stopwatch logging router."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
from models.study_session import StudySession
from models.topic import Topic
from schemas.study_session import (
    StudySessionCreate,
    StudySessionResponse,
    TopicStudyStats,
    StudySummaryResponse,
)
from typing import List, Optional
from datetime import date

router = APIRouter(prefix="/study-sessions", tags=["study-sessions"])


@router.post("/", response_model=StudySessionResponse, status_code=status.HTTP_201_CREATED)
def create_study_session(payload: StudySessionCreate, db: Session = Depends(get_db)):
    topic = db.get(Topic, payload.topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")

    session_data = payload.model_dump()
    if not session_data.get("logged_date"):
        session_data["logged_date"] = date.today()

    session = StudySession(**session_data)
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get("/", response_model=List[StudySessionResponse])
def list_study_sessions(
    topic_id: Optional[int] = None,
    target_date: Optional[date] = None,
    db: Session = Depends(get_db),
):
    query = db.query(StudySession)
    if topic_id is not None:
        query = query.filter(StudySession.topic_id == topic_id)
    if target_date is not None:
        query = query.filter(StudySession.logged_date == target_date)
    return query.order_by(StudySession.created_at.desc()).all()


@router.get("/topic/{topic_id}", response_model=TopicStudyStats)
def get_topic_study_stats(topic_id: int, db: Session = Depends(get_db)):
    topic = db.get(Topic, topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")

    res = (
        db.query(
            func.coalesce(func.sum(StudySession.duration_seconds), 0),
            func.count(StudySession.id),
        )
        .filter(StudySession.topic_id == topic_id)
        .first()
    )

    total_seconds = int(res[0]) if res else 0
    count = int(res[1]) if res else 0

    return TopicStudyStats(
        topic_id=topic.id,
        topic_title=topic.title,
        total_seconds=total_seconds,
        session_count=count,
    )


@router.get("/summary", response_model=StudySummaryResponse)
def get_study_summary(db: Session = Depends(get_db)):
    today = date.today()

    # Total today
    today_res = (
        db.query(func.coalesce(func.sum(StudySession.duration_seconds), 0))
        .filter(StudySession.logged_date == today)
        .scalar()
    )
    total_seconds_today = int(today_res) if today_res else 0

    # Total all time
    all_time_res = (
        db.query(
            func.coalesce(func.sum(StudySession.duration_seconds), 0),
            func.count(StudySession.id),
        )
        .first()
    )
    total_seconds_all = int(all_time_res[0]) if all_time_res else 0
    total_count = int(all_time_res[1]) if all_time_res else 0

    # Per-topic breakdown
    topic_breakdown = (
        db.query(
            StudySession.topic_id,
            Topic.title,
            func.coalesce(func.sum(StudySession.duration_seconds), 0),
            func.count(StudySession.id),
        )
        .join(Topic, StudySession.topic_id == Topic.id)
        .group_by(StudySession.topic_id, Topic.title)
        .order_by(func.sum(StudySession.duration_seconds).desc())
        .all()
    )

    stats = [
        TopicStudyStats(
            topic_id=row[0],
            topic_title=row[1],
            total_seconds=int(row[2]),
            session_count=int(row[3]),
        )
        for row in topic_breakdown
    ]

    return StudySummaryResponse(
        total_seconds_today=total_seconds_today,
        total_seconds_all_time=total_seconds_all,
        total_sessions_count=total_count,
        topic_stats=stats,
    )


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_study_session(session_id: int, db: Session = Depends(get_db)):
    session = db.get(StudySession, session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Study session not found")
    db.delete(session)
    db.commit()
