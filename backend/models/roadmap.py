"""Roadmap ORM model."""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Text
from sqlalchemy.orm import relationship
from database import Base


def _now():
    return datetime.now(timezone.utc)


class Roadmap(Base):
    __tablename__ = "roadmaps"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=_now)
    updated_at = Column(DateTime, default=_now, onupdate=_now)

    phases = relationship(
        "Phase",
        back_populates="roadmap",
        cascade="all, delete-orphan",
        order_by="Phase.order_index",
    )
    goals = relationship(
        "Goal",
        back_populates="roadmap",
        cascade="all, delete-orphan",
    )
