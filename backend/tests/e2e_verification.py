"""
StudyOS — Live End-to-End (E2E) Subprocess Verification Script
Launches live Uvicorn server, executes complete user workflows, tests persistence across server restarts,
verifies SQLite WAL integrity, and performs clean shutdown.
"""

import subprocess
import time
import sys
import os
import requests
from datetime import date, timedelta

BASE_URL = "http://127.0.0.1:8000"
BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def wait_for_server(timeout=15):
    """Wait until backend server responds to /health."""
    start = time.time()
    while time.time() - start < timeout:
        try:
            r = requests.get(f"{BASE_URL}/health", timeout=1)
            if r.status_code == 200 and r.json().get("status") == "ok":
                return True
        except requests.exceptions.RequestException:
            pass
        time.sleep(0.5)
    return False


def run_e2e():
    print("=" * 60)
    print("STUDYOS END-TO-END VERIFICATION")
    print("=" * 60)

    # -------------------------------------------------------------
    # Step 1: Boot Live Uvicorn Server Subprocess
    # -------------------------------------------------------------
    print("\n[Step 1] Launching Python Uvicorn subprocess on 127.0.0.1:8000...")
    proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000"],
        cwd=BACKEND_DIR,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    try:
        assert wait_for_server(), "Server failed to start within timeout"
        print("  -> Server is alive and responding on http://127.0.0.1:8000")

        # -------------------------------------------------------------
        # Step 2: System Reset (Clean Baseline)
        # -------------------------------------------------------------
        print("\n[Step 2] Executing System Clean Reset (POST /system/reset)...")
        r = requests.post(f"{BASE_URL}/system/reset")
        assert r.status_code == 200, f"Reset failed: {r.text}"
        assert r.json()["status"] == "reset_complete"
        print("  -> Database tables dropped and re-initialized cleanly.")

        # -------------------------------------------------------------
        # Step 3: Journey 1 — Create Roadmap & Hierarchy
        # -------------------------------------------------------------
        print("\n[Step 3] Journey 1 — Creating Roadmap, Phase, Topics, and Subtopic...")
        r = requests.post(f"{BASE_URL}/roadmaps/", json={
            "title": "Computer Systems & Architecture",
            "description": "Hardware, memory hierarchy, and operating system principles"
        })
        assert r.status_code == 201
        roadmap = r.json()
        rm_id = roadmap["id"]
        print(f"  -> Created Roadmap: '{roadmap['title']}' (ID: {rm_id})")

        # Create Phase
        r = requests.post(f"{BASE_URL}/phases/", json={
            "roadmap_id": rm_id,
            "title": "Phase 1: Processor Fundamentals",
            "order_index": 1
        })
        assert r.status_code == 201
        phase_id = r.json()["id"]
        print(f"  -> Created Phase: 'Phase 1: Processor Fundamentals' (ID: {phase_id})")

        # Create Topic 1
        r = requests.post(f"{BASE_URL}/topics/", json={
            "phase_id": phase_id,
            "title": "Topic 1.1: CPU Registers and ALU",
            "order_index": 1
        })
        assert r.status_code == 201
        topic1_id = r.json()["id"]

        # Create Topic 2
        r = requests.post(f"{BASE_URL}/topics/", json={
            "phase_id": phase_id,
            "title": "Topic 1.2: Memory Hierarchy & Caching",
            "order_index": 2
        })
        assert r.status_code == 201
        topic2_id = r.json()["id"]
        print(f"  -> Created Topics: ID {topic1_id} and ID {topic2_id}")

        # Create Subtopic under Topic 1.2
        r = requests.post(f"{BASE_URL}/subtopics/", json={
            "topic_id": topic2_id,
            "title": "L1/L2/L3 Cache Timing and Latencies",
            "order_index": 1
        })
        assert r.status_code == 201
        subtopic_id = r.json()["id"]
        print(f"  -> Created Subtopic: ID {subtopic_id}")

        # -------------------------------------------------------------
        # Step 4: Journey 2 — Goal Setting & Pacing Calculation
        # -------------------------------------------------------------
        print("\n[Step 4] Journey 2 — Setting Target Date and Verifying Pace...")
        target_str = (date.today() + timedelta(days=20)).isoformat()
        r = requests.post(f"{BASE_URL}/goals/", json={
            "roadmap_id": rm_id,
            "target_date": target_str
        })
        assert r.status_code == 201
        goal = r.json()
        print(f"  -> Set Target Date: {goal['target_date']}")

        # Fetch Dashboard Summary
        r = requests.get(f"{BASE_URL}/dashboard/{rm_id}")
        assert r.status_code == 200
        dash = r.json()
        assert dash["progress"]["total_topics"] == 2
        assert dash["progress"]["completed_topics"] == 0
        assert dash["progress"]["remaining_topics"] == 2
        assert dash["progress"]["progress_percent"] == 0.0
        assert dash["goal"]["days_remaining"] == 20
        assert dash["goal"]["topics_per_day_needed"] == 0.1  # 2 / 20 = 0.1
        assert dash["current_topic"] == "Topic 1.1: CPU Registers and ALU"
        print(f"  -> Dashboard Verified: 0.0% complete, 20 days left, pace: {dash['goal']['topics_per_day_needed']} topics/day")

        # -------------------------------------------------------------
        # Step 5: Journey 3 — Note-Taking & Autosave Simulation
        # -------------------------------------------------------------
        print("\n[Step 5] Journey 3 — Saving & Fetching Context Markdown Notes...")
        markdown_body = """# CPU Registers & ALU Notes
- Registers operate at clock speeds (<1ns).
- General-purpose registers: RAX, RBX, RCX, RDX.
```c
int a = 10;
int b = 20;
```
"""
        r = requests.put(f"{BASE_URL}/notes/topic/{topic1_id}", json={
            "content": markdown_body
        })
        assert r.status_code == 200
        saved_note = r.json()
        assert saved_note["content"] == markdown_body
        print("  -> Markdown note upserted and saved successfully.")

        # Fetch note
        r = requests.get(f"{BASE_URL}/notes/topic/{topic1_id}")
        assert r.status_code == 200
        assert r.json()["content"] == markdown_body
        print("  -> Note fetched and verified matching identical Markdown.")

        # -------------------------------------------------------------
        # Step 6: Journey 4 — Complete Topic & Verify Dynamic Progress
        # -------------------------------------------------------------
        print("\n[Step 6] Journey 4 — Toggling Topic Completion & Checking Live Recalculation...")
        r = requests.patch(f"{BASE_URL}/topics/{topic1_id}/complete", json={
            "is_completed": True
        })
        assert r.status_code == 200
        assert r.json()["is_completed"] is True
        print(f"  -> Topic {topic1_id} marked completed.")

        # Dashboard recalculation
        r = requests.get(f"{BASE_URL}/dashboard/{rm_id}")
        assert r.status_code == 200
        dash_after = r.json()
        assert dash_after["progress"]["completed_topics"] == 1
        assert dash_after["progress"]["remaining_topics"] == 1
        assert dash_after["progress"]["progress_percent"] == 50.0
        assert dash_after["current_topic"] == "Topic 1.2: Memory Hierarchy & Caching"
        print(f"  -> Progress dynamically recalculated to exactly {dash_after['progress']['progress_percent']}%!")

        # -------------------------------------------------------------
        # Step 7: Journey 5 — Persistence Across Server Restart
        # -------------------------------------------------------------
        print("\n[Step 7] Journey 5 — Simulating Server Restart to Verify SQLite WAL Persistence...")
        # Terminate server 1
        proc.terminate()
        proc.wait(timeout=5)
        print("  -> Process 1 terminated.")

        # Launch server 2 against existing data/studyos.db
        print("  -> Launching Process 2 against existing SQLite file...")
        proc2 = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000"],
            cwd=BACKEND_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        try:
            assert wait_for_server(), "Server 2 failed to start within timeout"
            print("  -> Server 2 is alive.")

            # Verify persisted data
            r = requests.get(f"{BASE_URL}/dashboard/{rm_id}")
            assert r.status_code == 200, "Failed to load dashboard after restart"
            dash_reboot = r.json()
            assert dash_reboot["progress"]["progress_percent"] == 50.0
            assert dash_reboot["progress"]["completed_topics"] == 1
            print("  -> Dashboard progress survived server restart intact (50.0%).")

            # Verify persisted notes
            r = requests.get(f"{BASE_URL}/notes/topic/{topic1_id}")
            assert r.status_code == 200
            assert r.json()["content"] == markdown_body
            print("  -> Markdown notes survived server restart intact.")

        finally:
            proc2.terminate()
            proc2.wait(timeout=5)
            print("  -> Process 2 terminated cleanly.")

    finally:
        if proc.poll() is None:
            proc.terminate()
            proc.wait(timeout=5)

    print("\n" + "=" * 60)
    print("ALL LIVE END-TO-END WORKFLOW VERIFICATIONS PASSED (100%)!")
    print("=" * 60)


if __name__ == "__main__":
    run_e2e()
