"""
StudyOS Backend — FastAPI Application Entry Point
Run: uvicorn main:app --host 127.0.0.1 --port 8000
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routers import roadmaps, phases, topics, subtopics, notes, goals, dashboard

app = FastAPI(
    title="StudyOS API",
    description="Local backend for the StudyOS desktop learning application.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Allow Flutter app on localhost to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register all routers
app.include_router(roadmaps.router)
app.include_router(phases.router)
app.include_router(topics.router)
app.include_router(subtopics.router)
app.include_router(notes.router)
app.include_router(goals.router)
app.include_router(dashboard.router)


@app.on_event("startup")
def on_startup():
    """Initialize database tables on first run."""
    init_db()


@app.get("/health", tags=["system"])
def health_check():
    """Health check endpoint — Flutter pings this to confirm the backend is ready."""
    return {"status": "ok", "version": "1.0.0"}
