"""Pydantic schemas for Offline LLM Study Planner (Ollama Integration)."""

from datetime import datetime
from typing import List, Optional, Any, Dict
from pydantic import BaseModel, ConfigDict


class OllamaStatusResponse(BaseModel):
    connected: bool
    endpoint: str
    models: List[str] = []


class StudyPlanGenerateRequest(BaseModel):
    subject: str
    proficiency: str = "intermediate"  # beginner, intermediate, advanced
    hours_per_week: int = 10
    target_weeks: int = 4
    focus_area: Optional[str] = "Practical Projects & Core Concepts"
    custom_instructions: Optional[str] = None
    model: Optional[str] = None  # None or empty = auto or heuristic
    roadmap_id: Optional[int] = None


class StudyPlanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    subject: str
    proficiency: str
    hours_per_week: int
    target_weeks: int
    model_used: str
    plan_markdown: str
    structured_data: Optional[Dict[str, Any]] = None
    roadmap_id: Optional[int] = None
    roadmap_title: Optional[str] = None
    created_at: datetime


class ImportRoadmapResponse(BaseModel):
    plan_id: int
    roadmap_id: int
    roadmap_title: str
    phases_created: int
    topics_created: int
