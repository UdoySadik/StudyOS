"""Notes router — upsert pattern (create or update per topic)."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models.note import Note
from models.topic import Topic
from schemas.note import NoteUpsert, NoteResponse

router = APIRouter(prefix="/notes", tags=["notes"])


@router.get("/", response_model=List[NoteResponse])
def list_notes_with_content(db: Session = Depends(get_db)):
    """Return all notes that have non-empty content."""
    return db.query(Note).filter(Note.content != "").all()


@router.get("/topic/{topic_id}", response_model=NoteResponse)
def get_note(topic_id: int, db: Session = Depends(get_db)):
    if not db.get(Topic, topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")
    note = db.query(Note).filter(Note.topic_id == topic_id).first()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return note


@router.put("/topic/{topic_id}", response_model=NoteResponse)
def upsert_note(topic_id: int, payload: NoteUpsert, db: Session = Depends(get_db)):
    """Create note if it doesn't exist, otherwise update content."""
    if not db.get(Topic, topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")
    note = db.query(Note).filter(Note.topic_id == topic_id).first()
    if note:
        note.content = payload.content
    else:
        note = Note(topic_id=topic_id, content=payload.content)
        db.add(note)
    db.commit()
    db.refresh(note)
    return note


@router.delete("/topic/{topic_id}", status_code=204)
def delete_note(topic_id: int, db: Session = Depends(get_db)):
    note = db.query(Note).filter(Note.topic_id == topic_id).first()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    db.delete(note)
    db.commit()
