"""SQLAlchemy model for tracking local device identity and sync history."""

from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from database import Base


class SyncDevice(Base):
    """Tracks local device sync metadata and encryption fingerprint."""
    __tablename__ = "sync_devices"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, unique=True, index=True, nullable=False)
    device_name = Column(String, nullable=False, default="StudyOS Desktop")
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_synced_at = Column(DateTime, nullable=True)
    sync_count = Column(Integer, default=0, nullable=False)
    device_fingerprint = Column(String, nullable=True)
