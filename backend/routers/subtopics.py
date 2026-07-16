"""Subtopic CRUD router."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models.subtopic import Subtopic
from models.topic import Topic
from schemas.subtopic import SubtopicCreate, SubtopicUpdate, SubtopicResponse

router = APIRouter(prefix="/subtopics", tags=["subtopics"])


@router.get("/topic/{topic_id}", response_model=List[SubtopicResponse])
def list_subtopics(topic_id: int, db: Session = Depends(get_db)):
    return db.query(Subtopic).filter(Subtopic.topic_id == topic_id).order_by(Subtopic.order_index).all()


@router.post("/", response_model=SubtopicResponse, status_code=status.HTTP_201_CREATED)
def create_subtopic(payload: SubtopicCreate, db: Session = Depends(get_db)):
    if not db.get(Topic, payload.topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")
    if payload.order_index == 0:
        count = db.query(Subtopic).filter(Subtopic.topic_id == payload.topic_id).count()
        payload.order_index = count
    subtopic = Subtopic(**payload.model_dump())
    db.add(subtopic)
    db.commit()
    db.refresh(subtopic)
    return subtopic


@router.patch("/{subtopic_id}", response_model=SubtopicResponse)
def update_subtopic(subtopic_id: int, payload: SubtopicUpdate, db: Session = Depends(get_db)):
    subtopic = db.get(Subtopic, subtopic_id)
    if not subtopic:
        raise HTTPException(status_code=404, detail="Subtopic not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(subtopic, key, value)
    db.commit()
    db.refresh(subtopic)
    return subtopic


@router.delete("/{subtopic_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_subtopic(subtopic_id: int, db: Session = Depends(get_db)):
    subtopic = db.get(Subtopic, subtopic_id)
    if not subtopic:
        raise HTTPException(status_code=404, detail="Subtopic not found")
    db.delete(subtopic)
    db.commit()
