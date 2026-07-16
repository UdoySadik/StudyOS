"""Topic CRUD router — includes mark-complete toggle."""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models.topic import Topic
from models.phase import Phase
from schemas.topic import TopicCreate, TopicUpdate, TopicCompleteToggle, TopicResponse

router = APIRouter(prefix="/topics", tags=["topics"])


@router.get("/phase/{phase_id}", response_model=List[TopicResponse])
def list_topics(phase_id: int, db: Session = Depends(get_db)):
    return db.query(Topic).filter(Topic.phase_id == phase_id).order_by(Topic.order_index).all()


@router.post("/", response_model=TopicResponse, status_code=status.HTTP_201_CREATED)
def create_topic(payload: TopicCreate, db: Session = Depends(get_db)):
    if not db.get(Phase, payload.phase_id):
        raise HTTPException(status_code=404, detail="Phase not found")
    if payload.order_index == 0:
        count = db.query(Topic).filter(Topic.phase_id == payload.phase_id).count()
        payload.order_index = count
    topic = Topic(**payload.model_dump())
    db.add(topic)
    db.commit()
    db.refresh(topic)
    return topic


@router.get("/{topic_id}", response_model=TopicResponse)
def get_topic(topic_id: int, db: Session = Depends(get_db)):
    topic = db.get(Topic, topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    return topic


@router.patch("/{topic_id}", response_model=TopicResponse)
def update_topic(topic_id: int, payload: TopicUpdate, db: Session = Depends(get_db)):
    topic = db.get(Topic, topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(topic, key, value)
    db.commit()
    db.refresh(topic)
    return topic


@router.patch("/{topic_id}/complete", response_model=TopicResponse)
def toggle_complete(topic_id: int, payload: TopicCompleteToggle, db: Session = Depends(get_db)):
    """Mark a topic as complete or incomplete."""
    topic = db.get(Topic, topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    topic.is_completed = payload.is_completed
    topic.completed_at = datetime.now(timezone.utc) if payload.is_completed else None
    db.commit()
    db.refresh(topic)
    return topic


@router.delete("/{topic_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_topic(topic_id: int, db: Session = Depends(get_db)):
    topic = db.get(Topic, topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    db.delete(topic)
    db.commit()
