"""FlashcardDeck and Flashcard SQLAlchemy models for Active Recall study tools."""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


def _now():
    return datetime.now(timezone.utc)


class FlashcardDeck(Base):
    __tablename__ = "flashcard_decks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    topic_id = Column(Integer, ForeignKey("topics.id", ondelete="CASCADE"), nullable=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=_now)

    topic = relationship("Topic", backref="flashcard_decks", lazy="joined")
    cards = relationship(
        "Flashcard",
        back_populates="deck",
        cascade="all, delete-orphan",
        order_by="Flashcard.id",
    )


class Flashcard(Base):
    __tablename__ = "flashcards"

    id = Column(Integer, primary_key=True, autoincrement=True)
    deck_id = Column(Integer, ForeignKey("flashcard_decks.id", ondelete="CASCADE"), nullable=False)
    front = Column(Text, nullable=False)
    back = Column(Text, nullable=False)
    is_mastered = Column(Boolean, default=False, nullable=False)
    review_count = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, default=_now)

    deck = relationship("FlashcardDeck", back_populates="cards")
