"""FastAPI router for Flashcards, Quizzes, and Automated Active Recall generation from notes."""

import json
import re
from datetime import datetime, timezone
from typing import List, Optional, Tuple, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from database import get_db
from models.topic import Topic
from models.note import Note
from models.flashcard import FlashcardDeck, Flashcard
from models.quiz import Quiz, QuizQuestion
from routers.ai_planner import check_ollama_connection, call_ollama_generate
from schemas.study_recall import (
    FlashcardCreate,
    FlashcardResponse,
    DeckCreate,
    DeckResponse,
    QuizQuestionCreate,
    QuizQuestionResponse,
    QuizCreate,
    QuizResponse,
    GenerateRecallRequest,
    GenerateRecallResponse,
)

router = APIRouter(prefix="/recall", tags=["study_recall"])


def _extract_heuristic_flashcards(note_text: str, topic_title: str, count: int = 5) -> List[Dict[str, str]]:
    """Heuristically extract flashcards from Markdown notes and topic context."""
    cards = []
    lines = [line.strip() for line in note_text.splitlines() if line.strip()]

    # Pattern: Definition lists / Term: Explanation or **Term** - Explanation
    def_pattern = re.compile(r"^(?:[-*]\s*)?(?:\*\*)?([A-Za-z0-9_\s\-/]{3,40})(?:\*\*)?\s*(?::|—|-)\s*(.+)$")

    for line in lines:
        match = def_pattern.match(line)
        if match:
            term, desc = match.group(1).strip(), match.group(2).strip()
            if len(term) >= 3 and len(desc) >= 8:
                cards.append({
                    "front": f"What is {term}?",
                    "back": desc,
                })
        if len(cards) >= count:
            break

    # If not enough cards, extract headers and bullet lists
    if len(cards) < count:
        current_header = topic_title
        bullets = []
        for line in lines:
            if line.startswith("#"):
                if bullets:
                    cards.append({
                        "front": f"Key principles of {current_header}?",
                        "back": "; ".join(bullets[:4]),
                    })
                    bullets = []
                current_header = line.lstrip("#").strip()
            elif line.startswith(("-", "*", "•")):
                cleaned = line.lstrip("-*• ").strip()
                if len(cleaned) > 10:
                    bullets.append(cleaned)
            if len(cards) >= count:
                break

        if bullets and len(cards) < count:
            cards.append({
                "front": f"Key concepts under {current_header}?",
                "back": "; ".join(bullets[:4]),
            })

    # Foundational fallbacks if notes are brief or empty
    fallbacks = [
        {"front": f"What is the core purpose of {topic_title}?", "back": f"Defines fundamental mental models, protocols, and core execution requirements for {topic_title}."},
        {"front": f"What are common architectural tradeoffs in {topic_title}?", "back": "Balances latency, memory footprint, implementation complexity, and fault tolerance."},
        {"front": f"How do you test and verify {topic_title}?", "back": "Unit testing invariant assertions, boundary condition tests, property checks, and integration benchmarks."},
        {"front": f"What failure modes should you guard against in {topic_title}?", "back": "Resource leaks, unexpected concurrency races, unhandled edge states, and network timeouts."},
        {"front": f"How does {topic_title} scale in production?", "back": "Through modular decomposition, caching, asynchronous event loops, and horizontal partitioning."},
    ]

    for fb in fallbacks:
        if len(cards) >= count:
            break
        cards.append(fb)

    return cards[:count]


def _extract_heuristic_quiz(note_text: str, topic_title: str, count: int = 5) -> List[Dict[str, Any]]:
    """Heuristically generate multiple choice questions with plausible distractors."""
    cards = _extract_heuristic_flashcards(note_text, topic_title, count=count)
    questions = []

    distractor_pool = [
        "It acts strictly as an unbuffered FIFO queue with zero persistence guarantees",
        "It forces single-threaded synchronized execution across all client worker threads",
        "It bypasses all kernel-level permission checks and runtime validation",
        "It converts dynamic memory pointers into immutable disk-only blocks",
        "It triggers an immediate process termination upon receiving unauthenticated packets",
        "It stores state exclusively in volatile CPU L1 registers without memory caching",
        "It replaces standard system calls with hardware-specific microcode instructions",
    ]

    for idx, card in enumerate(cards):
        clean_front = card["front"].rstrip("?")
        q_text = f"Regarding {topic_title}: {clean_front}?"
        correct_ans = card["back"]
        if len(correct_ans) > 120:
            correct_ans = correct_ans[:117] + "..."

        distractors = [distractor_pool[(idx + i) % len(distractor_pool)] for i in range(1, 4)]
        correct_idx = idx % 4

        options = list(distractors)
        options.insert(correct_idx, correct_ans)

        questions.append({
            "question": q_text,
            "options": options[:4],
            "correct_index": correct_idx,
            "explanation": f"Correct: {card['back']}",
        })

    return questions[:count]


