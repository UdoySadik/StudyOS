"""Pydantic schemas for Flashcards, Quizzes, and Automated Generation from Notes."""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class FlashcardCreate(BaseModel):
    front: str
    back: str


class FlashcardResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    deck_id: int
    front: str
    back: str
    is_mastered: bool
    review_count: int
    created_at: datetime


class DeckCreate(BaseModel):
    topic_id: Optional[int] = None
    title: str
    description: Optional[str] = None
    cards: List[FlashcardCreate] = []


class DeckResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    topic_id: Optional[int] = None
    topic_title: Optional[str] = None
    title: str
    description: Optional[str] = None
    total_cards: int = 0
    mastered_cards: int = 0
    created_at: datetime
    cards: List[FlashcardResponse] = []


class QuizQuestionCreate(BaseModel):
    question: str
    options: List[str]
    correct_index: int = 0
    explanation: Optional[str] = None


class QuizQuestionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    quiz_id: int
    question: str
    options: List[str]
    correct_index: int
    explanation: Optional[str] = None


class QuizCreate(BaseModel):
    topic_id: Optional[int] = None
    title: str
    description: Optional[str] = None
    questions: List[QuizQuestionCreate] = []


class QuizResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    topic_id: Optional[int] = None
    topic_title: Optional[str] = None
    title: str
    description: Optional[str] = None
    questions_count: int = 0
    created_at: datetime
    questions: List[QuizQuestionResponse] = []


class GenerateRecallRequest(BaseModel):
    topic_id: Optional[int] = None
    note_content: Optional[str] = None
    count: int = 5
    generate_flashcards: bool = True
    generate_quiz: bool = True
    model: Optional[str] = None


class GenerateRecallResponse(BaseModel):
    deck: Optional[DeckResponse] = None
    quiz: Optional[QuizResponse] = None
    model_used: str
    generated_cards_count: int
    generated_questions_count: int
