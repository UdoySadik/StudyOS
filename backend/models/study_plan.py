"""StudyPlan SQLAlchemy model for Offline LLM Study Planner (Ollama Integration)."""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


class AIStudyPlan(Base):
    __tablename__ = "ai_study_plans"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    subject = Column(String, nullable=False)
    proficiency = Column(String, nullable=False, default="intermediate")  # beginner, intermediate, advanced
    hours_per_week = Column(Integer, nullable=False, default=10)
    target_weeks = Column(Integer, nullable=False, default=4)
    model_used = Column(String, nullable=False, default="builtin-offline")
    plan_markdown = Column(Text, nullable=False)
    structured_json = Column(Text, nullable=True)  # JSON string of phases, topics, projects
    roadmap_id = Column(Integer, ForeignKey("roadmaps.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    roadmap = relationship("Roadmap", backref="ai_study_plans", lazy="joined")
