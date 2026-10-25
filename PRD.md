# StudyOS — Product Requirements Document (PRD)

> **Document Version:** 1.0.0  
> **Status:** Verified Active Specification  
> **Target Release:** Version 1.0 (MVP)  
> **Scope State:** Frozen for Stabilization

---

## 1. Product Summary

**StudyOS** is a local-first, distraction-free desktop operating system for self-directed technical learners. It combines hierarchical curriculum roadmap tracking, dynamic study pacing, completion deadline countdowns, and context-linked Markdown note-taking into a unified, high-performance desktop workstation.

---

## 2. Problem Statement

Self-directed learners, software engineers, and technical researchers face significant friction when studying large, multi-month curricula (such as Computer Systems, Machine Learning, or Distributed Systems):
1. **Curriculum Fragmentation:** Course syllabi, topic checklists, and notes are scattered across Notion, spreadsheets, bookmarks, and random text files.
2. **Loss of Pacing Awareness:** Learners frequently miss target completion dates because static checklists do not calculate the required daily study velocity.
3. **Context Disconnection:** Notes taken during study sessions are detached from the overarching roadmap, making revision and retention difficult.
4. **Cloud Bloat & Privacy Concerns:** Many modern tools suffer from high latency, recurring subscription costs, and mandatory cloud logins that interrupt focused offline study.

---

## 3. Target Users

- **Computer Science & Engineering Students:** Managing semester courses, syllabus roadmaps, and programming concepts.
- **Self-Taught Developers & Career Switchers:** Following structured curricula (e.g. OSSU, full-stack roadmaps) with strict target deadlines.
- **Technical Professionals:** Upskilling in specialized domains (e.g. Kubernetes, AI Engineering, Cloud Architecture).

---

## 4. Product Goals

1. **Structured Learning Hierarchy:** Provide an intuitive 4-tier learning tree ($\text{Roadmap} \to \text{Phase} \to \text{Topic} \to \text{Subtopic}$).
2. **Intelligent Dynamic Pacing:** Auto-calculate remaining days and exact required daily topic completion velocity.
3. **Context-Linked Knowledge Capture:** Enable instantaneous Markdown note-taking directly associated with the active topic.
4. **Local & Offline Sovereignty:** 100% functionality without internet connectivity, storing all data in a local SQLite database.

---

## 5. Non-Goals (V1.0)

- **Cloud Synchronization & Accounts:** No remote user accounts, social feeds, or cross-device cloud sync in V1.0.
- **WYSIWYG Rich Text Editing:** No complex drag-and-drop document blocks; Markdown is the standard format.
- **Infinite Tree Nesting:** Explicitly limited to 4 predefined hierarchical levels.
- **Third-Party Service Integrations:** No direct GitHub, Google Calendar, or Notion sync in V1.0.

---

## 6. V1.0 Feature Inventory & Implementation Audit

The following table reflects the **complete, audited status** of all V1.0 features across code inspection, tests, and runtime verification:

