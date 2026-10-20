# StudyOS — Design System & UX Specification

> **Document Version:** 1.0.0  
> **Status:** Verified Active Implementation  
> **Target Release:** Version 1.0 (MVP)

---

## 1. Product Branding & Identity

- **Application Name:** StudyOS
- **Version:** `1.0.0 (MVP)`
- **Visual Identity:** A cybernetic, distraction-free "Developer Operating System" tailored for self-learners, researchers, and technical professionals.
- **Brand Icon:** Clean stylized graduation cap (`Icons.school`) housed inside an indigo-to-cyan gradient container (`32x32px`, `BorderRadius.circular(8)`).
- **Core Aesthetic:** Dark Glassmorphism, Material 3, High-contrast functional typography, muted slate containers, and vivid accent glows.

---

## 2. Design Goals

1. **Zero Cognitive Friction:** The UI must eliminate clutter so the learner can focus 100% on studying and curriculum progression.
2. **High Information Density with Hierarchical Calm:** Information (progress bars, countdowns, pacing stats) must be accessible at a glance without feeling cramped.
3. **Instant Visual Feedback:** Interactive completion checkboxes, live countdown badges, and auto-save indicators provide continuous validation of user effort.
4. **Local-First Speed:** Instant page transitions (using `NoTransitionPage` in `GoRouter`) and sub-10ms UI reactivity.

---

## 3. Design Tokens & Component Styles

All tokens are defined in `frontend/lib/core/theme/app_theme.dart`.

### 3.1 Color Palette

```
Canvas / Backgrounds
  ├── Dark Background   : #0F0F13  (Primary window canvas)
  ├── Dark Surface      : #1A1A24  (Containers, cards, appbars)
  ├── Dark Card         : #22222E  (Elevated cards, list items)
  ├── Dark Card Hover   : #2A2A38  (Hovered cards and interactive rows)
  ├── Sidebar Canvas    : #13131A  (Persistent left navigation bar)
  └── Dark Border       : #2E2E3E  (Subtle container borders)

Primary & Accent
  ├── Primary Indigo    : #6366F1  (Buttons, active tabs, progress bars)
  ├── Primary Dark      : #4F46E5  (Button active/press states)
  ├── Primary Light     : #818CF8  (Highlighted text, badge accents)
  └── Accent Cyan       : #06B6D4  (Secondary indicators, subtopic highlights)

Status & Semantics
  ├── Success Green     : #10B981  (Completed tasks, saved notes indicator)
  ├── Warning Amber     : #F59E0B  (Pending/saving states, pacing warnings)
  ├── Error Red         : #EF4444  (Overdue deadlines, destructive actions)
  └── Info Blue         : #3B82F6  (System information)

Text Colors
  ├── Primary Text      : #F1F1F8  (Headings, primary card titles)
  ├── Secondary Text    : #9494B0  (Subtitles, metadata, inactive icons)
  └── Muted Text        : #5C5C78  (Placeholders, timestamps, phase tags)
```

### 3.2 Typography System

The typography is powered by **Google Fonts (Inter)** for general UI and a **Monospace font (`Courier`)** for Markdown editing:

| Style Role | Font | Size | Weight | Color | Usage |
|---|---|---|---|---|---|
| **Display Large** | Inter | 32px | Bold (700) | `#F1F1F8` | Page titles, major stats |
| **Headline Medium**| Inter | 24px | Bold (700) | `#F1F1F8` | Screen headers, modal titles |
| **Title Medium** | Inter | 18px | SemiBold (600)| `#F1F1F8` | Card headers, roadmap titles |
| **Body Large** | Inter | 15px | Regular (400)| `#F1F1F8` | Main reading text, inputs |
| **Body Medium** | Inter | 14px | Regular (400)| `#9494B0` | Descriptive text, subtitles |
| **Label Small** | Inter | 11px | Medium (500)| `#5C5C78` | Badges, version tags, headers |
| **Code / Editor** | Courier | 14px | Regular (400)| `#F1F1F8` | Notes Markdown editor |

### 3.3 Elevation, Borders & Radii
- **Card Borders:** `1px solid #2E2E3E`
- **Border Radii:**
  - Standard Cards & Containers: `12px`
  - Input Fields & Buttons: `8px`
  - Status Badges & Pills: `6px`
  - Selection Dots: Circular (`shape: BoxShape.circle`)
