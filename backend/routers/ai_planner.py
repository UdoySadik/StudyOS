"""FastAPI router for Offline LLM Study Planner with Ollama integration and built-in offline engine."""

import json
import urllib.request
import urllib.error
from datetime import datetime, timezone
from typing import List, Optional, Tuple, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models.study_plan import AIStudyPlan
from models.roadmap import Roadmap
from models.phase import Phase
from models.topic import Topic
from models.project import Project
from schemas.ai_planner import (
    OllamaStatusResponse,
    StudyPlanGenerateRequest,
    StudyPlanResponse,
    ImportRoadmapResponse,
)

router = APIRouter(prefix="/ai", tags=["ai_planner"])

OLLAMA_DEFAULT_URL = "http://127.0.0.1:11434"


def check_ollama_connection(endpoint: str = OLLAMA_DEFAULT_URL) -> Tuple[bool, List[str]]:
    """Check if local Ollama daemon is reachable and query installed models."""
    try:
        url = f"{endpoint.rstrip('/')}/api/tags"
        req = urllib.request.Request(url, headers={"User-Agent": "StudyOS/1.0"})
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                models = [m.get("name", "") for m in data.get("models", []) if m.get("name")]
                return True, models
    except Exception:
        pass
    return False, []


def call_ollama_generate(
    prompt: str,
    model: str,
    endpoint: str = OLLAMA_DEFAULT_URL,
    timeout: float = 30.0,
) -> Optional[str]:
    """Call Ollama /api/generate endpoint."""
    try:
        url = f"{endpoint.rstrip('/')}/api/generate"
        payload = json.dumps({
            "model": model,
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.4},
        }).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json", "User-Agent": "StudyOS/1.0"},
        )
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            if resp.status == 200:
                result = json.loads(resp.read().decode("utf-8"))
                return result.get("response", "")
    except Exception:
        pass
    return None


