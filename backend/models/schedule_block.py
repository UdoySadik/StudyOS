"""ScheduleBlock ORM model for Daily Study Schedule & Time-Blocking."""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, Date, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


def _now():
    return datetime.now(timezone.utc)


class ScheduleBlock(Base):
    __tablename__ = "schedule_blocks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    scheduled_date = Column(Date, nullable=False, index=True)
    start_time = Column(String(10), nullable=False)  # "HH:MM"
    end_time = Column(String(10), nullable=False)    # "HH:MM"
    title = Column(String(255), nullable=False)
    topic_id = Column(Integer, ForeignKey("topics.id", ondelete="SET NULL"), nullable=True)
    is_completed = Column(Boolean, default=False, nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=_now)
    updated_at = Column(DateTime, default=_now, onupdate=_now)

    topic = relationship("Topic")
