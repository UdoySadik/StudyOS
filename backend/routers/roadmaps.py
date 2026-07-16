"""Roadmap CRUD router."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models.roadmap import Roadmap
from schemas.roadmap import RoadmapCreate, RoadmapUpdate, RoadmapResponse
from typing import List

router = APIRouter(prefix="/roadmaps", tags=["roadmaps"])


@router.get("/", response_model=List[RoadmapResponse])
def list_roadmaps(db: Session = Depends(get_db)):
    return db.query(Roadmap).order_by(Roadmap.created_at.desc()).all()


@router.post("/", response_model=RoadmapResponse, status_code=status.HTTP_201_CREATED)
def create_roadmap(payload: RoadmapCreate, db: Session = Depends(get_db)):
    roadmap = Roadmap(**payload.model_dump())
    db.add(roadmap)
    db.commit()
    db.refresh(roadmap)
    return roadmap


@router.get("/{roadmap_id}", response_model=RoadmapResponse)
def get_roadmap(roadmap_id: int, db: Session = Depends(get_db)):
    roadmap = db.get(Roadmap, roadmap_id)
    if not roadmap:
        raise HTTPException(status_code=404, detail="Roadmap not found")
    return roadmap


@router.patch("/{roadmap_id}", response_model=RoadmapResponse)
def update_roadmap(roadmap_id: int, payload: RoadmapUpdate, db: Session = Depends(get_db)):
    roadmap = db.get(Roadmap, roadmap_id)
    if not roadmap:
        raise HTTPException(status_code=404, detail="Roadmap not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(roadmap, key, value)
    db.commit()
    db.refresh(roadmap)
    return roadmap


@router.delete("/{roadmap_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_roadmap(roadmap_id: int, db: Session = Depends(get_db)):
    roadmap = db.get(Roadmap, roadmap_id)
    if not roadmap:
        raise HTTPException(status_code=404, detail="Roadmap not found")
    db.delete(roadmap)
    db.commit()
