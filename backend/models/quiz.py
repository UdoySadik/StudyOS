"""Quiz and QuizQuestion SQLAlchemy models for Active Recall self-testing."""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


def _now():
    return datetime.now(timezone.utc)


class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    topic_id = Column(Integer, ForeignKey("topics.id", ondelete="CASCADE"), nullable=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=_now)

    topic = relationship("Topic", backref="quizzes", lazy="joined")
    questions = relationship(
        "QuizQuestion",
        back_populates="quiz",
        cascade="all, delete-orphan",
        order_by="QuizQuestion.id",
    )


class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False)
    question = Column(Text, nullable=False)
    options_json = Column(Text, nullable=False)  # JSON-encoded array of 4 option strings
    correct_index = Column(Integer, default=0, nullable=False)
    explanation = Column(Text, nullable=True)

    quiz = relationship("Quiz", back_populates="questions")
