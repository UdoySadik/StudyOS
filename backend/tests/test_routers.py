"""
StudyOS Backend — Automated Router Integration Tests
Tests all FastAPI CRUD endpoints, dynamic progress calculations, notes, and system reset.
"""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["version"] == "1.0.0"


def test_full_studyos_lifecycle():
    # 0. Clean reset to start from a deterministic baseline
    reset_res = client.post("/system/reset")
    assert reset_res.status_code == 200
    assert reset_res.json()["status"] == "reset_complete"

    # Verify roadmaps empty
    list_res = client.get("/roadmaps/")
    assert list_res.status_code == 200
    assert list_res.json() == []

    # 1. Create Roadmap
    rm_res = client.post("/roadmaps/", json={
        "title": "Systems Programming with Rust",
        "description": "Comprehensive low-level systems syllabus"
    })
    assert rm_res.status_code == 201
    roadmap = rm_res.json()
    roadmap_id = roadmap["id"]
    assert roadmap["title"] == "Systems Programming with Rust"

    # 2. Get Roadmap by ID
    get_rm_res = client.get(f"/roadmaps/{roadmap_id}")
    assert get_rm_res.status_code == 200
    assert get_rm_res.json()["id"] == roadmap_id

    # 3. Create Phase
    ph_res = client.post("/phases/", json={
        "roadmap_id": roadmap_id,
        "title": "Phase 1: Memory Safety & Ownership",
        "order_index": 1
    })
    assert ph_res.status_code == 201
    phase = ph_res.json()
    phase_id = phase["id"]
    assert phase["roadmap_id"] == roadmap_id

    # 4. Create Topics
    tp1_res = client.post("/topics/", json={
        "phase_id": phase_id,
        "title": "Topic 1: Stack vs Heap Allocation",
        "order_index": 1
    })
    assert tp1_res.status_code == 201
    topic1_id = tp1_res.json()["id"]

    tp2_res = client.post("/topics/", json={
        "phase_id": phase_id,
        "title": "Topic 2: Borrow Checker Rules",
        "order_index": 2
    })
    assert tp2_res.status_code == 201
    topic2_id = tp2_res.json()["id"]

    # 5. Create Subtopics
    sub_res = client.post("/subtopics/", json={
        "topic_id": topic1_id,
        "title": "Subtopic 1: Lifetime Annotations",
        "order_index": 1
    })
    assert sub_res.status_code == 201
    subtopic_id = sub_res.json()["id"]

    # Toggle subtopic completion
    sub_toggle = client.patch(f"/subtopics/{subtopic_id}", json={
        "is_completed": True
    })
    assert sub_toggle.status_code == 200
    assert sub_toggle.json()["is_completed"] is True

    # 6. Set Goal
    goal_res = client.post("/goals/", json={
        "roadmap_id": roadmap_id,
        "target_date": "2026-12-31"
    })
    assert goal_res.status_code == 201
    goal_id = goal_res.json()["id"]
    assert goal_res.json()["target_date"] == "2026-12-31"

    # 7. Check Dashboard Initial Progress (0% complete, 2 total)
    dash_res = client.get(f"/dashboard/{roadmap_id}")
    assert dash_res.status_code == 200
    dash_data = dash_res.json()
    assert dash_data["progress"]["total_topics"] == 2
    assert dash_data["progress"]["completed_topics"] == 0
    assert dash_data["progress"]["progress_percent"] == 0.0
    assert dash_data["current_topic"] == "Topic 1: Stack vs Heap Allocation"
    assert dash_data["goal"] is not None

    # 8. Mark Topic 1 Complete
    complete_res = client.patch(f"/topics/{topic1_id}/complete", json={
        "is_completed": True
    })
    assert complete_res.status_code == 200
    assert complete_res.json()["is_completed"] is True

    # 9. Verify Dashboard Dynamic Recalculation (50% complete)
    dash_updated = client.get(f"/dashboard/{roadmap_id}").json()
    assert dash_updated["progress"]["completed_topics"] == 1
    assert dash_updated["progress"]["remaining_topics"] == 1
    assert dash_updated["progress"]["progress_percent"] == 50.0
    assert dash_updated["current_topic"] == "Topic 2: Borrow Checker Rules"

    # 10. Notes Upsert & Markdown Fetch
    note_put = client.put(f"/notes/topic/{topic1_id}", json={
        "content": "# Rust Ownership\nMemory is freed when owner goes out of scope."
    })
    assert note_put.status_code == 200
    assert "Rust Ownership" in note_put.json()["content"]

    note_get = client.get(f"/notes/topic/{topic1_id}")
    assert note_get.status_code == 200
    assert note_get.json()["content"] == note_put.json()["content"]

    # 11. Delete Goal
    del_goal = client.delete(f"/goals/{goal_id}")
    assert del_goal.status_code == 204

    # 12. Final Clean Reset
    final_reset = client.post("/system/reset")
    assert final_reset.status_code == 200
    assert client.get("/roadmaps/").json() == []