def _deck_to_response(deck: FlashcardDeck) -> DeckResponse:
    cards = deck.cards or []
    mastered = sum(1 for c in cards if c.is_mastered)
    return DeckResponse(
        id=deck.id,
        topic_id=deck.topic_id,
        topic_title=deck.topic.title if deck.topic else None,
        title=deck.title,
        description=deck.description,
        total_cards=len(cards),
        mastered_cards=mastered,
        created_at=deck.created_at,
        cards=[
            FlashcardResponse(
                id=c.id,
                deck_id=c.deck_id,
                front=c.front,
                back=c.back,
                is_mastered=c.is_mastered,
                review_count=c.review_count,
                created_at=c.created_at,
            )
            for c in cards
        ],
    )


def _quiz_to_response(quiz: Quiz) -> QuizResponse:
    qs = quiz.questions or []
    out_questions = []
    for q in qs:
        opts = []
        try:
            opts = json.loads(q.options_json)
        except Exception:
            opts = ["Option A", "Option B", "Option C", "Option D"]

        out_questions.append(
            QuizQuestionResponse(
                id=q.id,
                quiz_id=q.quiz_id,
                question=q.question,
                options=opts,
                correct_index=q.correct_index,
                explanation=q.explanation,
            )
        )

    return QuizResponse(
        id=quiz.id,
        topic_id=quiz.topic_id,
        topic_title=quiz.topic.title if quiz.topic else None,
        title=quiz.title,
        description=quiz.description,
        questions_count=len(qs),
        created_at=quiz.created_at,
        questions=out_questions,
    )


# ── Active Recall Generator ──────────────────────────────────────────────────

