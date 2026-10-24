"""
StudyOS Backend — FastAPI Application Entry Point
Run: uvicorn main:app --host 127.0.0.1 --port 8000
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routers import roadmaps, phases, topics, subtopics, notes, goals, dashboard, system, schedule, study_sessions, calendar, analytics, resources, projects, ai_planner, study_recall, note_ai


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
app.include_router(study_sessions.router)
app.include_router(calendar.router)
app.include_router(analytics.router)
app.include_router(resources.router)
app.include_router(projects.router)
app.include_router(ai_planner.router)
app.include_router(study_recall.router)
app.include_router(note_ai.router)


@app.get("/health", tags=["system"])
def health_check():
    """Health check endpoint — Flutter pings this to confirm the backend is ready."""
    return {"status": "ok", "version": "1.0.0"}


# Automatically add alternate routes (with and without trailing slashes)
# to eliminate 307 Temporary Redirect responses for API clients like Dio.
_existing_path_methods = {
    (r.path, m)
    for r in app.routes
    if hasattr(r, "path") and hasattr(r, "methods")
    for m in r.methods
}
for _route in list(app.routes):
    if hasattr(_route, "path") and hasattr(_route, "endpoint") and hasattr(_route, "methods"):
        _alt = _route.path.rstrip("/") if (_route.path.endswith("/") and len(_route.path) > 1) else f"{_route.path}/"
        _needed_methods = [m for m in _route.methods if (_alt, m) not in _existing_path_methods]
        if _needed_methods and not any(_alt.startswith(prefix) for prefix in ("/docs", "/openapi", "/redoc")):
            for m in _needed_methods:
                _existing_path_methods.add((_alt, m))
            app.add_api_route(
                _alt,
                _route.endpoint,
                methods=_needed_methods,
                include_in_schema=False,
                response_model=getattr(_route, "response_model", None),
                status_code=getattr(_route, "status_code", None),
                dependencies=getattr(_route, "dependencies", None),
            )

