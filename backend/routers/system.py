"""
StudyOS Backend — System Maintenance & Reset Router
"""

from fastapi import APIRouter, status
from database import Base, engine, init_db

router = APIRouter(prefix="/system", tags=["system"])


@router.post("/reset", status_code=status.HTTP_200_OK)
def reset_database():
    """Drop all tables and recreate clean schema."""
    Base.metadata.drop_all(bind=engine)
    init_db()
    return {
        "status": "reset_complete",
        "message": "All database tables have been dropped and re-initialized cleanly."
    }
