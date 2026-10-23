"""Topic ORM model."""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


def _now():
    return datetime.now(timezone.utc)


class Topic(Base):
    __tablename__ = "topics"

    id = Column(Integer, primary_key=True, autoincrement=True)
    phase_id = Column(Integer, ForeignKey("phases.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    is_completed = Column(Boolean, default=False, nullable=False)
    order_index = Column(Integer, nullable=False, default=0)
    completed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=_now)

    phase = relationship("Phase", back_populates="topics")
    subtopics = relationship(
        "Subtopic",
        back_populates="topic",
        cascade="all, delete-orphan",
        order_by="Subtopic.order_index",
    )
    note = relationship(
        "Note",
        back_populates="topic",
        cascade="all, delete-orphan",
        uselist=False,  # one-to-one
    )
    study_sessions = relationship(
        "StudySession",
        back_populates="topic",
        cascade="all, delete-orphan",
    )
    resources = relationship(
        "Resource",
        back_populates="topic",
        cascade="all, delete-orphan",
        order_by="Resource.created_at",
    )

