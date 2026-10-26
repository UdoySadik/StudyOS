"""Pydantic schemas for End-to-End Encrypted Multi-Device Sync."""

from datetime import datetime
from typing import Optional, Dict
from pydantic import BaseModel, Field


class SyncStatusResponse(BaseModel):
    device_id: str
    device_name: str
    created_at: Optional[datetime] = None
    last_synced_at: Optional[datetime] = None
    sync_count: int = 0
    total_roadmaps: int = 0
    total_phases: int = 0
    total_topics: int = 0
    total_notes: int = 0
    total_goals: int = 0
    total_flashcards: int = 0
    total_quizzes: int = 0
    total_documents: int = 0
    database_revision: str


class SyncExportRequest(BaseModel):
    passphrase: str = Field(..., min_length=6, description="Master encryption passkey for AES-GCM-256")
    device_name: Optional[str] = Field(None, max_length=100)
    include_documents: bool = Field(True, description="Whether to include indexed document chunks in the sync bundle")


class SyncExportResponse(BaseModel):
    bundle_version: str = "1.0"
    device_id: str
    device_name: str
    exported_at: datetime
    salt_hex: str
    nonce_hex: str
    ciphertext_base64: str
    checksum_sha256: str
    entity_counts: Dict[str, int]


class SyncImportRequest(BaseModel):
    passphrase: str = Field(..., min_length=6, description="Master encryption passkey used to encrypt bundle")
    salt_hex: str
    nonce_hex: str
    ciphertext_base64: str
    checksum_sha256: Optional[str] = None
    merge_mode: str = Field("merge", description="'merge' for safe additive upsert or 'overwrite' for clean replacement")


class SyncImportResponse(BaseModel):
    success: bool
    message: str
    entities_imported: Dict[str, int]
    conflicts_resolved: int = 0
    imported_at: datetime


class DeviceRegisterRequest(BaseModel):
    device_name: str = Field(..., min_length=2, max_length=100)
