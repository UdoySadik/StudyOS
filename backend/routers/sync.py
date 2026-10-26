"""FastAPI router for End-to-End Encrypted Multi-Device Sync."""

import os
import json
import base64
import hashlib
import secrets
from datetime import datetime, timezone
from typing import Tuple, Dict, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

from database import get_db, init_db, Base, engine
from models.sync_device import SyncDevice
from models.roadmap import Roadmap
from models.phase import Phase
from models.topic import Topic
from models.subtopic import Subtopic
from models.note import Note
from models.goal import Goal
from models.schedule_block import ScheduleBlock
from models.study_session import StudySession
from models.resource import Resource
from models.project import Project
from models.flashcard import FlashcardDeck, Flashcard
from models.quiz import Quiz, QuizQuestion
from models.document import Document, DocumentChunk

from schemas.sync import (
    SyncStatusResponse,
    SyncExportRequest,
    SyncExportResponse,
    SyncImportRequest,
    SyncImportResponse,
    DeviceRegisterRequest,
)

router = APIRouter(prefix="/sync", tags=["sync"])


# ── Cryptography Utilities ──────────────────────────────────────────────────

def _derive_key(passphrase: str, salt: bytes) -> bytes:
    """Derive 256-bit symmetric encryption key using PBKDF2-HMAC-SHA256."""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    return kdf.derive(passphrase.encode("utf-8"))


def _encrypt_payload(payload_dict: dict, passphrase: str) -> Tuple[str, str, str, str]:
    """
    Encrypt dictionary with AES-256-GCM.
    Returns: (salt_hex, nonce_hex, ciphertext_base64, checksum_sha256)
    """
    raw_json = json.dumps(payload_dict, sort_keys=True, default=str).encode("utf-8")
    checksum = hashlib.sha256(raw_json).hexdigest()

    salt = secrets.token_bytes(16)
    key = _derive_key(passphrase, salt)
    nonce = secrets.token_bytes(12)

    aesgcm = AESGCM(key)
    ciphertext = aesgcm.encrypt(nonce, raw_json, None)

    return (
        salt.hex(),
        nonce.hex(),
        base64.b64encode(ciphertext).decode("utf-8"),
        checksum,
    )


def _decrypt_payload(
    ciphertext_b64: str,
    passphrase: str,
    salt_hex: str,
    nonce_hex: str,
    checksum_sha256: Optional[str] = None,
) -> dict:
    """
    Decrypt base64 ciphertext with AES-256-GCM and verify integrity checksum.
    """
    try:
        salt = bytes.fromhex(salt_hex)
        nonce = bytes.fromhex(nonce_hex)
        ciphertext = base64.b64decode(ciphertext_b64)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Malformed cryptographic parameters: {e}",
        )

    key = _derive_key(passphrase, salt)
    aesgcm = AESGCM(key)

    try:
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Decryption failed. Incorrect passphrase or corrupted payload.",
        )

    if checksum_sha256:
        calculated_hash = hashlib.sha256(plaintext).hexdigest()
        if calculated_hash.lower() != checksum_sha256.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payload integrity verification failed (SHA-256 mismatch).",
            )

    try:
        return json.loads(plaintext.decode("utf-8"))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Decrypted content is not valid JSON: {e}",
        )


# ── Device Identity Helper ──────────────────────────────────────────────────

def _get_or_create_device(db: Session, preferred_name: Optional[str] = None) -> SyncDevice:
    """Retrieve the primary local device registration or initialize a new one."""
    dev = db.query(SyncDevice).first()
    if not dev:
        dev = SyncDevice(
            device_id=f"dev_{secrets.token_hex(6)}",
            device_name=preferred_name or "StudyOS Desktop Workstation",
            created_at=datetime.now(timezone.utc),
            sync_count=0,
        )
        db.add(dev)
        db.commit()
        db.refresh(dev)
    elif preferred_name and dev.device_name != preferred_name:
        dev.device_name = preferred_name
        db.commit()
        db.refresh(dev)
    return dev


# ── Data Collection & Serialization ──────────────────────────────────────────

