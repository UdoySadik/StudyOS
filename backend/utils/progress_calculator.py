"""
Progress Calculator — pure functions, no DB dependency.
All progress is computed dynamically from topic completion data.
"""

from typing import List
from models.topic import Topic
from models.phase import Phase


def compute_roadmap_progress(phases: List[Phase]) -> dict:
    """Compute overall roadmap progress across all phases."""
    total = sum(len(phase.topics) for phase in phases)
    completed = sum(
        sum(1 for t in phase.topics if t.is_completed)
        for phase in phases
    )
    return {
        "total_topics": total,
        "completed_topics": completed,
        "remaining_topics": total - completed,
        "progress_percent": round((completed / total * 100) if total > 0 else 0, 1),
    }


def compute_phase_progress(phase: Phase) -> dict:
    """Compute progress for a single phase."""
    total = len(phase.topics)
    completed = sum(1 for t in phase.topics if t.is_completed)
    return {
        "phase_id": phase.id,
        "phase_title": phase.title,
        "total_topics": total,
        "completed_topics": completed,
        "remaining_topics": total - completed,
        "progress_percent": round((completed / total * 100) if total > 0 else 0, 1),
    }


def compute_goal_stats(remaining_topics: int, target_date, today) -> dict:
    """Compute goal-based statistics."""
    days_remaining = (target_date - today).days
    if days_remaining <= 0:
        topics_per_day = remaining_topics  # overdue
    else:
        topics_per_day = round(remaining_topics / days_remaining, 2)

    return {
        "days_remaining": max(days_remaining, 0),
        "topics_per_day_needed": topics_per_day,
        "is_overdue": days_remaining < 0,
    }


def get_today_suggestions(phases: List[Phase], topics_per_day: float) -> List[dict]:
    """Return the next N incomplete topics based on goal pace."""
    n = max(1, round(topics_per_day)) if topics_per_day > 0 else 3
    suggestions = []
    for phase in phases:
        for topic in sorted(phase.topics, key=lambda t: t.order_index):
            if not topic.is_completed:
                suggestions.append({
                    "topic_id": topic.id,
                    "topic_title": topic.title,
                    "phase_title": phase.title,
                })
            if len(suggestions) >= n:
                return suggestions
    return suggestions
