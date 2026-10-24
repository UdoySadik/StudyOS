"""Projects CRUD router for Practice Project Tracker with GitHub links."""

from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload
from database import get_db
from models.project import Project
from models.roadmap import Roadmap
from models.topic import Topic
from schemas.project import (
    ProjectCreate,
    ProjectUpdate,
    ProjectStatusUpdate,
    ProjectResponse,
)

router = APIRouter(prefix="/projects", tags=["projects"])

VALID_STATUSES = {"not_started", "in_progress", "completed", "on_hold"}
VALID_DIFFICULTIES = {"beginner", "medium", "advanced"}


def _to_response(proj: Project) -> ProjectResponse:
    return ProjectResponse(
        id=proj.id,
        roadmap_id=proj.roadmap_id,
        topic_id=proj.topic_id,
        title=proj.title,
        description=proj.description,
        github_url=proj.github_url,
        live_url=proj.live_url,
        status=proj.status,
        difficulty=proj.difficulty,
        tech_stack=proj.tech_stack,
        created_at=proj.created_at,
        completed_at=proj.completed_at,
        roadmap_title=proj.roadmap.title if proj.roadmap else None,
        topic_title=proj.topic.title if proj.topic else None,
    )


@router.get("/", response_model=List[ProjectResponse])
def list_projects(
    roadmap_id: Optional[int] = Query(None, description="Filter by roadmap ID"),
    topic_id: Optional[int] = Query(None, description="Filter by topic ID"),
    status: Optional[str] = Query(None, description="Filter by status"),
    db: Session = Depends(get_db),
):
    query = (
        db.query(Project)
        .options(joinedload(Project.roadmap), joinedload(Project.topic))
    )
    if roadmap_id is not None:
        query = query.filter(Project.roadmap_id == roadmap_id)
    if topic_id is not None:
        query = query.filter(Project.topic_id == topic_id)
    if status is not None:
        query = query.filter(Project.status == status)

    projects = query.order_by(Project.created_at.desc()).all()
    return [_to_response(p) for p in projects]


@router.get("/roadmap/{roadmap_id}", response_model=List[ProjectResponse])
def list_projects_for_roadmap(roadmap_id: int, db: Session = Depends(get_db)):
    if not db.get(Roadmap, roadmap_id):
        raise HTTPException(status_code=404, detail="Roadmap not found")
    projects = (
        db.query(Project)
        .options(joinedload(Project.roadmap), joinedload(Project.topic))
        .filter(Project.roadmap_id == roadmap_id)
        .order_by(Project.created_at.desc())
        .all()
    )
    return [_to_response(p) for p in projects]


@router.get("/topic/{topic_id}", response_model=List[ProjectResponse])
def list_projects_for_topic(topic_id: int, db: Session = Depends(get_db)):
    if not db.get(Topic, topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")
    projects = (
        db.query(Project)
        .options(joinedload(Project.roadmap), joinedload(Project.topic))
        .filter(Project.topic_id == topic_id)
        .order_by(Project.created_at.desc())
        .all()
    )
    return [_to_response(p) for p in projects]


@router.get("/{project_id}", response_model=ProjectResponse)
def get_project(project_id: int, db: Session = Depends(get_db)):
    proj = (
        db.query(Project)
        .options(joinedload(Project.roadmap), joinedload(Project.topic))
        .filter(Project.id == project_id)
        .first()
    )
    if not proj:
        raise HTTPException(status_code=404, detail="Project not found")
    return _to_response(proj)


@router.post("/", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
def create_project(payload: ProjectCreate, db: Session = Depends(get_db)):
    if not db.get(Roadmap, payload.roadmap_id):
        raise HTTPException(status_code=404, detail="Roadmap not found")
    if payload.topic_id and not db.get(Topic, payload.topic_id):
        raise HTTPException(status_code=404, detail="Topic not found")

    if payload.status not in VALID_STATUSES:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of {VALID_STATUSES}")
    if payload.difficulty not in VALID_DIFFICULTIES:
        raise HTTPException(status_code=400, detail=f"Invalid difficulty. Must be one of {VALID_DIFFICULTIES}")

    data = payload.model_dump()
    if data.get("status") == "completed":
        data["completed_at"] = datetime.now(timezone.utc)

    project = Project(**data)
    db.add(project)
    db.commit()
    db.refresh(project)

    # Reload with relationships
    return get_project(project.id, db)


@router.patch("/{project_id}", response_model=ProjectResponse)
def update_project(project_id: int, payload: ProjectUpdate, db: Session = Depends(get_db)):
    project = db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    if payload.topic_id is not None and payload.topic_id != 0:
        if not db.get(Topic, payload.topic_id):
            raise HTTPException(status_code=404, detail="Topic not found")

    updates = payload.model_dump(exclude_unset=True)
    if "status" in updates:
        new_status = updates["status"]
        if new_status not in VALID_STATUSES:
            raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of {VALID_STATUSES}")
        if new_status == "completed" and project.status != "completed":
            project.completed_at = datetime.now(timezone.utc)
        elif new_status != "completed":
            project.completed_at = None

    if "difficulty" in updates:
        if updates["difficulty"] not in VALID_DIFFICULTIES:
            raise HTTPException(status_code=400, detail=f"Invalid difficulty. Must be one of {VALID_DIFFICULTIES}")

    for key, value in updates.items():
        setattr(project, key, value)

    db.commit()
    db.refresh(project)
    return get_project(project.id, db)


@router.patch("/{project_id}/status", response_model=ProjectResponse)
def update_project_status(
    project_id: int,
    payload: ProjectStatusUpdate,
    db: Session = Depends(get_db),
):
    project = db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    if payload.status not in VALID_STATUSES:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of {VALID_STATUSES}")

    project.status = payload.status
    if payload.status == "completed":
        project.completed_at = datetime.now(timezone.utc)
    else:
        project.completed_at = None

    db.commit()
    db.refresh(project)
    return get_project(project.id, db)


@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_project(project_id: int, db: Session = Depends(get_db)):
    project = db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    db.delete(project)
    db.commit()
