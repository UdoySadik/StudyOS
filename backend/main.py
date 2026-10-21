"""
StudyOS Backend — FastAPI Application Entry Point
Run: uvicorn main:app --host 127.0.0.1 --port 8000
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routers import roadmaps, phases, topics, subtopics, notes, goals, dashboard, system, schedule


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize database tables on application startup."""
    init_db()
    yield


app = FastAPI(
    title="StudyOS API",
    description="Local backend for the StudyOS desktop learning application.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
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
app.include_router(system.router)
app.include_router(schedule.router)


@app.get("/health", tags=["system"])
def health_check():
    """Health check endpoint — Flutter pings this to confirm the backend is ready."""
    return {"status": "ok", "version": "1.0.0"}