@router.post("/generate", response_model=GenerateRecallResponse, status_code=status.HTTP_201_CREATED)
def generate_recall(payload: GenerateRecallRequest, db: Session = Depends(get_db)):
    """Generate flashcards and quiz questions from topic note or text via Ollama or built-in heuristic engine."""
    topic_title = "Study Topic"
    note_content = payload.note_content or ""

    if payload.topic_id:
        topic = db.get(Topic, payload.topic_id)
        if not topic:
            raise HTTPException(status_code=404, detail="Topic not found")
        topic_title = topic.title
        if not note_content:
            note = db.query(Note).filter(Note.topic_id == payload.topic_id).first()
            if note and note.content:
                note_content = note.content

    if not note_content.strip() and not payload.topic_id:
        raise HTTPException(status_code=400, detail="Either topic_id or note_content is required")

    model_used = "builtin-offline"
    generated_cards = []
    generated_quiz = []

    # Attempt Ollama if online
    connected, models = check_ollama_connection()
    if connected and models:
        model_name = payload.model if (payload.model and payload.model in models) else models[0]
        prompt = (
            f"You are an active recall tutor. Extract {payload.count} flashcards and {payload.count} multiple choice questions "
            f"from these notes on '{topic_title}':\n"
            f"{note_content[:2000]}\n\n"
            "Respond ONLY with valid JSON having this exact structure:\n"
            "{\"flashcards\": [{\"front\": \"Question?\", \"back\": \"Answer\"}], "
            "\"quiz\": [{\"question\": \"Q?\", \"options\": [\"A\",\"B\",\"C\",\"D\"], \"correct_index\": 0, \"explanation\": \"Exp\"}]}"
        )
        response_text = call_ollama_generate(prompt, model_name)
        if response_text:
            try:
                # Find JSON block
                json_match = re.search(r"\{.*\}", response_text, re.DOTALL)
                if json_match:
                    parsed = json.loads(json_match.group(0))
                    if "flashcards" in parsed and isinstance(parsed["flashcards"], list):
                        generated_cards = parsed["flashcards"]
                    if "quiz" in parsed and isinstance(parsed["quiz"], list):
                        generated_quiz = parsed["quiz"]
                    model_used = model_name
            except Exception:
                pass

    # Heuristic fallback if Ollama was offline or parsing failed
    if not generated_cards and payload.generate_flashcards:
        generated_cards = _extract_heuristic_flashcards(note_content, topic_title, count=payload.count)
    if not generated_quiz and payload.generate_quiz:
        generated_quiz = _extract_heuristic_quiz(note_content, topic_title, count=payload.count)

    out_deck_res = None
    out_quiz_res = None

    # 1. Create FlashcardDeck & Cards
    if payload.generate_flashcards and generated_cards:
        deck = FlashcardDeck(
            topic_id=payload.topic_id,
            title=f"{topic_title} Flashcards",
            description=f"Generated via StudyOS ({model_used}) from topic notes",
        )
        db.add(deck)
        db.commit()
        db.refresh(deck)

        for c_data in generated_cards:
            fc = Flashcard(
                deck_id=deck.id,
                front=c_data.get("front", f"Question about {topic_title}"),
                back=c_data.get("back", f"Key concept of {topic_title}"),
                is_mastered=False,
                review_count=0,
            )
            db.add(fc)
        db.commit()
        db.refresh(deck)
        out_deck_res = _deck_to_response(deck)

    # 2. Create Quiz & Questions
    if payload.generate_quiz and generated_quiz:
        quiz = Quiz(
            topic_id=payload.topic_id,
            title=f"{topic_title} Mastery Quiz",
            description=f"Active recall quiz generated via StudyOS ({model_used})",
        )
        db.add(quiz)
        db.commit()
        db.refresh(quiz)

        for q_data in generated_quiz:
            options = q_data.get("options", ["A", "B", "C", "D"])
            if len(options) < 4:
                options += [f"Distractor {i}" for i in range(len(options), 4)]
            qq = QuizQuestion(
                quiz_id=quiz.id,
                question=q_data.get("question", f"Question on {topic_title}"),
                options_json=json.dumps(options[:4]),
                correct_index=int(q_data.get("correct_index", 0)) % 4,
                explanation=q_data.get("explanation"),
            )
            db.add(qq)
        db.commit()
        db.refresh(quiz)
        out_quiz_res = _quiz_to_response(quiz)

    return GenerateRecallResponse(
        deck=out_deck_res,
        quiz=out_quiz_res,
        model_used=model_used,
        generated_cards_count=len(generated_cards) if payload.generate_flashcards else 0,
        generated_questions_count=len(generated_quiz) if payload.generate_quiz else 0,
    )


# ── Flashcard Decks CRUD ─────────────────────────────────────────────────────

@router.get("/decks/", response_model=List[DeckResponse])
def list_decks(topic_id: Optional[int] = Query(None), db: Session = Depends(get_db)):
    """List all flashcard decks, optionally filtered by topic_id."""
    query = db.query(FlashcardDeck)
    if topic_id is not None:
        query = query.filter(FlashcardDeck.topic_id == topic_id)
    decks = query.order_by(FlashcardDeck.created_at.desc()).all()
    return [_deck_to_response(d) for d in decks]