def _collect_all_entities(db: Session, include_documents: bool = True) -> Tuple[Dict[str, Any], Dict[str, int]]:
    """Serialize all SQLite tables into an unencrypted dictionary."""
    counts = {}

    # 1. Roadmaps with Phases, Topics, Subtopics
    roadmaps_data = []
    for rm in db.query(Roadmap).all():
        phases_data = []
        for ph in rm.phases:
            topics_data = []
            for tp in ph.topics:
                subtopics_data = [
                    {
                        "title": st.title,
                        "order_index": st.order_index,
                        "is_completed": st.is_completed,
                    }
                    for st in tp.subtopics
                ]
                topics_data.append({
                    "title": tp.title,
                    "order_index": tp.order_index,
                    "is_completed": tp.is_completed,
                    "subtopics": subtopics_data,
                })
            phases_data.append({
                "title": ph.title,
                "order_index": ph.order_index,
                "topics": topics_data,
            })
        roadmaps_data.append({
            "title": rm.title,
            "description": rm.description,
            "created_at": rm.created_at.isoformat() if rm.created_at else None,
            "phases": phases_data,
        })
    counts["roadmaps"] = len(roadmaps_data)

    # 2. Notes
    notes_data = []
    for n in db.query(Note).all():
        tp = db.query(Topic).filter(Topic.id == n.topic_id).first()
        topic_title = tp.title if tp else None
        notes_data.append({
            "topic_title": topic_title,
            "content": n.content,
            "updated_at": n.updated_at.isoformat() if n.updated_at else None,
        })
    counts["notes"] = len(notes_data)

    # 3. Goals
    goals_data = []
    for g in db.query(Goal).all():
        rm = db.query(Roadmap).filter(Roadmap.id == g.roadmap_id).first()
        roadmap_title = rm.title if rm else None
        goals_data.append({
            "roadmap_title": roadmap_title,
            "target_date": g.target_date.isoformat() if g.target_date else None,
            "created_at": g.created_at.isoformat() if g.created_at else None,
        })
    counts["goals"] = len(goals_data)

    # 4. Schedule Blocks
    schedule_data = []
    for sb in db.query(ScheduleBlock).all():
        tp = db.query(Topic).filter(Topic.id == sb.topic_id).first() if sb.topic_id else None
        schedule_data.append({
            "title": sb.title,
            "topic_title": tp.title if tp else None,
            "start_time": sb.start_time,
            "end_time": sb.end_time,
            "is_completed": sb.is_completed,
            "scheduled_date": sb.scheduled_date.isoformat() if sb.scheduled_date else None,
            "notes": sb.notes,
        })
    counts["schedule_blocks"] = len(schedule_data)

    # 5. Study Sessions
    sessions_data = []
    for ss in db.query(StudySession).all():
        tp = db.query(Topic).filter(Topic.id == ss.topic_id).first() if ss.topic_id else None
        sessions_data.append({
            "topic_title": tp.title if tp else None,
            "duration_seconds": ss.duration_seconds,
            "logged_date": ss.logged_date.isoformat() if ss.logged_date else None,
            "notes": ss.notes,
        })
    counts["study_sessions"] = len(sessions_data)

    # 6. Resources
    resources_data = []
    for r in db.query(Resource).all():
        tp = db.query(Topic).filter(Topic.id == r.topic_id).first()
        resources_data.append({
            "topic_title": tp.title if tp else None,
            "title": r.title,
            "url": r.url,
            "resource_type": r.resource_type,
            "notes": r.notes,
            "is_completed": r.is_completed,
        })
    counts["resources"] = len(resources_data)

    # 7. Projects
    projects_data = []
    for p in db.query(Project).all():
        rm = db.query(Roadmap).filter(Roadmap.id == p.roadmap_id).first() if p.roadmap_id else None
        tp = db.query(Topic).filter(Topic.id == p.topic_id).first() if p.topic_id else None
        projects_data.append({
            "roadmap_title": rm.title if rm else None,
            "topic_title": tp.title if tp else None,
            "title": p.title,
            "description": p.description,
            "tech_stack": p.tech_stack,
            "repo_url": p.repo_url,
            "live_demo_url": p.live_demo_url,
            "difficulty": p.difficulty,
            "status": p.status,
            "created_at": p.created_at.isoformat() if p.created_at else None,
        })
    counts["projects"] = len(projects_data)

    # 8. Flashcards
    decks_data = []
    for d in db.query(FlashcardDeck).all():
        tp = db.query(Topic).filter(Topic.id == d.topic_id).first() if d.topic_id else None
        cards_data = [
            {
                "front": c.front,
                "back": c.back,
                "mastery_level": c.mastery_level,
            }
            for c in d.cards
        ]
        decks_data.append({
            "title": d.title,
            "topic_title": tp.title if tp else None,
            "cards": cards_data,
        })
    counts["flashcard_decks"] = len(decks_data)

    # 9. Quizzes
    quizzes_data = []
    for q in db.query(Quiz).all():
        tp = db.query(Topic).filter(Topic.id == q.topic_id).first() if q.topic_id else None
        questions_data = [
            {
                "question_text": qn.question_text,
                "options_json": qn.options_json,
                "correct_option_index": qn.correct_option_index,
                "explanation": qn.explanation,
            }
            for qn in q.questions
        ]
        quizzes_data.append({
            "title": q.title,
            "topic_title": tp.title if tp else None,
            "questions": questions_data,
        })
    counts["quizzes"] = len(quizzes_data)

    # 10. Documents & Chunks
    documents_data = []
    if include_documents:
        for doc in db.query(Document).all():
            rm = db.query(Roadmap).filter(Roadmap.id == doc.roadmap_id).first() if doc.roadmap_id else None
            tp = db.query(Topic).filter(Topic.id == doc.topic_id).first() if doc.topic_id else None
            chunks_data = [
                {
                    "chunk_index": c.chunk_index,
                    "page_number": c.page_number,
                    "content": c.content,
                    "word_count": c.word_count,
                    "embedding_json": c.embedding_json,
                }
                for c in doc.chunks
            ]
            documents_data.append({
                "roadmap_title": rm.title if rm else None,
                "topic_title": tp.title if tp else None,
                "title": doc.title,
                "doc_type": doc.doc_type,
                "file_path": doc.file_path,
                "total_pages": doc.total_pages,
                "total_chunks": doc.total_chunks,
                "chunks": chunks_data,
            })
    counts["documents"] = len(documents_data)

    bundle_dict = {
        "version": "1.0",
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "roadmaps": roadmaps_data,
        "notes": notes_data,
        "goals": goals_data,
        "schedule_blocks": schedule_data,
        "study_sessions": sessions_data,
        "resources": resources_data,
        "projects": projects_data,
        "flashcard_decks": decks_data,
        "quizzes": quizzes_data,
        "documents": documents_data,
    }

    return bundle_dict, counts


