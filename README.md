# 🎓 StudyOS

StudyOS is a premium, local-first desktop learning management application designed to help self-learners organize study roadmaps, track daily progress, manage completion goals with dynamic pace calculations, and take context-rich Markdown notes—all stored securely on your local machine.

---

## ✨ Features

- **📊 Dynamic Dashboard:** Live overview of your overall and phase-by-phase progress, countdown timers, and an auto-suggested "Today's Focus" list based on your study pace.
- **🗺️ Roadmap Manager:** Create multiple custom roadmaps structured hierarchically into collapsible **Phases ➔ Topics ➔ Subtopics** with an interactive completion checklist.
- **🎯 Goal Manager:** Set target dates and let the app automatically calculate the exact pace (topics per day) and remaining days required to stay on track.
- **📝 Context-Linked Notes:** Write study notes directly linked to specific topics using a dual-mode Markdown Editor & Previewer featuring a 500ms debounced auto-save mechanism.
- **⚙️ Local & Offline-First:** Fast and secure data persistence using a local SQLite database in WAL (Write-Ahead Logging) mode. Completely offline—no internet required.

---

## 🛠️ Tech Stack

- **Frontend:** Flutter Desktop (Material 3 premium dark theme)
- **State Management:** Flutter Riverpod
- **Local Backend:** Python FastAPI (REST API on `localhost:8000`)
- **Database:** SQLite (SQLAlchemy ORM)
- **IPC:** HTTP over localhost (Spawns Python server as a subprocess on app launch)

---

## 🚀 Getting Started

### Prerequisites
- Python 3.10+
- Flutter SDK (stable channel)

### Installation & Run

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/studyos.git
   cd studyos
   ```

2. **Run Backend Server:**
   ```bash
   cd backend
   pip install -r requirements.txt
   python -m uvicorn main:app --host 127.0.0.1 --port 8000
   ```

3. **Run Frontend Application:**
   Open a new terminal window:
   ```bash
   cd frontend
   flutter pub get
   flutter run -d windows # Or 'flutter run -d chrome' for web-server
   ```
