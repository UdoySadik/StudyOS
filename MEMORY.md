# StudyOS — Engineering Handoff Memory (`MEMORY.md`)

> **Document Version:** 1.0.0  
> **Classification:** Authoritative Technical Knowledge & AI Handoff  
> **Last Verified:** October 2026 (Audit Completed)  
> **Status:** Active / Frozen for V1.0 Stabilization

---

## 1. Project Identity

- **Project Name:** StudyOS
- **Repository:** `https://github.com/UdoySadik/StudyOS.git`
- **Identity:** Local-first, developer-centric desktop operating system and study management platform.

---

## 2. Product Purpose

StudyOS enables self-directed learners, computer science students, and engineers to systematically organize extensive curricula into hierarchical roadmaps, monitor overall and phase-level completion, set dynamic completion deadlines with auto-calculated study pacing, and take topic-linked Markdown notes that auto-save locally.

---

## 3. Current Release & Scope

- **Current Release:** Version 1.0 (MVP)
- **Scope Status:** **FROZEN.** No new functional features may be added to V1.0.
- **Focus:** Stabilization, edge-case testing, UI polish, deprecation elimination, and regression testing.

---

## 4. Verified Technology Stack

Any future agent or developer must respect this exact stack. Do NOT attempt to replace or rewrite these foundational technologies:

| Layer | Framework / Library | Exact Version | Role |
|---|---|---|---|
| **Frontend Shell** | Flutter Desktop (Dart) | 3.44.0 (Dart 3.12.0) | Cross-platform desktop presentation |
| **State Management**| Flutter Riverpod | 2.6.1 | AsyncNotifier / reactive caching |
| **Routing** | GoRouter | 14.8.1 | Declarative URL-like routing & ShellRoute |
| **HTTP Client** | Dio | 5.10.0 | REST API communication |
| **Markdown** | flutter_markdown | 0.7.7+1 | Note preview renderer |
| **Backend API** | Python FastAPI | 0.115.5 | Local business logic microservice |
| **ASGI Server** | Uvicorn (standard) | 0.32.1 | HTTP loopback host on `127.0.0.1:8000` |
| **ORM / Schema** | SQLAlchemy & Pydantic V2| 2.0.36 / 2.10.3 | Relational mapping & request validation |
| **Database** | Embedded SQLite | 3.x | WAL-mode persistent relational storage |

---

## 5. Core Architectural Facts

1. **Split-Process IPC Architecture:**
   - The Flutter desktop application communicates with the local Python FastAPI service via HTTP REST over loopback TCP (`http://127.0.0.1:8000`).
   - `frontend/lib/main.dart` includes an automated supervisor (`Process.start`) that starts Uvicorn if the backend is not already running on port 8000.
2. **Authoritative Hierarchy:**
   - Hierarchy is strictly 4 levels: $\text{Roadmap} \longrightarrow \text{Phase} \longrightarrow \text{Topic} \longrightarrow \text{Subtopic}$.
   - Arbitrary or infinite recursive nesting is explicitly unsupported.
3. **Dynamic Calculations (Zero Redundant Columns):**
   - The database does **not** store precomputed percentages, progress counters, or days remaining in table columns.
   - All progress statistics and today's suggestions are calculated on-the-fly by pure functions in `backend/utils/progress_calculator.py`.

---

## 6. Database & Persistence Facts

- **Database File Location:** `data/studyos.db` (created automatically relative to project root).
- **WAL Mode & Foreign Keys:** Every SQLite connection executes:
  ```python
  PRAGMA foreign_keys = ON;
  PRAGMA journal_mode = WAL;
  ```
- **Cascade Deletion:** All child tables (`phases`, `topics`, `subtopics`, `notes`, `goals`) enforce `ON DELETE CASCADE` at both the SQLite foreign key level and the SQLAlchemy ORM level (`cascade="all, delete-orphan"`).
  *Rule:* Deleting a Roadmap cleanly wipes all associated phases, topics, subtopics, notes, and goals without leaving orphan rows.
- **Git Tracking:** The `data/` directory contains only `.gitkeep`. Database files (`*.db`, `*.db-wal`, `*.db-shm`) are strictly `.gitignore`d to prevent committing user data.

---

## 7. Coding & Naming Conventions

### Python / Backend
- **Module Structure:** `models/` for ORM models, `schemas/` for Pydantic models, `routers/` for FastAPI routes, `utils/` for pure helper logic.
- **Style:** PEP 8 compliance, snake_case for functions and variables, PascalCase for classes.
- **Endpoints:** RESTful nouns with trailing slashes where appropriate (`/roadmaps/`, `/phases/`, `/topics/`, `/notes/`, `/goals/`, `/dashboard/{roadmap_id}`).
- **Dependency Injection:** Database sessions are injected via `db: Session = Depends(get_db)`.

### Dart / Flutter
- **Folder Structure:** Feature-first directory layout under `lib/features/<feature_name>/{application,domain,presentation}/`.
- **State Management:** Riverpod 2.x `AsyncNotifier` and `FamilyAsyncNotifier` classes for mutative state; `FutureProvider` for read-only data.
- **Providers:** Always name providers with the suffix `Provider` (e.g. `roadmapNotifierProvider`, `dashboardProvider`).
- **Imports:** Relative package imports within features; shared utilities from `../../../shared/` or `../../../core/`.

---

## 8. Established Design Conventions

- **Dark Theme Canvas:** Default `#0F0F13`, Cards `#22222E`, Borders `#2E2E3E`.
- **Primary Accent:** Indigo `#6366F1`, Cyan `#06B6D4`.
- **Typography:** Inter (via Google Fonts) for UI, Courier for Markdown notes editor.
- **Debounced Input:** All text inputs tied to backend network synchronization must enforce a **500ms debounce**.