# ── Data Ingestion & Merge ───────────────────────────────────────────────────

def _apply_entities(bundle_dict: dict, db: Session, merge_mode: str = "merge") -> Tuple[Dict[str, int], int]:
    """Apply decrypted bundle payload into database with conflict resolution."""
    if merge_mode == "overwrite":
        Base.metadata.drop_all(bind=engine)
        init_db()

    imported_counts: Dict[str, int] = {}
    conflicts_resolved = 0

    topic_cache: Dict[str, Topic] = {}
    roadmap_cache: Dict[str, Roadmap] = {}

    # Seed cache from existing DB
    for rm in db.query(Roadmap).all():
        roadmap_cache[rm.title.strip()] = rm
    for tp in db.query(Topic).all():
        topic_cache[tp.title.strip()] = tp

    # 1. Roadmaps, Phases, Topics, Subtopics
    roadmaps_in = bundle_dict.get("roadmaps", [])
    rm_count = 0
    for rm_data in roadmaps_in:
        rm_title = rm_data["title"].strip()
        rm_obj = roadmap_cache.get(rm_title)
        if not rm_obj:
            rm_obj = Roadmap(
                title=rm_title,
                description=rm_data.get("description"),
            )
            db.add(rm_obj)
            db.flush()
            roadmap_cache[rm_title] = rm_obj
            rm_count += 1
        else:
            conflicts_resolved += 1

        for ph_data in rm_data.get("phases", []):
            ph_title = ph_data["title"].strip()
            ph_obj = db.query(Phase).filter(Phase.roadmap_id == rm_obj.id, Phase.title == ph_title).first()
            if not ph_obj:
                ph_obj = Phase(
                    roadmap_id=rm_obj.id,
                    title=ph_title,
                    order_index=ph_data.get("order_index", 0),
                )
                db.add(ph_obj)
                db.flush()

            for tp_data in ph_data.get("topics", []):
                tp_title = tp_data["title"].strip()
                tp_obj = db.query(Topic).filter(Topic.phase_id == ph_obj.id, Topic.title == tp_title).first()
                if not tp_obj:
                    tp_obj = Topic(
                        phase_id=ph_obj.id,
                        title=tp_title,
                        order_index=tp_data.get("order_index", 0),
                        is_completed=tp_data.get("is_completed", False),
                    )
                    db.add(tp_obj)
                    db.flush()
                else:
                    if tp_data.get("is_completed", False) and not tp_obj.is_completed:
                        tp_obj.is_completed = True
                    conflicts_resolved += 1
                topic_cache[tp_title] = tp_obj

                for st_data in tp_data.get("subtopics", []):
                    st_title = st_data["title"].strip()
                    st_obj = db.query(Subtopic).filter(Subtopic.topic_id == tp_obj.id, Subtopic.title == st_title).first()
                    if not st_obj:
                        st_obj = Subtopic(
                            topic_id=tp_obj.id,
                            title=st_title,
                            order_index=st_data.get("order_index", 0),
                            is_completed=st_data.get("is_completed", False),
                        )
                        db.add(st_obj)
                        db.flush()
                    elif st_data.get("is_completed", False) and not st_obj.is_completed:
                        st_obj.is_completed = True

    imported_counts["roadmaps"] = rm_count

    # 2. Notes
    notes_in = bundle_dict.get("notes", [])
    notes_count = 0
    for n_data in notes_in:
        tp_title = (n_data.get("topic_title") or "").strip()
        tp_obj = topic_cache.get(tp_title)
        if tp_obj:
            n_obj = db.query(Note).filter(Note.topic_id == tp_obj.id).first()
            if not n_obj:
                n_obj = Note(
                    topic_id=tp_obj.id,
                    content=n_data.get("content", ""),
                )
                db.add(n_obj)
                notes_count += 1
            else:
                # Merge: Keep longer note or append diff
                incoming_content = n_data.get("content", "")
                if len(incoming_content) > len(n_obj.content):
                    n_obj.content = incoming_content
                conflicts_resolved += 1
    imported_counts["notes"] = notes_count

    # Goals
    goals_in = bundle_dict.get("goals", [])
    goals_count = 0
    for g_data in goals_in:
        rm_title = (g_data.get("roadmap_title") or "").strip()
        rm_obj = roadmap_cache.get(rm_title)
        if rm_obj and g_data.get("target_date"):
            t_date = datetime.fromisoformat(g_data["target_date"]).date()
            existing_g = db.query(Goal).filter(Goal.roadmap_id == rm_obj.id).first()
            if not existing_g:
                db.add(Goal(roadmap_id=rm_obj.id, target_date=t_date))
                goals_count += 1
            else:
                existing_g.target_date = t_date
    imported_counts["goals"] = goals_count

    # Schedule Blocks
    sb_in = bundle_dict.get("schedule_blocks", [])
    sb_count = 0
    for sb_data in sb_in:
        tp_title = (sb_data.get("topic_title") or "").strip()
        tp_obj = topic_cache.get(tp_title)
        if sb_data.get("scheduled_date") and sb_data.get("start_time") and sb_data.get("end_time"):
            s_date = datetime.fromisoformat(sb_data["scheduled_date"]).date()
            new_sb = ScheduleBlock(
                scheduled_date=s_date,
                start_time=sb_data["start_time"],
                end_time=sb_data["end_time"],
                title=sb_data.get("title", "Study Block"),
                topic_id=tp_obj.id if tp_obj else None,
                is_completed=sb_data.get("is_completed", False),
                notes=sb_data.get("notes"),
            )
            db.add(new_sb)
            sb_count += 1
    imported_counts["schedule_blocks"] = sb_count

    # Study Sessions
    ss_in = bundle_dict.get("study_sessions", [])
    ss_count = 0
    for ss_data in ss_in:
        tp_title = (ss_data.get("topic_title") or "").strip()
        tp_obj = topic_cache.get(tp_title)
        if tp_obj and ss_data.get("duration_seconds"):
            l_date = datetime.fromisoformat(ss_data["logged_date"]).date() if ss_data.get("logged_date") else None
            new_ss = StudySession(
                topic_id=tp_obj.id,
                duration_seconds=ss_data["duration_seconds"],
                logged_date=l_date,
                notes=ss_data.get("notes"),
            )
            db.add(new_ss)
            ss_count += 1
    imported_counts["study_sessions"] = ss_count

    # 3. Resources
    res_in = bundle_dict.get("resources", [])
    res_count = 0
    for r_data in res_in:
        tp_title = (r_data.get("topic_title") or "").strip()
        tp_obj = topic_cache.get(tp_title)
        if tp_obj:
            existing = db.query(Resource).filter(
                Resource.topic_id == tp_obj.id,
                Resource.title == r_data["title"].strip(),
            ).first()
            if not existing:
                new_r = Resource(
                    topic_id=tp_obj.id,
                    title=r_data["title"].strip(),
                    url=r_data.get("url"),
                    resource_type=r_data.get("resource_type", "book"),
                    notes=r_data.get("notes"),
                    is_completed=r_data.get("is_completed", False),
                )
                db.add(new_r)
                res_count += 1
    imported_counts["resources"] = res_count

    # 4. Projects
    projects_in = bundle_dict.get("projects", [])
    proj_count = 0
    for p_data in projects_in:
        rm_title = (p_data.get("roadmap_title") or "").strip()
        rm_obj = roadmap_cache.get(rm_title)
        tp_title = (p_data.get("topic_title") or "").strip()
        tp_obj = topic_cache.get(tp_title)

        existing = db.query(Project).filter(Project.title == p_data["title"].strip()).first()
        if not existing:
            new_p = Project(
                roadmap_id=rm_obj.id if rm_obj else None,
                topic_id=tp_obj.id if tp_obj else None,
                title=p_data["title"].strip(),
                description=p_data.get("description"),
                tech_stack=p_data.get("tech_stack"),
                repo_url=p_data.get("repo_url"),
                live_demo_url=p_data.get("live_demo_url"),
                difficulty=p_data.get("difficulty", "medium"),
                status=p_data.get("status", "in_progress"),
            )
            db.add(new_p)
            proj_count += 1
    imported_counts["projects"] = proj_count

    # 5. Flashcards
    decks_in = bundle_dict.get("flashcard_decks", [])
    decks_count = 0
    for d_data in decks_in:
        tp_title = (d_data.get("topic_title") or "").strip()
        tp_obj = topic_cache.get(tp_title)
        d_obj = db.query(FlashcardDeck).filter(FlashcardDeck.title == d_data["title"].strip()).first()
        if not d_obj:
            d_obj = FlashcardDeck(
                title=d_data["title"].strip(),
                topic_id=tp_obj.id if tp_obj else None,
            )
            db.add(d_obj)
            db.flush()
            decks_count += 1

            for c_data in d_data.get("cards", []):
                card = Flashcard(
                    deck_id=d_obj.id,
                    front=c_data["front"],
                    back=c_data["back"],
                    mastery_level=c_data.get("mastery_level", 0),
                )
                db.add(card)
    imported_counts["flashcards"] = decks_count

    # 6. Documents
    docs_in = bundle_dict.get("documents", [])
    docs_count = 0
    for doc_data in docs_in:
        rm_title = (doc_data.get("roadmap_title") or "").strip()
        rm_obj = roadmap_cache.get(rm_title)
        tp_title = (doc_data.get("topic_title") or "").strip()
        tp_obj = topic_cache.get(tp_title)

        existing = db.query(Document).filter(Document.title == doc_data["title"].strip()).first()
        if not existing:
            new_doc = Document(
                roadmap_id=rm_obj.id if rm_obj else None,
                topic_id=tp_obj.id if tp_obj else None,
                title=doc_data["title"].strip(),
                doc_type=doc_data.get("doc_type", "textbook"),
                file_path=doc_data.get("file_path"),
                total_pages=doc_data.get("total_pages", 1),
                total_chunks=len(doc_data.get("chunks", [])),
            )
            db.add(new_doc)
            db.flush()
            docs_count += 1

            for c_data in doc_data.get("chunks", []):
                chunk = DocumentChunk(
                    document_id=new_doc.id,
                    chunk_index=c_data["chunk_index"],
                    page_number=c_data["page_number"],
                    content=c_data["content"],
                    word_count=c_data["word_count"],
                    embedding_json=c_data.get("embedding_json"),
                )
                db.add(chunk)
    imported_counts["documents"] = docs_count

    db.commit()
    return imported_counts, conflicts_resolved