- **Shadows:** Minimalist zero-blur borders preferred over heavy drop-shadows to preserve crispness on high-DPI displays.

---

## 4. Navigation Architecture

Navigation is implemented using **GoRouter** with a fixed **220px Left Sidebar Shell** (`AppShell` in `frontend/lib/shared/widgets/app_shell.dart`).

```
┌────────────────────────────────────────────────────────┐
│ AppShell Layout                                        │
├──────────────┬─────────────────────────────────────────┤
│ [Logo]       │ Header (Dynamic per screen)             │
│ StudyOS      ├─────────────────────────────────────────┤
│              │                                         │
│ 📊 Dashboard │                                         │
│ 🗺️ Roadmap   │                                         │
│ 🎯 Goals     │           Active Page Content           │
│ 📝 Notes     │        (Nested Router Viewport)         │
│ ⚙️ Settings  │                                         │
│              │                                         │
│              │                                         │
│ v1.0.0       │                                         │
└──────────────┴─────────────────────────────────────────┘
```

- **Sidebar Width:** Fixed `220px`, background `#13131A`.
- **Nav Item States:**
  - *Inactive:* Transparent background, `#9494B0` icon and label.
  - *Hover:* Background `#22222E`, transition duration `150ms`.
  - *Active:* Background `#6366F1` with 15% opacity, border `1px solid #6366F1` (30% opacity), text & icon in Primary Indigo (`#6366F1`), and a 4px circular active dot on the right edge.
- **Route Definitions:**
  - `/dashboard` → `DashboardPage`
  - `/roadmap` → `RoadmapPage`
  - `/goals` → `GoalsPage`
  - `/notes` → `NotesPage`
  - `/settings` → `SettingsPage`

---

## 5. Screen Layouts & User Experience

### 5.1 Dashboard Layout (`dashboard_page.dart`)
- **Header Section:** Time-based greeting (`Good Morning / Afternoon / Evening 👋`), active roadmap title, and a breadcrumb of the current in-progress topic (`Phase 1 → Topic 1.1`).
- **Roadmap Selector:** When multiple roadmaps exist, a sleek dark dropdown appears top-right allowing instant context switching.
- **Top KPI Cards Row:**
  1. *Overall Progress Card:* Large percentage display (`XX.X%`) with embedded animated `StudyProgressBar`.
  2. *Countdown Card:* Target date countdown (`XX days left` or `Overdue!`).
  3. *Topic Stats Card:* Completed vs Total topics (`X / Y completed`, `Z remaining`).
- **Today's Focus Panel:** Auto-generated checklist of topics recommended for study today based on the required daily pace.
- **Phase Breakdown Cards:** Horizontal cards showing individual phase progress bars and completed topic ratios.

### 5.2 Roadmap Manager Layout (`roadmap_page.dart`)
- **Header:** Title + "New Roadmap" action button opening a dialog for roadmap creation.
- **Card Hierarchy:**
  - `_RoadmapCard`: Encapsulates a full roadmap. Displays title, description, actions dropdown (Edit, Delete, Add Phase), and collapsible phase list.
  - `_PhaseTile`: Inner expansion tile. Header shows phase title and order index with Phase Action buttons (Add Topic, Edit, Delete).
  - `_TopicTile`: Inner topic container. Contains completion checkbox, topic title, navigation shortcut to note, and Topic Action buttons (Add Subtopic, Edit, Delete).
  - `_SubtopicTile`: Indented checklist item with completion checkbox and delete button.

### 5.3 Goal Manager Layout (`goals_page.dart`)
- **No Goal State:** Clean empty state illustration with "Set Target Date" CTA.
- **Active Goal Hero Banner:**
  - Target Completion Date formatted nicely (`MMMM d, yyyy`).
  - Action buttons: "Change Date" (triggers calendar picker) and "Delete Goal".
- **Dynamic Pacing Cards:**
  - *Days Remaining Card:* Amber warning badge if deadline is near, green if ample time, red if overdue.
  - *Required Study Pace Card:* Calculates exactly how many topics must be completed per day (`X.XX topics / day`).
  - *Current Status Card:* Highlights completion ratio and on-track status.

### 5.4 Notes Workspace Layout (`notes_page.dart`)
- **Two-Column Split Screen:**
  - **Left Pane (280px):** `_TopicExplorer` grouped by Phase. Lists every topic with note indicators and active selection state.
  - **Right Pane:** The Markdown Workspace.