---

## 9. Architectural Decisions Made & Frozen

| Decision ID | Context / Problem | Decision | Rationale |
|---|---|---|---|
| **ADR-001** | Cross-platform desktop runtime | Flutter Desktop over Electron | Flutter compiles to native C++ Win32 binary, consuming <100MB RAM compared to Chromium overhead. |
| **ADR-002** | Local Backend Engine | FastAPI over native Dart SQLite | Decouples business logic, enables future Python AI integrations (RAG, PyTorch, LangChain), and supports rich ecosystem. |
| **ADR-003** | Progress Storage | Pure Dynamic Calculation over Stored Counts | Prevents data inconsistency and stale counters when topics are marked/unmarked or deleted. |
| **ADR-004** | Notes Association | Strict 1-to-1 with Topics (`unique=True`) | Direct cognitive link between a study topic and its notes; simplifies note explorer navigation. |
| **ADR-005** | Notes Autosave | 500ms Debounced PUT Upsert | Prevents lost work without flooding the local SQLite database with write operations per keystroke. |

---

## 10. Explicitly Rejected Approaches & Scope Constraints

- ❌ **No Cloud Authentication in V1.0:** No Firebase, Supabase, or remote user accounts. StudyOS is strictly single-user local-first.
- ❌ **No Infinite Tree Nesting:** Deep arbitrary nesting leads to confusing UI in desktop list tiles. Strict Roadmap → Phase → Topic → Subtopic is enforced.
- ❌ **No Heavy Rich-Text WYSIWYG:** Avoided fragile Quill/Draft.js style HTML editors in favor of standard Markdown with dual Edit/Preview mode.
- ❌ **No Direct Frontend-to-SQLite DB Connections:** Frontend never touches `studyos.db` directly; all queries flow through FastAPI.

---

## 11. Important Known Bugs & Technical Debt (Audit Findings)

1. **Theme Switch Inactivity (`settings_page.dart:89`):** The Dark Theme switch toggle has no backing Riverpod provider or persistent state handler.
2. **Database Clean Reset Inactivity (`settings_page.dart:163`):** The "Reset All" confirmation dialog closes without calling any database deletion endpoint.
3. **Dashboard Empty State Navigation (`dashboard_page.dart:23`):** The "New Roadmap" button inside the dashboard empty state contains an empty callback instead of navigating to `/roadmap`.
4. **Deprecated Color API Warnings:** Flutter 3.27+ flags multiple uses of `.withOpacity(...)` in `app_shell.dart`, `dashboard_page.dart`, `goals_page.dart`, `roadmap_page.dart`, and `settings_page.dart`. These should be replaced with `.withValues(...)`.
5. **Backend Automated Router Test Suite:** `backend/test_api.py` exists as a manual script, but standard automated `pytest` test suites covering HTTP router error codes are not yet in `backend/tests/`.

---

## 12. Current Development Status

- **Architecture:** Complete and verified.
- **Backend Core:** Complete and verified (FastAPI + SQLAlchemy + SQLite WAL).
- **Frontend Core:** Complete and verified (5 screens, Riverpod notifiers, GoRouter navigation).
- **Build Status:** Compiles cleanly to Windows x64 executable (`flutter run -d windows`).
- **Tests:** Widget smoke tests passing (100%); pure math and cascade tests verified.
- **Next Phase:** **V1.0 Stabilization** (resolving the 5 items in Section 11).

---

## 13. Invariant Rules for Future AI Coding Sessions

When working on this repository, you **MUST** follow these rules:

1. **Do Not Rebuild the Application:** Never propose rewriting the app in a different framework (e.g. Next.js, Electron, React Native).
2. **Preserve Working Functionality:** Ensure existing Riverpod providers and FastAPI endpoints remain functional.
3. **No Unapproved Dependencies:** Do not add third-party packages to `pubspec.yaml` or `requirements.txt` without explicit approval.
4. **Keep V1.0 Scope Frozen:** Reject feature requests that introduce new domains (Calendar, AI, Sync) into V1.0. Place them in `TASKS.md` under their respective future milestone.
5. **Small, Testable Changes:** Edit small slices of code, verify compile status, and write unit tests for every change.
6. **No Phantom Evidence:** Never mark a task as `DONE-VERIFIED` without citing the exact file, line number, or passing test output.
7. **Document Sync:** Whenever code is modified, update `MEMORY.md` and `TASKS.md` immediately.

---

## 14. Documentation Sitemap

- [ARCHITECTURE.md](file:///c:/StudyOS/ARCHITECTURE.md) — System overview, data flow, ER diagram, and technology stack.
- [DESIGN.md](file:///c:/StudyOS/DESIGN.md) — Visual tokens, UX layout, components, and interaction patterns.
- [MEMORY.md](file:///c:/StudyOS/MEMORY.md) — This file (durable AI handoff and rules).
- [PRD.md](file:///c:/StudyOS/PRD.md) — Product requirements, functional/non-functional specs, and acceptance criteria.
- [TASKS.md](file:///c:/StudyOS/TASKS.md) — Actionable task tracker with stable IDs and priorities.

---

## 15. How to Update This Memory File

Whenever an implementation change is made:
1. Update Section 4 if a dependency version is bumped.
2. Move resolved items out of Section 11 (Known Bugs) into a completed changelog.
3. If an architectural decision is altered, record an ADR entry in Section 9.
4. Increment the document revision date at the top of this file.
