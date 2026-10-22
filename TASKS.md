# StudyOS — Tasks & Implementation Progress (`TASKS.md`)

> **Document Version:** 1.0.0  
> **Master Reference:** [ARCHITECTURE.md](file:///c:/StudyOS/ARCHITECTURE.md), [PRD.md](file:///c:/StudyOS/PRD.md)  
> **Current Milestone:** V1.0 Stabilization (Scope Frozen)  
> **Test Status:** 100% Widget Smoke Passing, Pure Functions Verified, Cascade Deletes Verified

---

## 1. High-Level Milestone Dashboard

| Milestone | Focus | Status | Target Completion |
|---|---|:---:|---|
| **V1.0 MVP Core** | Core Roadmap, Notes, Goals, Dashboard, Backend | ✅ **DONE-VERIFIED** | October 2026 |
| **V1.0 Stabilization** | UI Polish, Deprecation Fixes, Reset & Theme wiring | ✅ **DONE-VERIFIED** | October 2026 |
| **V1.1 Productivity** | Roadmap search, Keyboard shortcuts, View toggles | 📋 PROPOSED | Post-V1.0 |
| **V1.2 Planning** | Daily/Weekly planners, Study-hour tracking | 📋 PROPOSED | Future |
| **V1.3 Analytics** | Consistency streaks, Completion trends, Hour charts | 📋 PROPOSED | Future |
| **V1.4 Resources** | Project tracker, Syllabus book & URL repository | 📋 PROPOSED | Future |
| **V2.0 Local AI** | Offline AI Study Planner, Quiz generator, Note summarizer | 📋 PROPOSED | Future |
| **V2.x Doc Intel** | Local PDF QA and Textbook RAG | 📋 PROPOSED | Future |
| **V3.0 Sync & Cloud** | Multi-device encrypted sync, Cloud backups | 📋 PROPOSED | Long-term |

---

## Section A: V1.0 Audit Findings

*Audit conducted across source code, models, schemas, and live tests.*

- [x] **`AUDIT-001` — Shell & Navigation Core**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Release:** V1.0
  - **Description:** Verified 5-route sidebar navigation, branding, version badge, and responsive desktop container layout.
  - **Evidence:** `app_shell.dart:21-52`, `app_router.dart:10-54`.

- [x] **`AUDIT-002` — Dynamic Dashboard Calculations**
  - **Status:** `DONE-VERIFIED` | **Priority:** P0 | **Release:** V1.0
  - **Description:** Verified dynamic progress percentage, completed/remaining counts, and countdown days computed via pure functions without redundant DB columns.
  - **Evidence:** `backend/utils/progress_calculator.py`, `backend/routers/dashboard.py`. Automated test verified.

- [x] **`AUDIT-003` — Roadmap 4-Tier Hierarchy**
  - **Status:** `DONE-VERIFIED` | **Priority:** P0 | **Release:** V1.0
  - **Description:** Verified strict 4-level nesting: Roadmap → Phase → Topic → Subtopic with full CRUD, order indexing, and ExpansionTiles.
  - **Evidence:** `models/roadmap.py`, `models/phase.py`, `models/topic.py`, `models/subtopic.py`, `roadmap_page.dart`.

- [x] **`AUDIT-004` — Topic & Subtopic Completion Toggles**
  - **Status:** `DONE-VERIFIED` | **Priority:** P0 | **Release:** V1.0
  - **Description:** Verified checkbox toggles mutate `is_completed`, trigger Riverpod invalidation, and update dashboard immediately.
  - **Evidence:** `topics.py:55-64`, `subtopics.py:33-43`, `roadmap_provider.dart:105, 131`.

- [x] **`AUDIT-005` — Goal Pacing & Overdue Detection**
  - **Status:** `DONE-VERIFIED` | **Priority:** P0 | **Release:** V1.0
  - **Description:** Verified target date configuration, countdown days remaining, daily required topics calculation, and overdue status.
  - **Evidence:** `progress_calculator.py:40-52`, `goals_page.dart:161-240`. Automated test verified.

- [x] **`AUDIT-006` — Context-Linked Notes & Auto-Save**
  - **Status:** `DONE-VERIFIED` | **Priority:** P0 | **Release:** V1.0
  - **Description:** Verified 1-to-1 topic-note linkage, dual Edit/Preview Markdown modes, and 500ms debounced PUT upsert auto-save.
  - **Evidence:** `notes.py:30-44`, `notes_provider.dart:48-55`, `notes_page.dart:227-335`.

- [x] **`AUDIT-007` — SQLite WAL & Foreign Key Cascade**
  - **Status:** `DONE-VERIFIED` | **Priority:** P0 | **Release:** V1.0
  - **Description:** Verified `PRAGMA foreign_keys=ON`, `PRAGMA journal_mode=WAL`, and `ondelete="CASCADE"` wiping child entities when parent is deleted.
  - **Evidence:** `database.py:23-29`. Verified with in-memory cascade deletion script.

- [x] **`AUDIT-008` — Theme Mode Switching Toggle**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Release:** V1.0
  - **Description:** Dark/Light Theme switch wired to `themeModeProvider` in `app_theme.dart` and consumed dynamically by `StudyOsApp` in `app.dart`.
  - **Evidence:** `app_theme.dart:5`, `app.dart:10-18`, `settings_page.dart:88-95`.

- [x] **`AUDIT-009` — Database Clean Reset Control**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Release:** V1.0
  - **Description:** "Reset All" confirmation dialog invokes `POST /system/reset`, resets active roadmap, invalidates all Riverpod caches, and notifies user.
  - **Evidence:** `backend/routers/system.py:10-18`, `settings_page.dart:150-180`.

- [x] **`AUDIT-010` — Dashboard Empty State Navigation**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Release:** V1.0
  - **Description:** Dashboard empty state "New Roadmap" action button navigates to `/roadmap` via `context.go('/roadmap')`.
  - **Evidence:** `dashboard_page.dart:22-26`.

---

## Section B: V1.0 Stabilization Tasks (P0 & P1)

- [x] **`TASK-STAB-001` — Implement Backend Database Reset Endpoint**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Milestone:** V1.0 Stabilization
  - **Description:** Added `POST /system/reset` in backend that drops and recreates all tables via `Base.metadata.drop_all(bind=engine)` and `init_db()`.
  - **Evidence:** `backend/routers/system.py`, registered in `backend/main.py`. Verified by automated test in `tests/test_routers.py`.

- [x] **`TASK-STAB-002` — Connect Settings Reset Button to API**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Milestone:** V1.0 Stabilization
  - **Description:** Wired the "Reset All" button in `SettingsPage` to invoke `ApiService().post('/system/reset')`, invalidate all providers, and display a snackbar confirmation.
  - **Evidence:** `frontend/lib/features/settings/presentation/settings_page.dart:150-185`.

- [x] **`TASK-STAB-003` — Implement Dynamic ThemeMode Provider**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Milestone:** V1.0 Stabilization
  - **Description:** Created `themeModeProvider` in `app_theme.dart` and wired `StudyOsApp` and `SettingsPage` to toggle between `ThemeMode.dark` and `ThemeMode.light`.
  - **Evidence:** `app_theme.dart`, `app.dart`, `settings_page.dart`. Tested and verified.

- [x] **`TASK-STAB-004` — Fix Dashboard Empty State Navigation**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Milestone:** V1.0 Stabilization
  - **Description:** Wired `_EmptyState(onCreateRoadmap: () => context.go('/roadmap'))` in `DashboardPage`.
  - **Evidence:** `frontend/lib/features/dashboard/presentation/dashboard_page.dart:22-26`.

- [x] **`TASK-STAB-005` — Migrate Deprecated Flutter API Usages**
  - **Status:** `DONE-VERIFIED` | **Priority:** P2 | **Milestone:** V1.0 Stabilization
  - **Description:** Replaced `.withOpacity(...)` with `.withValues(...)`, `dialogBackgroundColor` with `DialogThemeData`, `activeColor` with `activeThumbColor`, and removed unused imports.
  - **Evidence:** `flutter analyze` completed with 0 errors, 0 warnings, 0 infos ("No issues found!").

- [x] **`TASK-STAB-006` — Build Automated Backend Router Test Suite**
  - **Status:** `DONE-VERIFIED` | **Priority:** P1 | **Milestone:** V1.0 Stabilization
  - **Description:** Created `backend/tests/test_routers.py` using `pytest` and `TestClient(app)` verifying all CRUD endpoints, 404 responses, and 422 validations.
  - **Evidence:** `pytest tests/test_routers.py` passed 3/3 tests with zero warnings (100% pass rate).

---

## Section C: Required Tasks for V1.0 Acceptance

- [x] **`TASK-REQ-001` — Verified End-to-End Startup Verification**
  - **Status:** `DONE-VERIFIED` | **Priority:** P0 | **Milestone:** V1.0 Acceptance
  - **Description:** Complete automated end-to-end user journeys executed against a live Uvicorn subprocess on `127.0.0.1:8000`.
  - **Evidence:** `backend/tests/e2e_verification.py`. All 7 steps passed (100%): Subprocess launch & `/health` check → Clean Reset → Roadmap & Phase & Topic hierarchy creation → Goal setting & dynamic pace calculation (`0.1 topics/day`) → Markdown note autosave & retrieval → Topic completion toggle & 50.0% progress recalculation → Subprocess restart & SQLite WAL persistence retention verified.

---

## Section D: Completed V1.1 — Productivity Improvements

- [x] **`TASK-V11-001` — Roadmap & Notes Full-Text Search**
  - **Status:** `DONE-VERIFIED` | **Priority:** P2 | **Milestone:** V1.1
  - **Description:** Added instant search filter bar in Roadmap and Notes explorers with case-insensitive backend query support (`/roadmaps/?q=` and `/notes/?q=`).
  - **Evidence:** `backend/routers/roadmaps.py`, `backend/routers/notes.py`, `roadmap_page.dart:58-88`, `notes_page.dart:79-114`. Verified via automated tests `test_search_endpoints()` in `tests/test_routers.py`.

- [x] **`TASK-V11-002` — Global Desktop Keyboard Shortcuts**
  - **Status:** `DONE-VERIFIED` | **Priority:** P2 | **Milestone:** V1.1
  - **Description:** Implemented `CallbackShortcuts` and `SingleActivator` listeners for `Ctrl+1` (Dashboard), `Ctrl+2` (Roadmap), `Ctrl+3` (Goals), `Ctrl+4` (Notes), `Ctrl+5` (Settings), along with keyboard shortcut badges and hover tooltips on the sidebar navigation items.
  - **Evidence:** `frontend/lib/shared/widgets/app_shell.dart:55-85, 215-265`. Verified via `flutter test`.

- [x] **`TASK-V11-003` — Compact Tree View Mode**
  - **Status:** `DONE-VERIFIED` | **Priority:** P3 | **Milestone:** V1.1
  - **Description:** Added a view mode toggle in Roadmap Manager allowing instant switching between spacious cards and a compact hierarchical tree view with inline phase/topic completion nodes and action triggers.
  - **Evidence:** `frontend/lib/features/roadmap/presentation/roadmap_page.dart:88-115, 226-515`. Verified via `flutter analyze` (0 issues).

---

## Section E: Milestone V1.2 — Planning (Completed 100%)

- [x] **`TASK-V12-001` — Daily Study Schedule & Time-Blocking**
  - **Status:** `DONE-VERIFIED` | **Priority:** P2 | **Milestone:** V1.2 Planning
  - **Description:** Implemented full backend CRUD API for `ScheduleBlock` (`GET /schedule/?target_date=`, `POST`, `PATCH`, `DELETE`) and desktop Flutter presentation (`schedule_page.dart`) with day navigator, time block cards, completion toggles, daily progress bar, and keyboard navigation (`Ctrl+3`).
  - **Evidence:** `backend/models/schedule_block.py`, `backend/routers/schedule.py`, `frontend/lib/features/schedule/presentation/schedule_page.dart`. Verified via automated tests `test_schedule_endpoints()` (100% pass) and `flutter analyze` (0 issues).

- [x] **`TASK-V12-002` — Stopwatch & Study-Hour Logging per Topic**
  - **Status:** `DONE-VERIFIED` | **Priority:** P2 | **Milestone:** V1.2 Planning
  - **Description:** Implemented backend `StudySession` model, summary & stats API (`POST /study-sessions/`, `GET /study-sessions/summary`, `GET /study-sessions/topic/{id}`), frontend `StudyTimerNotifier`, global glowing `ActiveStudyTimerBar` at bottom of `AppShell`, quick topic timer triggers & invested time badges (`_TopicStudyBadge`) across Roadmap and Notes workspaces.
  - **Evidence:** `backend/models/study_session.py`, `backend/routers/study_sessions.py`, `frontend/lib/features/timer/`, `roadmap_page.dart:1110-1195`, `notes_page.dart:315-360`. Verified via automated tests `test_study_sessions_endpoints()` (100% pass) and `flutter analyze` (0 issues).

- [x] **`TASK-V12-003` — Calendar View for Target Milestones & Daily Schedule**
  - **Status:** `DONE-VERIFIED` | **Priority:** P2 | **Milestone:** V1.2 Planning
  - **Description:** Implemented backend aggregation endpoint (`GET /calendar/events?year=&month=`) consolidating roadmap target milestones, scheduled time blocks, and logged study hours for any month. Implemented desktop Flutter `CalendarView` with interactive monthly grid, date-specific indicators (milestones 🚩, blocks 📅, study time ⏱️), monthly metrics ribbon, and responsive selected-day inspector with inline completion and scheduling shortcuts.
  - **Evidence:** `backend/routers/calendar.py`, `backend/schemas/calendar.py`, `frontend/lib/features/schedule/presentation/calendar_view.dart`, `frontend/lib/features/schedule/presentation/schedule_page.dart`, `frontend/test/calendar_test.dart`. Verified via pytest (100% pass), `flutter test` (100% pass), and `flutter analyze` (0 issues).

---

## Section F: Milestone V1.3 — Analytics (In Progress)

- [x] **`TASK-V13-001` — Study Streaks & Daily Consistency Counter**
  - **Status:** `DONE-VERIFIED` | **Priority:** P2 | **Milestone:** V1.3 Analytics
  - **Description:** Implemented backend `/analytics/streak` endpoint calculating active consecutive study days (sessions, schedule blocks, completed topics), longest streak record, total active days, and 7-day weekly consistency matrix. Built frontend `StreakConsistencyCard` with glowing fire motif, daily status chips, week strip with active checkmarks, and live `_SidebarStreakBadge` in `AppShell`.
  - **Evidence:** `backend/routers/analytics.py`, `backend/schemas/analytics.py`, `frontend/lib/features/analytics/`, `dashboard_page.dart:140-145`, `app_shell.dart:140-155, 270-335`. Verified via pytest (100% pass, 8/8 tests), `flutter test` (100% pass, 9/9 tests), and `flutter analyze` (0 issues).

- [x] **`TASK-V13-002` — Phase Burndown & Velocity Charts**
  - **Status:** `DONE-VERIFIED` | **Priority:** P2 | **Milestone:** V1.3 Analytics
  - **Description:** Implemented backend `/analytics/burndown/{roadmap_id}` endpoint delivering comprehensive phase burndown progress (order index, completed/remaining topics, progress percent, estimated days to finish per phase), 7-day velocity metrics (current pace vs required goal pace, days remaining, schedule status, projected finish date), and 7-day velocity activity breakdown. Built responsive Flutter `BurndownVelocityCard` on Dashboard featuring dual-column master/detail breakdown, status pill badges, phase completion progress bars, velocity statistics cards, and vertical bar velocity chart. Wired reactive cache invalidations across topic, phase, and goal mutations.
  - **Evidence:** `backend/routers/analytics.py`, `backend/schemas/analytics.py`, `frontend/lib/features/analytics/presentation/burndown_velocity_card.dart`, `frontend/lib/features/analytics/domain/burndown_model.dart`, `frontend/lib/features/analytics/application/burndown_provider.dart`, `frontend/test/burndown_test.dart`. Verified via pytest (100% pass, 9/9 tests), `flutter test` (100% pass, 14/14 tests), and `flutter analyze` (0 issues).

- [ ] **`TASK-V13-003` — Monthly Study Hours Distribution** (`BACKLOG`, P3)

---

## Section G: Future Release Backlog (V1.4 onward)

### V1.4 — Projects & Resources
- [ ] **`TASK-V14-001` — Topic Learning Resource Shelf (Books, Course URLs, PDFs)** (`BACKLOG`, P2)
- [ ] **`TASK-V14-002` — Practice Project Tracker with GitHub Links** (`BACKLOG`, P2)

### V2.0 — Local AI Features
- [ ] **`TASK-V20-001` — Offline LLM Study Planner (Ollama Integration)** (`BACKLOG`, P2)
- [ ] **`TASK-V20-002` — Automated Flashcard & Quiz Generation from Notes** (`BACKLOG`, P2)
- [ ] **`TASK-V20-003` — AI Note Summarizer & Concept Explainer** (`BACKLOG`, P2)

### V2.x — Document Intelligence
- [ ] **`TASK-V2X-001` — Local Textbook & Paper PDF Q&A with RAG** (`BACKLOG`, P2)

### V3.0 — Cloud & Sync
- [ ] **`TASK-V30-001` — End-to-End Encrypted Multi-Device Sync** (`BACKLOG`, P3)
- [ ] **`TASK-V30-002` — Automated Local & Cloud Encrypted Backups** (`BACKLOG`, P3)

### General Unscheduled Backlog
- [ ] **`TASK-GEN-001` — Pomodoro Focus Mode with ambient audio** (`BACKLOG`, P3)
- [ ] **`TASK-GEN-002` — Spaced Repetition Flashcards (SM-2 Algorithm)** (`BACKLOG`, P3)
- [ ] **`TASK-GEN-003` — Gamification (XP, Levels, Completion Badges)** (`BACKLOG`, P3)
- [ ] **`TASK-GEN-004` — Roadmap Import/Export (JSON, Markdown, CSV)** (`BACKLOG`, P3)