def generate_heuristic_study_plan(
    subject: str,
    proficiency: str,
    hours_per_week: int,
    target_weeks: int,
    focus_area: Optional[str] = None,
    custom_instructions: Optional[str] = None,
) -> Tuple[str, Dict[str, Any]]:
    """Generate a high-quality deterministic study syllabus when Ollama is offline."""
    title = f"{subject.strip()} — {target_weeks}-Week Mastery Plan"
    focus = focus_area or "Core Fundamentals & Practical Projects"

    num_phases = max(2, min(target_weeks, 4))
    weeks_per_phase = max(1, target_weeks // num_phases)

    phases_data = []

    # Phase templates based on domain heuristics
    phase_blueprints = [
        {
            "suffix": "Foundations, Architecture & Core Primitives",
            "topics": [
                f"{subject}: Core Concepts & Mental Model",
                "Tooling, Ecosystem & Development Environment",
                "Fundamental Syntax, Typings & Idiomatic Patterns",
                "Memory, State & Runtime Execution Model",
            ],
            "project": f"{subject} CLI Starter / Prototype Engine",
            "diff": "beginner",
        },
        {
            "suffix": "Deep Dive, Data Structures & Concurrency",
            "topics": [
                "Advanced Data Structures & Algorithms",
                "Concurrency, Async I/O & Event Loops",
                "Error Handling Strategies & Defensive Programming",
                "Standard Library & Network Communication",
            ],
            "project": f"{subject} Concurrent Service or Pipeline",
            "diff": "medium",
        },
        {
            "suffix": "Production Engineering, System Design & Optimization",
            "topics": [
                "Performance Profiling, Benchmarking & Memory Optimization",
                "Distributed Patterns, Scalability & Fault Tolerance",
                "Security Hardening & Safe Resource Management",
                "Automated Testing, CI/CD & Production Deployment",
            ],
            "project": f"{subject} High-Performance Production System",
            "diff": "advanced",
        },
        {
            "suffix": "Capstone Implementation & Portfolio Verification",
            "topics": [
                "End-to-End System Integration & Stress Testing",
                "Documentation, API Schemas & Open Source Hygiene",
                "Code Review, Refactoring & Static Analysis",
                "Release Packaging & Benchmarking Report",
            ],
            "project": f"{subject} Full Portfolio Capstone Showcase",
            "diff": "advanced",
        },
    ]

    md_lines = [
        f"# {title}",
        "",
        f"> **Subject:** {subject}  ",
        f"> **Proficiency Level:** {proficiency.capitalize()}  ",
        f"> **Commitment:** {hours_per_week} hours/week × {target_weeks} weeks ({hours_per_week * target_weeks} total study hours)  ",
        f"> **Primary Focus:** {focus}  ",
        "",
        "---",
        "",
        "## Executive Summary & Learning Strategy",
        f"This offline study curriculum is tailored for an intensive **{proficiency}** track in **{subject}**. "
        f"With a dedicated **{hours_per_week} hours per week**, the plan balances theoretical foundations with hands-on "
        "practice projects and source-code implementations.",
        "",
        "### Weekly Study Rhythm",
        f"- **Theory & Concept Mapping:** ~{int(hours_per_week * 0.35)} hours/week (Reading official documentation, RFCs, and books)",
        f"- **Hands-on Implementation:** ~{int(hours_per_week * 0.45)} hours/week (Writing clean code, debugging, building projects)",
        f"- **Review, Notes & Self-Assessment:** ~{int(hours_per_week * 0.20)} hours/week (Synthesizing notes and code refactoring)",
        "",
        "---",
        "",
        "## Phased Syllabus & Topic Breakdown",
        "",
    ]

    for i in range(num_phases):
        bp = phase_blueprints[i % len(phase_blueprints)]
        start_w = i * weeks_per_phase + 1
        end_w = target_weeks if i == num_phases - 1 else (i + 1) * weeks_per_phase
        phase_title = f"Phase {i + 1} (Weeks {start_w}–{end_w}): {bp['suffix']}"

        md_lines.append(f"### {phase_title}")
        md_lines.append(f"**Target Commitment:** ~{hours_per_week * (end_w - start_w + 1)} hours")
        md_lines.append("")
        md_lines.append("**Topics to Master:**")
        for tp in bp["topics"]:
            md_lines.append(f"- [ ] **{tp}**")
        md_lines.append("")
        md_lines.append(f"**Practice Project Milestone:** `{bp['project']}` ({bp['diff'].capitalize()})")
        md_lines.append("")

        phases_data.append({
            "title": phase_title,
            "order_index": i + 1,
            "topics": bp["topics"],
            "project": {
                "title": bp["project"],
                "difficulty": bp["diff"],
                "tech_stack": subject,
            },
        })

    if custom_instructions:
        md_lines.extend([
            "---",
            "",
            "## Specific Constraints & User Goals",
            f"{custom_instructions.strip()}",
            "",
        ])

    md_lines.extend([
        "---",
        "",
        "## Roadmap Action Step",
        "Click the **\"Import as Roadmap\"** button above to automatically convert these phases and topics "
        "into your active StudyOS Roadmap with linked practice projects.",
    ])

    structured_data = {
        "title": title,
        "subject": subject,
        "phases": phases_data,
    }

    return "\n".join(md_lines), structured_data


def _to_response(plan: AIStudyPlan) -> StudyPlanResponse:
    structured = None
    if plan.structured_json:
        try:
            structured = json.loads(plan.structured_json)
        except Exception:
            structured = None

    return StudyPlanResponse(
        id=plan.id,
        title=plan.title,
        subject=plan.subject,
        proficiency=plan.proficiency,
        hours_per_week=plan.hours_per_week,
        target_weeks=plan.target_weeks,
        model_used=plan.model_used,
        plan_markdown=plan.plan_markdown,
        structured_data=structured,
        roadmap_id=plan.roadmap_id,
        roadmap_title=plan.roadmap.title if plan.roadmap else None,
        created_at=plan.created_at,
    )


@router.get("/ollama/status", response_model=OllamaStatusResponse)
def get_ollama_status():
    """Check whether local Ollama server is active and list available models."""
    connected, models = check_ollama_connection()
    return OllamaStatusResponse(
        connected=connected,
        endpoint=OLLAMA_DEFAULT_URL,
        models=models,
    )


@router.get("/plans/", response_model=List[StudyPlanResponse])
def list_study_plans(db: Session = Depends(get_db)):
    """Retrieve all saved AI study plans."""
    plans = db.query(AIStudyPlan).order_by(AIStudyPlan.created_at.desc()).all()
    return [_to_response(p) for p in plans]


@router.get("/plans/{plan_id}", response_model=StudyPlanResponse)
def get_study_plan(plan_id: int, db: Session = Depends(get_db)):
    """Get single AI study plan by ID."""
    plan = db.get(AIStudyPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Study plan not found")
    return _to_response(plan)


@router.post("/plans/generate", response_model=StudyPlanResponse, status_code=status.HTTP_201_CREATED)
def generate_study_plan(payload: StudyPlanGenerateRequest, db: Session = Depends(get_db)):
    """Generate and persist a study plan using local Ollama if available, else built-in engine."""
    subject = payload.subject.strip()
    if not subject:
        raise HTTPException(status_code=400, detail="Subject cannot be empty")

    connected, models = check_ollama_connection()
    model_to_use = None
    plan_markdown = None
    structured_data = None

    if connected and models:
        # User specified model or default to first model
        if payload.model and payload.model in models:
            model_to_use = payload.model
        elif not payload.model:
            model_to_use = models[0]

        if model_to_use:
            prompt = (
                f"You are an expert curriculum architect. Create a structured {payload.target_weeks}-week "
                f"study plan for {subject} at {payload.proficiency} level with {payload.hours_per_week} hours/week commitment.\n"
                f"Focus: {payload.focus_area or 'Core concepts & practical projects'}.\n"
                f"Additional instructions: {payload.custom_instructions or 'None'}.\n"
                f"Format the output cleanly in Markdown with phases, topics, and practical projects."
            )
            response_text = call_ollama_generate(prompt, model_to_use)
            if response_text and len(response_text.strip()) > 100:
                plan_markdown = response_text.strip()
                # Also generate structured metadata for roadmap conversion
                _, structured_data = generate_heuristic_study_plan(
                    subject=subject,
                    proficiency=payload.proficiency,
                    hours_per_week=payload.hours_per_week,
                    target_weeks=payload.target_weeks,
                    focus_area=payload.focus_area,
                    custom_instructions=payload.custom_instructions,
                )

    # Fallback if Ollama not running, model not found, or call failed
    if not plan_markdown:
        model_to_use = "builtin-offline"
        plan_markdown, structured_data = generate_heuristic_study_plan(
            subject=subject,
            proficiency=payload.proficiency,
            hours_per_week=payload.hours_per_week,
            target_weeks=payload.target_weeks,
            focus_area=payload.focus_area,
            custom_instructions=payload.custom_instructions,
        )

    title = f"{subject} — {payload.target_weeks}W Plan"
    plan = AIStudyPlan(
        title=title,
        subject=subject,
        proficiency=payload.proficiency,
        hours_per_week=payload.hours_per_week,
        target_weeks=payload.target_weeks,
        model_used=model_to_use or "builtin-offline",
        plan_markdown=plan_markdown,
        structured_json=json.dumps(structured_data) if structured_data else None,
        roadmap_id=payload.roadmap_id,
    )
    db.add(plan)
    db.commit()
    db.refresh(plan)
    return _to_response(plan)


@router.delete("/plans/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_study_plan(plan_id: int, db: Session = Depends(get_db)):
    """Delete a saved study plan."""
    plan = db.get(AIStudyPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Study plan not found")
    db.delete(plan)
    db.commit()


@router.post("/plans/{plan_id}/import-roadmap", response_model=ImportRoadmapResponse, status_code=status.HTTP_201_CREATED)
def import_plan_as_roadmap(plan_id: int, db: Session = Depends(get_db)):
    """Convert a generated study plan into an active Roadmap with Phases, Topics, and Projects."""
    plan = db.get(AIStudyPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Study plan not found")

    structured = None
    if plan.structured_json:
        try:
            structured = json.loads(plan.structured_json)
        except Exception:
            pass

    if not structured or not structured.get("phases"):
        # Regenerate structured data if missing
        _, structured = generate_heuristic_study_plan(
            subject=plan.subject,
            proficiency=plan.proficiency,
            hours_per_week=plan.hours_per_week,
            target_weeks=plan.target_weeks,
        )

    # 1. Create Roadmap
    roadmap = Roadmap(
        title=f"{plan.subject} (AI Syllabus)",
        description=f"Generated via StudyOS AI Planner ({plan.model_used}) — {plan.target_weeks} weeks, {plan.hours_per_week}h/week",
    )
    db.add(roadmap)
    db.commit()
    db.refresh(roadmap)

    # 2. Create Phases, Topics, and Projects
    phases_created = 0
    topics_created = 0

    for idx, p_data in enumerate(structured.get("phases", [])):
        phase = Phase(
            roadmap_id=roadmap.id,
            title=p_data.get("title", f"Phase {idx + 1}"),
            order_index=idx + 1,
        )
        db.add(phase)
        db.commit()
        db.refresh(phase)
        phases_created += 1

        first_topic_id = None
        for t_idx, topic_title in enumerate(p_data.get("topics", [])):
            topic = Topic(
                phase_id=phase.id,
                title=topic_title,
                order_index=t_idx + 1,
                is_completed=False,
            )
            db.add(topic)
            db.commit()
            db.refresh(topic)
            topics_created += 1
            if first_topic_id is None:
                first_topic_id = topic.id

        # 3. Create practice project linked to this roadmap
        proj_data = p_data.get("project")
        if proj_data:
            project = Project(
                roadmap_id=roadmap.id,
                topic_id=first_topic_id,
                title=proj_data.get("title", f"Project {idx + 1}"),
                difficulty=proj_data.get("difficulty", "medium"),
                tech_stack=proj_data.get("tech_stack", plan.subject),
                status="not_started",
                description=f"Practice project milestone for {phase.title}",
            )
            db.add(project)
            db.commit()

    # Link plan to created roadmap
    plan.roadmap_id = roadmap.id
    db.commit()

    return ImportRoadmapResponse(
        plan_id=plan.id,
        roadmap_id=roadmap.id,
        roadmap_title=roadmap.title,
        phases_created=phases_created,
        topics_created=topics_created,
    )
