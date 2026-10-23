"""Resource CRUD router for Topic Learning Resource Shelf."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models.resource import Resource
from models.topic import Topic
from schemas.resource import (
    ResourceCreate,
    ResourceUpdate,
    ResourceCompleteToggle,
    ResourceResponse,
)

router = APIRouter(prefix="/resources", tags=["resources"])


@router.get("/topic/{topic_id}", response_model=List[ResourceResponse])
def list_resources_for_topic(topic_id: int, db: Session = Depends(get_db)):
    if not db.get(Topic, topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")
    return (
        db.query(Resource)
        .filter(Resource.topic_id == topic_id)
        .order_by(Resource.is_completed.asc(), Resource.created_at.desc())
        .all()
    )


@router.get("/{resource_id}", response_model=ResourceResponse)
def get_resource(resource_id: int, db: Session = Depends(get_db)):
    resource = db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(status_code=404, detail="Resource not found")
    return resource


@router.post("/", response_model=ResourceResponse, status_code=status.HTTP_201_CREATED)
def create_resource(payload: ResourceCreate, db: Session = Depends(get_db)):
    if not db.get(Topic, payload.topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")
    resource = Resource(**payload.model_dump())
    db.add(resource)
    db.commit()
    db.refresh(resource)
    return resource


@router.patch("/{resource_id}", response_model=ResourceResponse)
def update_resource(resource_id: int, payload: ResourceUpdate, db: Session = Depends(get_db)):
    resource = db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(status_code=404, detail="Resource not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(resource, key, value)
    db.commit()
    db.refresh(resource)
    return resource


@router.patch("/{resource_id}/complete", response_model=ResourceResponse)
def toggle_resource_complete(
    resource_id: int,
    payload: ResourceCompleteToggle,
    db: Session = Depends(get_db),
):
    resource = db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(status_code=404, detail="Resource not found")
    resource.is_completed = payload.is_completed
    db.commit()
    db.refresh(resource)
    return resource


@router.delete("/{resource_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_resource(resource_id: int, db: Session = Depends(get_db)):
    resource = db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(status_code=404, detail="Resource not found")
    db.delete(resource)
    db.commit()
