"""Phase CRUD router."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models.phase import Phase
from models.roadmap import Roadmap
from schemas.phase import PhaseCreate, PhaseUpdate, PhaseResponse

router = APIRouter(prefix="/phases", tags=["phases"])


@router.get("/roadmap/{roadmap_id}", response_model=List[PhaseResponse])
def list_phases(roadmap_id: int, db: Session = Depends(get_db)):
    return db.query(Phase).filter(Phase.roadmap_id == roadmap_id).order_by(Phase.order_index).all()


@router.post("/", response_model=PhaseResponse, status_code=status.HTTP_201_CREATED)
def create_phase(payload: PhaseCreate, db: Session = Depends(get_db)):
    if not db.get(Roadmap, payload.roadmap_id):
        raise HTTPException(status_code=404, detail="Roadmap not found")
    # Auto-assign order index if not specified
    if payload.order_index == 0:
        count = db.query(Phase).filter(Phase.roadmap_id == payload.roadmap_id).count()
        payload.order_index = count
    phase = Phase(**payload.model_dump())
    db.add(phase)
    db.commit()
    db.refresh(phase)
    return phase


@router.get("/{phase_id}", response_model=PhaseResponse)
def get_phase(phase_id: int, db: Session = Depends(get_db)):
    phase = db.get(Phase, phase_id)
    if not phase:
        raise HTTPException(status_code=404, detail="Phase not found")
    return phase


@router.patch("/{phase_id}", response_model=PhaseResponse)
def update_phase(phase_id: int, payload: PhaseUpdate, db: Session = Depends(get_db)):
    phase = db.get(Phase, phase_id)
    if not phase:
        raise HTTPException(status_code=404, detail="Phase not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(phase, key, value)
    db.commit()
    db.refresh(phase)
    return phase


@router.delete("/{phase_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_phase(phase_id: int, db: Session = Depends(get_db)):
    phase = db.get(Phase, phase_id)
    if not phase:
        raise HTTPException(status_code=404, detail="Phase not found")
    db.delete(phase)
    db.commit()