# ── Router Endpoints ─────────────────────────────────────────────────────────

@router.get("/status", response_model=SyncStatusResponse)
def get_sync_status(db: Session = Depends(get_db)):
    """Retrieve local device sync status, total entity counters, and database fingerprint."""
    device = _get_or_create_device(db)

    total_roadmaps = db.query(Roadmap).count()
    total_phases = db.query(Phase).count()
    total_topics = db.query(Topic).count()
    total_notes = db.query(Note).count()
    total_goals = db.query(Goal).count()
    total_flashcards = db.query(Flashcard).count()
    total_quizzes = db.query(Quiz).count()
    total_documents = db.query(Document).count()

    # Compute lightweight database revision fingerprint
    fp_raw = f"{total_roadmaps}:{total_topics}:{total_notes}:{total_flashcards}:{total_documents}"
    revision = hashlib.sha256(fp_raw.encode("utf-8")).hexdigest()[:12]

    return SyncStatusResponse(
        device_id=device.device_id,
        device_name=device.device_name,
        created_at=device.created_at,
        last_synced_at=device.last_synced_at,
        sync_count=device.sync_count,
        total_roadmaps=total_roadmaps,
        total_phases=total_phases,
        total_topics=total_topics,
        total_notes=total_notes,
        total_goals=total_goals,
        total_flashcards=total_flashcards,
        total_quizzes=total_quizzes,
        total_documents=total_documents,
        database_revision=revision,
    )