def test_404_error_handling():
    # Non-existent roadmap
    assert client.get("/roadmaps/999999").status_code == 404
    # Non-existent phase
    assert client.get("/phases/999999").status_code == 404
    # Non-existent topic
    assert client.get("/topics/999999").status_code == 404
    # Non-existent note
    assert client.get("/notes/topic/999999").status_code == 404
    # Non-existent dashboard
    assert client.get("/dashboard/999999").status_code == 404


def test_search_endpoints():
    client.post("/system/reset")

    # Create roadmaps
    rm1 = client.post("/roadmaps/", json={"title": "Golang Microservices", "description": "Backend services"}).json()
    rm2 = client.post("/roadmaps/", json={"title": "Rust Systems", "description": "Embedded and kernels"}).json()

    # Search roadmaps
    search_rust = client.get("/roadmaps/?q=rust").json()
    assert len(search_rust) == 1
    assert search_rust[0]["id"] == rm2["id"]

    search_services = client.get("/roadmaps/?q=services").json()
    assert len(search_services) == 1
    assert search_services[0]["id"] == rm1["id"]

    # Create phase, topic and notes
    ph = client.post("/phases/", json={"roadmap_id": rm2["id"], "title": "Phase 1"}).json()
    tp = client.post("/topics/", json={"phase_id": ph["id"], "title": "Concurrency"}).json()
    client.put(f"/notes/topic/{tp['id']}", json={"content": "Mutex and Arc patterns for thread safety."})

    # Search notes
    notes_mutex = client.get("/notes/?q=mutex").json()
    assert len(notes_mutex) == 1
    assert "Mutex and Arc" in notes_mutex[0]["content"]

    notes_nonexistent = client.get("/notes/?q=nonexistentword123").json()
    assert len(notes_nonexistent) == 0

    client.post("/system/reset")


def test_schedule_endpoints():
    client.post("/system/reset")

    # 1. Create a roadmap & topic to link
    rm = client.post("/roadmaps/", json={"title": "Algorithms", "description": "DS & Algo"}).json()
    ph = client.post("/phases/", json={"roadmap_id": rm["id"], "title": "Phase 1"}).json()
    tp = client.post("/topics/", json={"phase_id": ph["id"], "title": "Graph Traversal"}).json()

    # 2. Create schedule block for today
    block_res = client.post("/schedule/", json={
        "scheduled_date": "2026-10-21",
        "start_time": "09:00",
        "end_time": "10:30",
        "title": "Study BFS & DFS",
        "topic_id": tp["id"],
        "notes": "Solve 3 LeetCode problems"
    })
    assert block_res.status_code == 201
    block = block_res.json()
    assert block["title"] == "Study BFS & DFS"
    assert block["is_completed"] is False
    block_id = block["id"]

    # 3. Create another schedule block for tomorrow
    client.post("/schedule/", json={
        "scheduled_date": "2026-10-22",
        "start_time": "14:00",
        "end_time": "15:30",
        "title": "Review Dynamic Programming"
    })

    # 4. Filter by date
    today_blocks = client.get("/schedule/?target_date=2026-10-21").json()
    assert len(today_blocks) == 1
    assert today_blocks[0]["id"] == block_id

    tomorrow_blocks = client.get("/schedule/?target_date=2026-10-22").json()
    assert len(tomorrow_blocks) == 1

    all_blocks = client.get("/schedule/").json()
    assert len(all_blocks) == 2

    # 5. Toggle completion
    comp_res = client.patch(f"/schedule/{block_id}/complete", json={"is_completed": True})
    assert comp_res.status_code == 200
    assert comp_res.json()["is_completed"] is True

    # 6. Update block
    update_res = client.patch(f"/schedule/{block_id}", json={"start_time": "09:30"})
    assert update_res.status_code == 200
    assert update_res.json()["start_time"] == "09:30"

    # 7. Delete block
    del_res = client.delete(f"/schedule/{block_id}")
    assert del_res.status_code == 204
    assert client.get(f"/schedule/{block_id}").status_code == 404

    # 8. Clean reset
    client.post("/system/reset")


