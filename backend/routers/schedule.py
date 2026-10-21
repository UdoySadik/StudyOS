"""Daily Schedule & Time-Blocking router."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models.schedule_block import ScheduleBlock
from models.topic import Topic
from schemas.schedule_block import ScheduleBlockCreate, ScheduleBlockUpdate, ScheduleBlockResponse
from typing import List, Optional
from datetime import date
from pydantic import BaseModel

router = APIRouter(prefix="/schedule", tags=["schedule"])


class CompletePayload(BaseModel):
    is_completed: bool


@router.get("/", response_model=List[ScheduleBlockResponse])
def list_schedule_blocks(target_date: Optional[date] = None, db: Session = Depends(get_db)):
    """List schedule blocks, optionally filtered by scheduled_date."""
    query = db.query(ScheduleBlock)
    if target_date:
        query = query.filter(ScheduleBlock.scheduled_date == target_date)
    return query.order_by(ScheduleBlock.scheduled_date.asc(), ScheduleBlock.start_time.asc()).all()


@router.post("/", response_model=ScheduleBlockResponse, status_code=status.HTTP_201_CREATED)
def create_schedule_block(payload: ScheduleBlockCreate, db: Session = Depends(get_db)):
    if payload.topic_id and not db.get(Topic, payload.topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")
    block = ScheduleBlock(**payload.model_dump())
    db.add(block)
    db.commit()
    db.refresh(block)
    return block


@router.get("/{block_id}", response_model=ScheduleBlockResponse)
def get_schedule_block(block_id: int, db: Session = Depends(get_db)):
    block = db.get(ScheduleBlock, block_id)
    if not block:
        raise HTTPException(status_code=404, detail="Schedule block not found")
    return block


@router.patch("/{block_id}", response_model=ScheduleBlockResponse)
def update_schedule_block(block_id: int, payload: ScheduleBlockUpdate, db: Session = Depends(get_db)):
    block = db.get(ScheduleBlock, block_id)
    if not block:
        raise HTTPException(status_code=404, detail="Schedule block not found")
    update_data = payload.model_dump(exclude_unset=True)
    if "topic_id" in update_data and update_data["topic_id"] is not None:
        if not db.get(Topic, update_data["topic_id"]):
            raise HTTPException(status_code=404, detail="Topic not found")
    for key, value in update_data.items():
        setattr(block, key, value)
    db.commit()
    db.refresh(block)
    return block


@router.patch("/{block_id}/complete", response_model=ScheduleBlockResponse)
def toggle_schedule_complete(block_id: int, payload: CompletePayload, db: Session = Depends(get_db)):
    block = db.get(ScheduleBlock, block_id)
    if not block:
        raise HTTPException(status_code=404, detail="Schedule block not found")
    block.is_completed = payload.is_completed
    db.commit()
    db.refresh(block)
    return block


@router.delete("/{block_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_schedule_block(block_id: int, db: Session = Depends(get_db)):
    block = db.get(ScheduleBlock, block_id)
    if not block:
        raise HTTPException(status_code=404, detail="Schedule block not found")
    db.delete(block)
    db.commit()