| ID | Feature Group | Feature Name | Status | Evidence / Source Reference |
|---|---|---|:---:|---|
| **INV-001** | Application Shell | Branding & Versioning | `DONE-VERIFIED` | `app_shell.dart:109, 142` (StudyOS logo & v1.0.0 label) |
| **INV-002** | Application Shell | Sidebar Navigation | `DONE-VERIFIED` | `app_shell.dart:21-52`, `app_router.dart:10-54` (5 routes) |
| **INV-003** | Application Shell | Dark Theme | `DONE-VERIFIED` | `app_theme.dart:41-100`, `app.dart:15` (Material 3 Dark) |
| **INV-004** | Application Shell | Light Theme Toggle | `DONE-VERIFIED` | `app_theme.dart:5`, `app.dart:10-18`, `settings_page.dart:88-95` |
| **INV-005** | Application Shell | Window Resizing & Layout | `DONE-VERIFIED` | `app_shell.dart:65-71` (Responsive desktop flex) |
| **INV-006** | Dashboard | Active Roadmap Title | `DONE-VERIFIED` | `dashboard_page.dart:96`, `dashboard.py:80` |
| **INV-007** | Dashboard | Current Phase & Topic | `DONE-VERIFIED` | `dashboard.py:45-55`, `dashboard_page.dart:104-120` |
| **INV-008** | Dashboard | Overall Progress Bar | `DONE-VERIFIED` | `progress_calculator.py:11-23`, `dashboard_page.dart:156` |
| **INV-009** | Dashboard | Completed & Total Counts | `DONE-VERIFIED` | `progress_calculator.py:19-21`, `dashboard_page.dart:181` |
| **INV-010** | Dashboard | Deadline Countdown | `DONE-VERIFIED` | `progress_calculator.py:40-52`, `dashboard_page.dart:164` |
| **INV-011** | Dashboard | Today's Focus Suggestions | `DONE-VERIFIED` | `progress_calculator.py:55-70`, `dashboard_page.dart:191` |
| **INV-012** | Dashboard | Phase Breakdown Cards | `DONE-VERIFIED` | `progress_calculator.py:26-37`, `dashboard_page.dart:260` |
| **INV-013** | Dashboard | Multiple Roadmap Switcher | `DONE-VERIFIED` | `dashboard_page.dart:125-139` (Dropdown selector) |
| **INV-014** | Dashboard | Empty State Handling | `DONE-VERIFIED` | `dashboard_page.dart:22-26` (Wired to `context.go('/roadmap')`) |
| **INV-015** | Roadmap Manager | Create Roadmap | `DONE-VERIFIED` | `roadmap_page.dart:74`, `roadmaps.py:19` |
| **INV-016** | Roadmap Manager | Add / Edit / Delete Phase | `DONE-VERIFIED` | `roadmap_page.dart:212, 637, 662`, `phases.py:20, 43, 54` |
| **INV-017** | Roadmap Manager | Add / Edit / Delete Topic | `DONE-VERIFIED` | `roadmap_page.dart:320, 695, 719`, `topics.py:21, 43, 68` |
| **INV-018** | Roadmap Manager | Add / Delete Subtopic | `DONE-VERIFIED` | `roadmap_page.dart:456, 531`, `subtopics.py:19, 46` |
| **INV-019** | Roadmap Manager | Toggle Topic Complete | `DONE-VERIFIED` | `roadmap_page.dart:404`, `topics.py:55-64` |
| **INV-020** | Roadmap Manager | Toggle Subtopic Complete | `DONE-VERIFIED` | `roadmap_page.dart:507`, `subtopics.py:33-43` |
| **INV-021** | Roadmap Manager | Collapsible Hierarchy Tree| `DONE-VERIFIED` | `roadmap_page.dart:170, 275, 386` (ExpansionTiles) |
| **INV-022** | Roadmap Manager | Automatic Progress Sync | `DONE-VERIFIED` | Pure calculation in `progress_calculator.py:11-37` |
| **INV-023** | Goal Manager | Set Target Completion Date| `DONE-VERIFIED` | `goals_page.dart:147`, `goals.py:19` |
| **INV-024** | Goal Manager | Change Target Date | `DONE-VERIFIED` | `goals_page.dart:216`, `goals.py:30` |
| **INV-025** | Goal Manager | Delete / Reset Goal | `DONE-VERIFIED` | `goals_page.dart:227`, `goals.py:41` |
| **INV-026** | Goal Manager | Calculate Remaining Days | `DONE-VERIFIED` | `progress_calculator.py:42-49`, `test_api.py:51-58` |
| **INV-027** | Goal Manager | Calculate Topics Per Day | `DONE-VERIFIED` | `progress_calculator.py:46`, pure function tested |
| **INV-028** | Goal Manager | Overdue Deadline Alert | `DONE-VERIFIED` | `progress_calculator.py:51`, `goals_page.dart:168` |
| **INV-029** | Notes | Topic Explorer Sidebar | `DONE-VERIFIED` | `notes_page.dart:51-165` (Grouped by phase) |
| **INV-030** | Notes | Multi-line Markdown Editor | `DONE-VERIFIED` | `notes_page.dart:278-311` (Monospace Courier font) |
| **INV-031** | Notes | Formatted Markdown Preview | `DONE-VERIFIED` | `notes_page.dart:320-335` (flutter_markdown) |
| **INV-032** | Notes | 500ms Debounced Auto-Save | `DONE-VERIFIED` | `notes_provider.dart:49-54`, `notes_page.dart:227-245` |
| **INV-033** | Notes | Cascade Cleanup on Delete | `DONE-VERIFIED` | `models/note.py:17` (`ondelete="CASCADE"`), verified |
| **INV-034** | Local Storage | SQLite WAL Engine | `DONE-VERIFIED` | `database.py:27` (`PRAGMA journal_mode=WAL`) |
| **INV-035** | Local Storage | Foreign Key Enforcment | `DONE-VERIFIED` | `database.py:26` (`PRAGMA foreign_keys=ON`) |
| **INV-036** | Local Storage | Database Clean Reset | `DONE-VERIFIED` | `backend/routers/system.py:10`, `settings_page.dart:150-185` |
| **INV-037** | Settings | Environment Information | `DONE-VERIFIED` | `settings_page.dart:38-41` (Informational text cards) |