def test_study_sessions_endpoints():
    client.post("/system/reset")

    # 1. Setup roadmap and topics
    rm = client.post("/roadmaps/", json={"title": "Rust Mastery", "description": "Systems"}).json()
    ph = client.post("/phases/", json={"roadmap_id": rm["id"], "title": "Ownership"}).json()
    tp1 = client.post("/topics/", json={"phase_id": ph["id"], "title": "Borrow Checker"}).json()
    tp2 = client.post("/topics/", json={"phase_id": ph["id"], "title": "Smart Pointers"}).json()

    # 2. Log sessions for Topic 1
    s1 = client.post("/study-sessions/", json={
        "topic_id": tp1["id"],
        "duration_seconds": 1800,  # 30 mins
        "notes": "Read chapters 4.1 to 4.3"
    })
    assert s1.status_code == 201
    s1_id = s1.json()["id"]
    assert s1.json()["duration_seconds"] == 1800

    s2 = client.post("/study-sessions/", json={
        "topic_id": tp1["id"],
        "duration_seconds": 1200,  # 20 mins
        "notes": "Exercised borrow errors"
    })
    assert s2.status_code == 201

    # Log session for Topic 2
    client.post("/study-sessions/", json={
        "topic_id": tp2["id"],
        "duration_seconds": 2400,  # 40 mins
        "notes": "Box and Rc pointers"
    })

    # 3. Check topic stats for Topic 1
    stats1 = client.get(f"/study-sessions/topic/{tp1['id']}").json()
    assert stats1["topic_id"] == tp1["id"]
    assert stats1["total_seconds"] == 3000  # 1800 + 1200
    assert stats1["session_count"] == 2

    # 4. Check study summary
    summary = client.get("/study-sessions/summary").json()
    assert summary["total_seconds_today"] == 5400  # 3000 + 2400
    assert summary["total_seconds_all_time"] == 5400
    assert summary["total_sessions_count"] == 3
    assert len(summary["topic_stats"]) == 2

    # 5. List with filter
    tp1_list = client.get(f"/study-sessions/?topic_id={tp1['id']}").json()
    assert len(tp1_list) == 2

    # 6. Delete a session
    del_res = client.delete(f"/study-sessions/{s1_id}")
    assert del_res.status_code == 204

    # Stats updated after delete
    stats_after = client.get(f"/study-sessions/topic/{tp1['id']}").json()
    assert stats_after["total_seconds"] == 1200
    assert stats_after["session_count"] == 1

    # 7. Invalid topic validation
    inv = client.post("/study-sessions/", json={"topic_id": 999999, "duration_seconds": 300})
    assert inv.status_code == 404

    client.post("/system/reset")


def test_calendar_endpoints():
    client.post("/system/reset")

    # 1. Setup roadmap and goal for October 2026
    rm = client.post("/roadmaps/", json={"title": "Cloud Computing", "description": "AWS & Kubernetes"}).json()
    client.post("/goals/", json={"roadmap_id": rm["id"], "target_date": "2026-10-25"})

    # 2. Setup phase, topic, and study session for October 2026
    ph = client.post("/phases/", json={"roadmap_id": rm["id"], "title": "Kubernetes"}).json()
    tp = client.post("/topics/", json={"phase_id": ph["id"], "title": "Pods & Services"}).json()
    client.post("/study-sessions/", json={
        "topic_id": tp["id"],
        "duration_seconds": 1800,
        "logged_date": "2026-10-22",
        "notes": "Configured Ingress controllers"
    })

    # 3. Setup schedule block for October 2026
    client.post("/schedule/", json={
        "scheduled_date": "2026-10-22",
        "start_time": "10:00",
        "end_time": "11:30",
        "title": "Study Deployments",
        "topic_id": tp["id"]
    })

    # 4. Fetch October 2026 events
    cal_oct = client.get("/calendar/events?year=2026&month=10").json()
    assert cal_oct["year"] == 2026
    assert cal_oct["month"] == 10
    assert len(cal_oct["goals"]) == 1
    assert cal_oct["goals"][0]["roadmap_title"] == "Cloud Computing"
    assert cal_oct["goals"][0]["target_date"] == "2026-10-25"
    assert len(cal_oct["schedule_blocks"]) == 1
    assert cal_oct["schedule_blocks"][0]["title"] == "Study Deployments"
    assert len(cal_oct["study_sessions"]) == 1
    assert cal_oct["study_sessions"][0]["topic_title"] == "Pods & Services"

    # 5. Fetch November 2026 events (should be empty)
    cal_nov = client.get("/calendar/events?year=2026&month=11").json()
    assert len(cal_nov["goals"]) == 0
    assert len(cal_nov["schedule_blocks"]) == 0
    assert len(cal_nov["study_sessions"]) == 0

    client.post("/system/reset")