@router.post("/device/register", response_model=SyncStatusResponse)
def register_device(req: DeviceRegisterRequest, db: Session = Depends(get_db)):
    """Update or register the friendly name of this device."""
    device = _get_or_create_device(db, preferred_name=req.device_name.strip())
    return get_sync_status(db)


@router.post("/export", response_model=SyncExportResponse)
def export_sync_bundle(req: SyncExportRequest, db: Session = Depends(get_db)):
    """
    Export all local StudyOS entities into an authenticated AES-256-GCM encrypted sync payload.
    Uses PBKDF2 with 100,000 iterations to derive key from passphrase.
    """
    device = _get_or_create_device(db, preferred_name=req.device_name)
    bundle_dict, counts = _collect_all_entities(db, include_documents=req.include_documents)

    salt_hex, nonce_hex, ciphertext_b64, checksum = _encrypt_payload(bundle_dict, req.passphrase)

    # Record sync activity
    now = datetime.now(timezone.utc)
    device.last_synced_at = now
    device.sync_count += 1
    db.commit()

    return SyncExportResponse(
        bundle_version="1.0",
        device_id=device.device_id,
        device_name=device.device_name,
        exported_at=now,
        salt_hex=salt_hex,
        nonce_hex=nonce_hex,
        ciphertext_base64=ciphertext_b64,
        checksum_sha256=checksum,
        entity_counts=counts,
    )