---

## 7. Core User Journeys

### User Journey 1: Building a New Study Roadmap
1. Learner clicks **Roadmap** in sidebar.
2. Learner clicks **New Roadmap**, enters "Distributed Systems", and clicks Save.
3. Learner adds "Phase 1: Foundations", adds "Topic 1: Consensus", and adds subtopics "Raft" and "Paxos".
4. Learner navigates to **Dashboard**; the new roadmap appears with 0.0% completion and 1 total topic.

### User Journey 2: Setting a Study Goal & Checking Velocity
1. Learner navigates to **Goals**.
2. Learner clicks **Set Target Date** and selects a date 30 days in the future.
3. The Goal Manager instantly calculates: `30 days remaining`, `1 remaining topic`, required pace `0.03 topics / day`.
4. Learner returns to **Dashboard**; the Countdown card shows "30 days left" and Today's Focus recommends "Topic 1: Consensus".

### User Journey 3: Studying and Taking Context Notes
1. Learner clicks **Notes** in sidebar.
2. Learner selects "Topic 1: Consensus" from the left topic explorer.
3. Learner types study notes in Markdown in the editor pane.
4. Auto-save displays `Saving...` and transitions to `Saved` 500ms after the last keystroke.
5. Learner toggles to **Preview** to read formatted headings and syntax-highlighted code.
6. Learner returns to **Roadmap** and marks "Topic 1: Consensus" as completed.
7. Dashboard overall progress updates to 100.0%.

---

## 8. Functional Requirements

### Group A: Roadmap & Hierarchy Management
- **FR-001 (Roadmap CRUD):** The system shall allow creating, reading, updating (title/description), and deleting roadmaps.
- **FR-002 (Hierarchy Structure):** The system shall enforce a strict 4-level hierarchy: Roadmap → Phase → Topic → Subtopic.
- **FR-003 (Phase Management):** Each phase shall belong to a roadmap, have a title, and have an `order_index`.
- **FR-004 (Topic Management):** Each topic shall belong to a phase, have an `is_completed` boolean flag, and maintain an optional `completed_at` timestamp.
- **FR-005 (Subtopic Management):** Each subtopic shall belong to a topic, have an `is_completed` boolean flag, and maintain an `order_index`.
- **FR-006 (Cascading Deletion):** Deleting any parent entity shall automatically delete all child entities across the entire tree.

