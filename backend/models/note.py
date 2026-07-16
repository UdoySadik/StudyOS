"""Note ORM model — one-to-one with Topic."""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


def _now():
    return datetime.now(timezone.utc)


class Note(Base):
    __tablename__ = "notes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    topic_id = Column(Integer, ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, unique=True)
    content = Column(Text, default="")
    updated_at = Column(DateTime, default=_now, onupdate=_now)

    topic = relationship("Topic", back_populates="note")