def test_analytics_streak():
    from datetime import date, timedelta
    client.post("/system/reset")

    today = date.today()
    yesterday = today - timedelta(days=1)
    day_before = today - timedelta(days=2)

    # 1. Initially 0 streak
    res = client.get("/analytics/streak")
    assert res.status_code == 200
    data = res.json()
    assert data["current_streak"] == 0
    assert data["longest_streak"] == 0
    assert data["total_active_days"] == 0
    assert data["is_active_today"] is False
    assert len(data["weekly_consistency"]) == 7

    # 2. Setup roadmap & topic
    rm = client.post("/roadmaps/", json={"title": "ML & AI", "description": "Machine Learning"}).json()
    ph = client.post("/phases/", json={"roadmap_id": rm["id"], "title": "Math"}).json()
    tp = client.post("/topics/", json={"phase_id": ph["id"], "title": "Linear Algebra"}).json()

    # 3. Log study session for today
    client.post("/study-sessions/", json={
        "topic_id": tp["id"],
        "duration_seconds": 3600,
        "logged_date": today.isoformat(),
        "notes": "Eigenvalues"
    })

    res = client.get("/analytics/streak")
    data = res.json()
    assert data["current_streak"] == 1
    assert data["longest_streak"] == 1
    assert data["total_active_days"] == 1
    assert data["is_active_today"] is True

    # 4. Log study session for yesterday -> streak becomes 2
    client.post("/study-sessions/", json={
        "topic_id": tp["id"],
        "duration_seconds": 1800,
        "logged_date": yesterday.isoformat()
    })

    res = client.get("/analytics/streak")
    data = res.json()
    assert data["current_streak"] == 2
    assert data["longest_streak"] == 2
    assert data["total_active_days"] == 2

    # 5. Mark schedule block complete for day before yesterday -> streak becomes 3
    client.post("/schedule/", json={
        "scheduled_date": day_before.isoformat(),
        "start_time": "14:00",
        "end_time": "15:00",
        "title": "Matrix Multiplication",
        "is_completed": True
    })

    res = client.get("/analytics/streak")
    data = res.json()
    assert data["current_streak"] == 3
    assert data["longest_streak"] == 3
    assert data["total_active_days"] == 3

    # Check weekly consistency
    today_item = [d for d in data["weekly_consistency"] if d["is_today"]][0]
    assert today_item["is_active"] is True
    assert today_item["study_seconds"] == 3600

    client.post("/system/reset")


def test_burndown_velocity_endpoints():
    from datetime import date, timedelta
    client.post("/system/reset")

    today = date.today()
    target = today + timedelta(days=10)

    # 1. Create Roadmap, Phases, and Topics
    rm = client.post("/roadmaps/", json={"title": "Rust Engineering", "description": "Systems"}).json()
    rm_id = rm["id"]

    p1 = client.post("/phases/", json={"roadmap_id": rm_id, "title": "Basics"}).json()
    p2 = client.post("/phases/", json={"roadmap_id": rm_id, "title": "Advanced"}).json()

    t1 = client.post("/topics/", json={"phase_id": p1["id"], "title": "Borrowing"}).json()
    t2 = client.post("/topics/", json={"phase_id": p1["id"], "title": "Lifetimes"}).json()
    t3 = client.post("/topics/", json={"phase_id": p2["id"], "title": "Async"}).json()
    t4 = client.post("/topics/", json={"phase_id": p2["id"], "title": "Macros"}).json()

    # 2. Complete topic 1
    client.patch(f"/topics/{t1['id']}/complete", json={"is_completed": True})

    # 3. Create Goal
    client.post("/goals/", json={"roadmap_id": rm_id, "target_date": target.isoformat()})

    # 4. Fetch burndown & velocity
    res = client.get(f"/analytics/burndown/{rm_id}")
    assert res.status_code == 200
    data = res.json()

    assert data["roadmap_id"] == rm_id
    assert data["total_topics"] == 4
    assert data["completed_topics"] == 1
    assert data["remaining_topics"] == 3
    assert data["progress_percent"] == 25.0
    assert data["target_date"] == target.isoformat()
    assert data["days_remaining"] == 10
    assert data["required_velocity"] == 0.3  # 3 remaining / 10 days
    assert len(data["phases"]) == 2
    assert data["phases"][0]["phase_title"] == "Basics"
    assert data["phases"][0]["completed_topics"] == 1
    assert data["phases"][0]["remaining_topics"] == 1
    assert data["phases"][1]["phase_title"] == "Advanced"
    assert data["phases"][1]["completed_topics"] == 0
    assert data["phases"][1]["remaining_topics"] == 2
    assert len(data["recent_velocity"]) == 7

    # 5. Non-existent roadmap returns 404
    assert client.get("/analytics/burndown/99999").status_code == 404

    client.post("/system/reset")


