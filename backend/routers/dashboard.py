"""
Dashboard Summary Router
Returns all computed stats for a roadmap in a single request.
No stored progress — everything is computed dynamically.
"""

from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from database import get_db
from models.roadmap import Roadmap
from models.phase import Phase
from models.goal import Goal
from utils.progress_calculator import (
    compute_roadmap_progress,
    compute_phase_progress,
    compute_goal_stats,
    get_today_suggestions,
)

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/{roadmap_id}")
def get_dashboard(roadmap_id: int, db: Session = Depends(get_db)):
    """Return complete dashboard data for a roadmap."""
    roadmap = (
        db.query(Roadmap)
        .options(
            joinedload(Roadmap.phases).joinedload(Phase.topics)
        )
        .filter(Roadmap.id == roadmap_id)
        .first()
    )
    if not roadmap:
        raise HTTPException(status_code=404, detail="Roadmap not found")

    # Overall progress
    progress = compute_roadmap_progress(roadmap.phases)

    # Phase-by-phase progress
    phase_progress = [compute_phase_progress(p) for p in roadmap.phases]

    # Current phase/topic (first incomplete)
    current_phase = None
    current_topic = None
    for phase in roadmap.phases:
        for topic in sorted(phase.topics, key=lambda t: t.order_index):
            if not topic.is_completed:
                current_phase = phase.title
                current_topic = topic.title
                break
        if current_topic:
            break

    # Goal stats
    goal = db.query(Goal).filter(Goal.roadmap_id == roadmap_id).order_by(Goal.updated_at.desc()).first()
    goal_data = None
    today_suggestions = []

    if goal:
        goal_stats = compute_goal_stats(
            remaining_topics=progress["remaining_topics"],
            target_date=goal.target_date,
            today=date.today(),
        )
        goal_data = {
            "target_date": goal.target_date.isoformat(),
            **goal_stats,
        }
        today_suggestions = get_today_suggestions(
            phases=roadmap.phases,
            topics_per_day=goal_stats["topics_per_day_needed"],
        )
    else:
        today_suggestions = get_today_suggestions(phases=roadmap.phases, topics_per_day=3)

    return {
        "roadmap_id": roadmap_id,
        "roadmap_title": roadmap.title,
        "current_phase": current_phase,
        "current_topic": current_topic,
        "progress": progress,
        "phase_progress": phase_progress,
        "goal": goal_data,
        "today_suggestions": today_suggestions,
    }
