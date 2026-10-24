"""Project ORM model for Practice Project Tracker with GitHub links."""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


def _now():
    return datetime.now(timezone.utc)


class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, autoincrement=True)
    roadmap_id = Column(Integer, ForeignKey("roadmaps.id", ondelete="CASCADE"), nullable=False, index=True)
    topic_id = Column(Integer, ForeignKey("topics.id", ondelete="SET NULL"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    github_url = Column(String(1024), nullable=True)
    live_url = Column(String(1024), nullable=True)
    status = Column(String(50), nullable=False, default="not_started")  # not_started, in_progress, completed, on_hold
    difficulty = Column(String(50), nullable=False, default="medium")   # beginner, medium, advanced
    tech_stack = Column(String(500), nullable=True)                    # comma-separated e.g. "Rust, Tokio"
    created_at = Column(DateTime, default=_now)
    completed_at = Column(DateTime, nullable=True)

    roadmap = relationship("Roadmap", back_populates="projects")
    topic = relationship("Topic", back_populates="projects")