def test_monthly_study_hours_endpoints():
    import calendar
    from datetime import date
    client.post("/system/reset")

    today = date.today()
    cur_year = today.year
    cur_month = today.month
    _, num_days = calendar.monthrange(cur_year, cur_month)

    # 1. Empty state
    res = client.get(f"/analytics/study-hours?year={cur_year}&month={cur_month}")
    assert res.status_code == 200
    data = res.json()
    assert data["year"] == cur_year
    assert data["month"] == cur_month
    assert data["total_seconds"] == 0
    assert data["total_hours"] == 0.0
    assert data["total_sessions"] == 0
    assert data["active_days_count"] == 0
    assert data["total_days_in_month"] == num_days
    assert len(data["daily_distribution"]) == num_days
    assert len(data["weekday_distribution"]) == 7
    assert len(data["topic_distribution"]) == 0

    # 2. Setup Roadmap, Phase, and 2 Topics
    rm = client.post("/roadmaps/", json={"title": "Distributed Systems", "description": "Raft"}).json()
    rm_id = rm["id"]
    ph = client.post("/phases/", json={"roadmap_id": rm_id, "title": "Consensus"}).json()
    t1 = client.post("/topics/", json={"phase_id": ph["id"], "title": "Raft Leader Election"}).json()
    t2 = client.post("/topics/", json={"phase_id": ph["id"], "title": "Log Replication"}).json()

    # 3. Log sessions on 2 specific dates in current month
    d1 = date(cur_year, cur_month, min(5, num_days))
    d2 = date(cur_year, cur_month, min(12, num_days))

    # Session 1: Topic 1, 3600s on d1
    client.post("/study-sessions/", json={
        "topic_id": t1["id"],
        "duration_seconds": 3600,
        "logged_date": d1.isoformat(),
        "notes": "Elections logic"
    })
    # Session 2: Topic 1, 1800s on d1
    client.post("/study-sessions/", json={
        "topic_id": t1["id"],
        "duration_seconds": 1800,
        "logged_date": d1.isoformat(),
        "notes": "Split vote cases"
    })
    # Session 3: Topic 2, 5400s on d2
    client.post("/study-sessions/", json={
        "topic_id": t2["id"],
        "duration_seconds": 5400,
        "logged_date": d2.isoformat(),
        "notes": "RPC commit index"
    })

    # 4. Fetch monthly analytics
    res = client.get(f"/analytics/study-hours?year={cur_year}&month={cur_month}")
    assert res.status_code == 200
    data = res.json()

    assert data["total_seconds"] == 10800
    assert data["total_hours"] == 3.0
    assert data["total_sessions"] == 3
    assert data["active_days_count"] == 2
    assert data["daily_average_hours"] == 1.5
    assert data["peak_day_hours"] == 1.5
    assert len(data["topic_distribution"]) == 2
    assert data["topic_distribution"][0]["study_seconds"] == 5400
    assert data["topic_distribution"][0]["percentage"] == 50.0

    # 5. Filter by roadmap_id
    res_filtered = client.get(f"/analytics/study-hours?year={cur_year}&month={cur_month}&roadmap_id={rm_id}")
    assert res_filtered.status_code == 200
    assert res_filtered.json()["total_seconds"] == 10800

    # 6. Error handling
    assert client.get("/analytics/study-hours?month=13").status_code == 400
    assert client.get("/analytics/study-hours?roadmap_id=99999").status_code == 404

    client.post("/system/reset")