@router.post("/import", response_model=SyncImportResponse)
def import_sync_bundle(req: SyncImportRequest, db: Session = Depends(get_db)):
    """
    Decrypt and ingest an AES-256-GCM encrypted sync bundle.
    Supports 'merge' (safe upsert) and 'overwrite' modes.
    """
    # Decrypt and verify payload
    bundle_dict = _decrypt_payload(
        ciphertext_b64=req.ciphertext_base64,
        passphrase=req.passphrase,
        salt_hex=req.salt_hex,
        nonce_hex=req.nonce_hex,
        checksum_sha256=req.checksum_sha256,
    )

    imported_counts, conflicts = _apply_entities(bundle_dict, db, merge_mode=req.merge_mode)

    device = _get_or_create_device(db)
    now = datetime.now(timezone.utc)
    device.last_synced_at = now
    device.sync_count += 1
    db.commit()

    return SyncImportResponse(
        success=True,
        message=f"Sync bundle successfully applied ({req.merge_mode} mode).",
        entities_imported=imported_counts,
        conflicts_resolved=conflicts,
        imported_at=now,
    )


@router.post("/backup/export")
def export_encrypted_backup(req: SyncExportRequest, db: Session = Depends(get_db)):
    """Export standalone encrypted database snapshot."""
    return export_sync_bundle(req, db)


@router.post("/backup/restore", response_model=SyncImportResponse)
def restore_encrypted_backup(req: SyncImportRequest, db: Session = Depends(get_db)):
    """Restore from encrypted standalone backup snapshot (defaults to overwrite mode)."""
    req.merge_mode = "overwrite"
    return import_sync_bundle(req, db)