### Group B: Progress & Dashboard
- **FR-007 (Dynamic Progress Calculation):** Overall and phase-level progress shall be computed dynamically on read from topic completion counts.
- **FR-008 (Current Focus Identification):** The dashboard shall display the first incomplete topic in chronological sequence.
- **FR-009 (Today's Focus Algorithm):** The system shall recommend up to $\lceil \text{topics\_per\_day} \rceil$ incomplete topics for daily focus.
- **FR-010 (Multiple Roadmap Switching):** The user shall be able to switch between multiple roadmaps via a dropdown selector.

### Group C: Goals & Deadlines
- **FR-011 (Goal Association):** The system shall allow associating a target completion date with a roadmap.
- **FR-012 (Countdown Calculation):** Days remaining shall equal $\max(0, \text{target\_date} - \text{today})$.
- **FR-013 (Study Pace Calculation):** Required topics per day shall equal $\frac{\text{remaining\_topics}}{\text{days\_remaining}}$ when days remaining $> 0$.
- **FR-014 (Overdue Flagging):** When $\text{today} > \text{target\_date}$, the system shall display an "Overdue!" warning badge.

### Group D: Notes Workspace
- **FR-015 (Topic-Note Linkage):** Each topic shall have at most one associated note (`unique=True`).
- **FR-016 (Auto-Save):** Note content changes shall automatically persist to the database after a 500ms debounce window.
- **FR-017 (Dual-Mode Viewer):** The notes workspace shall provide both raw Markdown text editing and formatted preview modes.

### Group E: Local Persistence & Lifecycle
- **FR-018 (Subprocess Supervisor):** The desktop client shall check backend health on boot and launch the FastAPI server if inactive.
- **FR-019 (SQLite WAL Operation):** The database engine shall operate in WAL mode with active foreign key checks.

---

## 9. Non-Functional Requirements

- **NFR-001 (Performance):** Dashboard and Roadmap screens shall load in $<100\text{ms}$ on local machines.
- **NFR-002 (Storage Footprint):** The core application executable and database shall consume $<150\text{MB}$ disk space.
- **NFR-003 (Memory Footprint):** Combined client and backend idle RAM usage shall not exceed $250\text{MB}$.
- **NFR-004 (Offline Operation):** 100% of core features must function without an active internet connection.
- **NFR-005 (Data Integrity):** Abrupt application termination (e.g. process kill) shall not corrupt the SQLite database due to WAL crash protection.
- **NFR-006 (Compatibility):** Support Windows 10/11 x64 and Linux desktop distributions.

---

## 10. Data & Persistence Requirements

1. **Storage Engine:** SQLite 3.x with WAL journal mode.
2. **Path:** `data/studyos.db` relative to project directory.
3. **Database Initialization:** Auto-created via `init_db()` on first startup.
4. **Data Isolation:** User data remains strictly local; no outbound telemetry or cloud transmission.

---

## 11. Error & Edge-Case Requirements

| Edge Case | Required Behavior | Handled By |
|---|---|---|
| **Zero topics in roadmap** | Display 0.0% progress; no division-by-zero crash. | `progress_calculator.py:22` |
| **No active goal set** | Display default 3 suggestions; show "No Target Date Set" card. | `dashboard.py:76`, `goals_page.dart:119` |
| **Target date in the past** | Set `is_overdue=True`, `days_remaining=0`, pace = remaining topics. | `progress_calculator.py:43-52` |
| **Target date today** | Set `days_remaining=0`, pace = remaining topics. | `progress_calculator.py:43` |
| **Backend port 8000 in use** | Detect existing service; reuse without spawning duplicate process. | `main.dart:14-15` |
| **Note requested for non-existent topic** | Return 404 HTTP status; UI displays null without crashing. | `notes.py:22-26`, `notes_provider.dart:15-18` |

---

## 12. Acceptance Criteria for Core Workflows

1. **Hierarchy Integrity:** When a Phase with 5 topics is deleted, all 5 topics and their linked notes must be purged from the database immediately.
2. **Progress Calculation Accuracy:** Marking 2 out of 4 topics complete must yield exactly `50.0%` overall progress, verified on both Dashboard and Roadmap pages.
3. **Pacing Real-Time Update:** Updating a goal's target date from 10 days to 5 days must immediately double the required topics-per-day indicator without requiring an application restart.
4. **Notes Autosave Recovery:** If the user types notes and closes the window 1 second later, the full text must be present upon reopening the application.

---

## 13. Proposed Future Releases (Roadmap)

### Current Milestone: V1.0 Stabilization (Scope Frozen)
- Resolve UI-only gaps (Theme toggle, DB clean reset).
- Fix empty state navigation callbacks.
- Eliminate Flutter 3.27+ deprecation warnings.
- Complete automated pytest router test suite.

### Completed: V1.1 — Productivity Improvements (DONE-VERIFIED)
- Roadmap and Notes full-text search with instant filtering and backend ILIKE query support (`TASK-V11-001`).
- Global desktop keyboard shortcuts (`Ctrl+1` through `Ctrl+5`) and sidebar badges (`TASK-V11-002`).
- Compact tree view toggle for dense hierarchical roadmap view (`TASK-V11-003`).

### Completed: Milestone V1.2 — Planning (DONE-VERIFIED)
- **Daily Study Schedule & Time Blocking (`TASK-V12-001` - DONE-VERIFIED):** Hourly block planner, day navigator, progress bar, completion checkboxes.
- **Stopwatch & Study-Hour Logging per Topic (`TASK-V12-002` - DONE-VERIFIED):** Active focus timer, persistent glowing bottom timer bar, topic study badges and session logging.
- **Calendar View for Target Milestones (`TASK-V12-003` - DONE-VERIFIED):** Monthly milestone calendar grid, study blocks overview, logged study hours ribbon, and day inspector.

### Completed: Milestone V1.3 — Analytics (DONE-VERIFIED)
- **Study Streaks & Daily Consistency Counter (`TASK-V13-001` - DONE-VERIFIED):** Consecutive active study days, longest streak record, 7-day consistency strip on Dashboard, and live sidebar streak badge.
- **Phase Completion Velocity & Burndown Charts (`TASK-V13-002` - DONE-VERIFIED):** Phase burndown progress bars, remaining topic estimates, 7-day velocity average, schedule health status, projected finish date, and 7-day velocity chart.
- **Monthly Study Hour Distribution Graphs (`TASK-V13-003` - DONE-VERIFIED):** Month-by-month study duration, full month day-by-day histogram, top topics share, and Monday–Sunday weekday study habits.

### Completed: Milestone V1.4 — Projects & Resources (DONE-VERIFIED)
- **Topic Learning Resource Shelf (`TASK-V14-001` - DONE-VERIFIED):** Resource repository linked to topics (Books, PDFs, documentation links, YouTube courses, GitHub links) with type selector chips, completion tracking, and quick shelf launcher.
- **Practice Project Tracker with GitHub Links (`TASK-V14-002` - DONE-VERIFIED):** Project portfolio tracker with GitHub repo links, difficulty ratings, tech stack badges, status overview cards, clipboard URL copy, and roadmap navigation shortcut.

### Completed: Milestone V2.0 — Local AI Features (DONE-VERIFIED)
- **Offline LLM Study Planner (`TASK-V20-001` - DONE-VERIFIED):** Intelligent study plan generator integrated with local Ollama (`http://127.0.0.1:11434`) and built-in offline heuristic curriculum engine, featuring live Ollama connection status, customizable parameters, Markdown plan preview, and one-click "Convert to Roadmap" action.
- **Automated Flashcard & Quiz Generation from Notes (`TASK-V20-002` - DONE-VERIFIED):** Generate active recall flashcard decks (with 3D animated flip cards and mastery tracking) and interactive multiple-choice quizzes with explanations directly from study notes or manual input via local Ollama and offline heuristic extractor.
- **AI Note Summarizer & Concept Explainer (`TASK-V20-003` - DONE-VERIFIED):** Distill study notes into executive briefs, key takeaways, bullet points, or cheat sheets, and explain complex concepts across four depths (Beginner/ELI5, Intermediate, Technical Deep Dive, Analogy) with one-click insertion and clipboard export.

### Completed: Milestone V2.x — Document Intelligence (DONE-VERIFIED)
- **Local Textbook & Paper PDF Q&A with RAG (`TASK-V2X-001` - DONE-VERIFIED):** Local Retrieval-Augmented Generation (RAG) over study PDFs, research papers, and textbook chapters. Features sliding-window chunking, offline TF-IDF and term-frequency hybrid retrieval, citations with relevance percentage scoring, Ollama AI synthesis with offline evidence extractor fallback, and a dedicated `DocumentHubPage` with two-column library shelf, chunk inspector, and `Ctrl+9` keyboard shortcut.

### Proposed V3.0 — Cloud & Sync
- Multi-device encrypted sync and backup.
