"""StudySession ORM model for stopwatch & study-hour tracking."""

from datetime import datetime, timezone, date
from sqlalchemy import Column, Integer, Date, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


def _now():
    return datetime.now(timezone.utc)


class StudySession(Base):
    __tablename__ = "study_sessions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    topic_id = Column(Integer, ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, index=True)
    duration_seconds = Column(Integer, nullable=False)
    logged_date = Column(Date, default=date.today, nullable=False, index=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=_now)

    topic = relationship("Topic", back_populates="study_sessions")