- **Workspace Header:**
  - Topic Title and breadcrumbs.
  - Auto-save Status Indicator: Live animated icon showing `Saving...` (amber spinner) during active typing and `Saved` (green checkmark) after the 500ms debounce completes.
  - Dual Mode Toggle Buttons: `[ Edit | Preview ]`.
- **Workspace Body:**
  - *Edit Mode:* Full-bleed borderless multiline text area styled with monospace typography.
  - *Preview Mode:* Formatted Markdown view rendering headers, lists, blockquotes, and styled code blocks (`#0F0F13` background with amber text).

### 5.5 Settings Layout (`settings_page.dart`)
- **Sections:**
  1. *Appearance:* Dark Theme switch toggle.
  2. *About StudyOS:* Structured key-value cards displaying Version (`1.0.0 (MVP)`), Database Engine (`SQLite 3.x`), Local Port (`127.0.0.1:8000`), and Platform (`Windows / Linux`).
  3. *Troubleshooting:* Destructive "Database Clean Reset" button with modal confirmation dialog.

---

## 6. Interaction Patterns

1. **Debounced Auto-Save:** In Notes, text changes do not trigger immediate network requests. A 500ms timer runs; if no key is pressed within 500ms, the PUT request is dispatched and the status icon transitions from `Saving...` to `Saved`.
2. **Immediate Checkbox Toggle:** Clicking a topic or subtopic checkbox triggers an immediate optimistic update followed by background network sync and cache invalidation.
3. **Modal Dialogs:** Add/Edit operations for Roadmaps, Phases, Topics, and Subtopics use Material 3 `AlertDialog` with autofocus on the primary input field.
4. **Context-Sensitive Empty States:** Each screen features an informative empty state providing guidance on what entity needs to be created first (e.g., "Please select or create a roadmap first to set goals").

---

## 7. Responsive Layout Expectations

- **Target Form Factor:** Desktop (Windows 10/11, Linux, macOS).
- **Minimum Supported Window Dimensions:** `1024 x 700 px`.
- **Layout Behavior:**
  - The left sidebar (`220px`) and notes explorer (`280px`) remain fixed-width.
  - The central content area flexes dynamically using `Expanded` and `SingleChildScrollView`.
  - Stat cards on Dashboard and Goals pages use flexible grid/row patterns that adapt smoothly to widescreen monitors (1440p, 4K).

---

## 8. Accessibility Considerations

1. **Color Contrast:** Text tokens `#F1F1F8` (Primary) and `#9494B0` (Secondary) against `#0F0F13` canvas satisfy WCAG AAA and AA contrast ratios (>7:1 and >4.5:1).
2. **Keyboard Focus:** TextFields across dialogs and notes support standard desktop keyboard navigation (`Tab`, `Enter`, `Ctrl+A`).
3. **Semantic Hierarchy:** Screen titles use standard `h1`/`h2` style tokens for visual structure.

---

## 9. Current UI Inconsistencies & Polish Tasks

During the design audit, the following UI gaps were discovered:
1. **Settings Theme Switch:** The toggle is rendered in `settings_page.dart:89` with `value: true`, but `onChanged` contains an empty comment (`// Switch functionality`).
2. **Settings Database Reset:** The "Reset All" confirmation dialog in `settings_page.dart:163` has an empty callback (`// DB clear triggers Navigator.pop(ctx);`).
3. **Dashboard Empty State CTA:** In `dashboard_page.dart:23`, `_EmptyState(onCreateRoadmap: () { // Navigate to roadmap page })` does not navigate to `/roadmap`.
4. **Deprecated Color API Warnings:** 8 usages of `.withOpacity(...)` in `dashboard_page.dart`, `goals_page.dart`, `roadmap_page.dart`, `settings_page.dart`, and `app_shell.dart` should be migrated to `.withValues(...)` as recommended by Flutter 3.27+.

---

## 10. Design Principles for Future Releases

1. **Maintain Pure Dark Palette Consistency:** Any future screens (e.g. Analytics, Calendar, Focus Mode) must strictly reuse `AppColors` and never introduce arbitrary ad-hoc hex codes.
2. **Keep Monospace Integrity for Code/Notes:** Any rich code viewing or Markdown rendering must preserve the established styling.
3. **Preserve Sub-process Calm:** Background tasks and auto-saves must never block the main thread or trigger jarring full-screen loading spinners.