@router.get("/decks/{deck_id}", response_model=DeckResponse)
def get_deck(deck_id: int, db: Session = Depends(get_db)):
    """Get single flashcard deck with all cards."""
    deck = db.get(FlashcardDeck, deck_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found")
    return _deck_to_response(deck)


@router.post("/decks/", response_model=DeckResponse, status_code=status.HTTP_201_CREATED)
def create_deck(payload: DeckCreate, db: Session = Depends(get_db)):
    """Create a manual flashcard deck."""
    if payload.topic_id and not db.get(Topic, payload.topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")

    deck = FlashcardDeck(
        topic_id=payload.topic_id,
        title=payload.title.strip(),
        description=payload.description,
    )
    db.add(deck)
    db.commit()
    db.refresh(deck)

    for c in payload.cards:
        fc = Flashcard(
            deck_id=deck.id,
            front=c.front.strip(),
            back=c.back.strip(),
        )
        db.add(fc)
    db.commit()
    db.refresh(deck)
    return _deck_to_response(deck)


@router.delete("/decks/{deck_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_deck(deck_id: int, db: Session = Depends(get_db)):
    """Delete a flashcard deck and its cards."""
    deck = db.get(FlashcardDeck, deck_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found")
    db.delete(deck)
    db.commit()


@router.post("/decks/{deck_id}/cards", response_model=FlashcardResponse, status_code=status.HTTP_201_CREATED)
def add_card_to_deck(deck_id: int, payload: FlashcardCreate, db: Session = Depends(get_db)):
    """Add a flashcard to an existing deck."""
    deck = db.get(FlashcardDeck, deck_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found")

    fc = Flashcard(
        deck_id=deck_id,
        front=payload.front.strip(),
        back=payload.back.strip(),
        is_mastered=False,
        review_count=0,
    )
    db.add(fc)
    db.commit()
    db.refresh(fc)
    return fc


@router.patch("/cards/{card_id}/mastery", response_model=FlashcardResponse)
def toggle_card_mastery(card_id: int, is_mastered: bool = Query(...), db: Session = Depends(get_db)):
    """Toggle mastery and increment review count for a flashcard."""
    card = db.get(Flashcard, card_id)
    if not card:
        raise HTTPException(status_code=404, detail="Card not found")
    card.is_mastered = is_mastered
    card.review_count += 1
    db.commit()
    db.refresh(card)
    return card


@router.delete("/cards/{card_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_card(card_id: int, db: Session = Depends(get_db)):
    """Delete single flashcard."""
    card = db.get(Flashcard, card_id)
    if not card:
        raise HTTPException(status_code=404, detail="Card not found")
    db.delete(card)
    db.commit()


# ── Quizzes CRUD ─────────────────────────────────────────────────────────────

@router.get("/quizzes/", response_model=List[QuizResponse])
def list_quizzes(topic_id: Optional[int] = Query(None), db: Session = Depends(get_db)):
    """List all quizzes, optionally filtered by topic_id."""
    query = db.query(Quiz)
    if topic_id is not None:
        query = query.filter(Quiz.topic_id == topic_id)
    quizzes = query.order_by(Quiz.created_at.desc()).all()
    return [_quiz_to_response(q) for q in quizzes]


@router.get("/quizzes/{quiz_id}", response_model=QuizResponse)
def get_quiz(quiz_id: int, db: Session = Depends(get_db)):
    """Get single quiz with all questions."""
    quiz = db.get(Quiz, quiz_id)
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    return _quiz_to_response(quiz)


@router.post("/quizzes/", response_model=QuizResponse, status_code=status.HTTP_201_CREATED)
def create_quiz(payload: QuizCreate, db: Session = Depends(get_db)):
    """Create a manual quiz."""
    if payload.topic_id and not db.get(Topic, payload.topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")

    quiz = Quiz(
        topic_id=payload.topic_id,
        title=payload.title.strip(),
        description=payload.description,
    )
    db.add(quiz)
    db.commit()
    db.refresh(quiz)

    for q in payload.questions:
        qq = QuizQuestion(
            quiz_id=quiz.id,
            question=q.question.strip(),
            options_json=json.dumps(q.options[:4]),
            correct_index=q.correct_index % 4,
            explanation=q.explanation,
        )
        db.add(qq)
    db.commit()
    db.refresh(quiz)
    return _quiz_to_response(quiz)


@router.delete("/quizzes/{quiz_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_quiz(quiz_id: int, db: Session = Depends(get_db)):
    """Delete a quiz and its questions."""
    quiz = db.get(Quiz, quiz_id)
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    db.delete(quiz)
    db.commit()


@router.post("/quizzes/{quiz_id}/questions", response_model=QuizQuestionResponse, status_code=status.HTTP_201_CREATED)
def add_question_to_quiz(quiz_id: int, payload: QuizQuestionCreate, db: Session = Depends(get_db)):
    """Add a question to an existing quiz."""
    quiz = db.get(Quiz, quiz_id)
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    options = payload.options[:4]
    if len(options) < 4:
        options += [f"Distractor {i}" for i in range(len(options), 4)]

    qq = QuizQuestion(
        quiz_id=quiz_id,
        question=payload.question.strip(),
        options_json=json.dumps(options),
        correct_index=payload.correct_index % 4,
        explanation=payload.explanation,
    )
    db.add(qq)
    db.commit()
    db.refresh(qq)

    return QuizQuestionResponse(
        id=qq.id,
        quiz_id=qq.quiz_id,
        question=qq.question,
        options=options,
        correct_index=qq.correct_index,
        explanation=qq.explanation,
    )


@router.delete("/questions/{question_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_question(question_id: int, db: Session = Depends(get_db)):
    """Delete single quiz question."""
    question = db.get(QuizQuestion, question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")
    db.delete(question)
    db.commit()
