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


def test_resource_endpoints():
    client.post("/system/reset")

    # 1. Setup hierarchy
    rm = client.post("/roadmaps/", json={"title": "Cloud Systems", "description": "Cloud native"}).json()
    ph = client.post("/phases/", json={"roadmap_id": rm["id"], "title": "Storage"}).json()
    tp = client.post("/topics/", json={"phase_id": ph["id"], "title": "Distributed File Systems"}).json()
    tp_id = tp["id"]

    # 2. Empty list
    res = client.get(f"/resources/topic/{tp_id}")
    assert res.status_code == 200
    assert res.json() == []

    # 3. Create Resource 1: Book
    r1 = client.post("/resources/", json={
        "topic_id": tp_id,
        "title": "Designing Data-Intensive Applications",
        "resource_type": "book",
        "url": "https://dataintensive.net",
        "notes": "Chapters 5-7 on Replication"
    }).json()
    assert r1["id"] is not None
    assert r1["title"] == "Designing Data-Intensive Applications"
    assert r1["resource_type"] == "book"
    assert r1["is_completed"] is False

    # 4. Create Resource 2: Video
    r2 = client.post("/resources/", json={
        "topic_id": tp_id,
        "title": "MIT 6.824 GFS Lecture",
        "resource_type": "video",
        "url": "https://youtube.com/watch?v=ep4E0h_BnhA",
        "notes": "Master architecture"
    }).json()
    assert r2["id"] is not None
    assert r2["resource_type"] == "video"

    # 5. List resources
    res_list = client.get(f"/resources/topic/{tp_id}").json()
    assert len(res_list) == 2

    # 6. Get single resource
    res_single = client.get(f"/resources/{r1['id']}")
    assert res_single.status_code == 200
    assert res_single.json()["title"] == "Designing Data-Intensive Applications"

    # 7. Update resource
    res_updated = client.patch(f"/resources/{r1['id']}", json={
        "title": "DDIA (O'Reilly)",
        "notes": "Finished part 1"
    }).json()
    assert res_updated["title"] == "DDIA (O'Reilly)"
    assert res_updated["notes"] == "Finished part 1"

    # 8. Toggle complete
    res_completed = client.patch(f"/resources/{r1['id']}/complete", json={"is_completed": True}).json()
    assert res_completed["is_completed"] is True

    # 9. Delete resource
    del_res = client.delete(f"/resources/{r2['id']}")
    assert del_res.status_code == 204

    # 10. Verify deleted
    assert client.get(f"/resources/{r2['id']}").status_code == 404
    assert len(client.get(f"/resources/topic/{tp_id}").json()) == 1

    # 11. Error handling: non-existent topic or resource
    assert client.get("/resources/topic/99999").status_code == 404
    assert client.post("/resources/", json={"topic_id": 99999, "title": "Missing"}).status_code == 404
    assert client.patch("/resources/99999", json={"title": "Missing"}).status_code == 404
    assert client.delete("/resources/99999").status_code == 404

    client.post("/system/reset")


def test_project_endpoints():
    # 0. Clean reset
    client.post("/system/reset")

    # 1. Setup roadmap, phase, topic
    rm = client.post("/roadmaps/", json={"title": "Full Stack Mastery"}).json()
    rm_id = rm["id"]

    ph = client.post("/phases/", json={"roadmap_id": rm_id, "title": "Phase 1: Backend", "order_index": 1}).json()
    ph_id = ph["id"]

    tp = client.post("/topics/", json={"phase_id": ph_id, "title": "FastAPI & Distributed Systems", "order_index": 1}).json()
    tp_id = tp["id"]

    # 2. Create Project 1: Complete fields
    p1 = client.post("/projects/", json={
        "roadmap_id": rm_id,
        "topic_id": tp_id,
        "title": "StudyOS Realtime Engine",
        "description": "High performance async event processing server",
        "github_url": "https://github.com/studyos/engine",
        "live_url": "https://engine.studyos.dev",
        "difficulty": "advanced",
        "tech_stack": "Python, FastAPI, Redis, Docker",
        "status": "in_progress"
    }).json()

    assert p1["id"] is not None
    assert p1["title"] == "StudyOS Realtime Engine"
    assert p1["roadmap_title"] == "Full Stack Mastery"
    assert p1["topic_title"] == "FastAPI & Distributed Systems"
    assert p1["status"] == "in_progress"
    assert p1["difficulty"] == "advanced"
    assert p1["tech_stack"] == "Python, FastAPI, Redis, Docker"
    assert p1["completed_at"] is None

    # 3. Create Project 2: Optional fields omitted
    p2 = client.post("/projects/", json={
        "roadmap_id": rm_id,
        "title": "CLI Habit Tracker",
        "difficulty": "beginner",
        "tech_stack": "Rust"
    }).json()

    assert p2["id"] is not None
    assert p2["title"] == "CLI Habit Tracker"
    assert p2["status"] == "not_started"
    assert p2["topic_id"] is None
    assert p2["github_url"] is None

    # 4. List all projects
    all_proj = client.get("/projects/").json()
    assert len(all_proj) == 2

    # 5. Filter by roadmap_id
    rm_proj = client.get(f"/projects/?roadmap_id={rm_id}").json()
    assert len(rm_proj) == 2

    # 6. Filter by topic_id
    tp_proj = client.get(f"/projects/?topic_id={tp_id}").json()
    assert len(tp_proj) == 1
    assert tp_proj[0]["id"] == p1["id"]

    # 7. Filter by status
    in_prog = client.get("/projects/?status=in_progress").json()
    assert len(in_prog) == 1
    assert in_prog[0]["id"] == p1["id"]

    # 8. Get single project
    p1_get = client.get(f"/projects/{p1['id']}")
    assert p1_get.status_code == 200
    assert p1_get.json()["title"] == "StudyOS Realtime Engine"

    # 9. Update project fields
    p1_updated = client.patch(f"/projects/{p1['id']}", json={
        "title": "StudyOS Distributed Engine",
        "tech_stack": "Python, Rust, FastAPI"
    }).json()
    assert p1_updated["title"] == "StudyOS Distributed Engine"
    assert p1_updated["tech_stack"] == "Python, Rust, FastAPI"

    # 10. Update status to completed -> completed_at set
    p1_completed = client.patch(f"/projects/{p1['id']}/status", json={"status": "completed"}).json()
    assert p1_completed["status"] == "completed"
    assert p1_completed["completed_at"] is not None

    # 11. Update status back to in_progress -> completed_at cleared
    p1_reopened = client.patch(f"/projects/{p1['id']}/status", json={"status": "in_progress"}).json()
    assert p1_reopened["status"] == "in_progress"
    assert p1_reopened["completed_at"] is None

    # 12. Delete project
    del_res = client.delete(f"/projects/{p2['id']}")
    assert del_res.status_code == 204
    assert client.get(f"/projects/{p2['id']}").status_code == 404
    assert len(client.get("/projects/").json()) == 1

    # 13. Validation error cases
    # Invalid status in create
    assert client.post("/projects/", json={"roadmap_id": rm_id, "title": "Bad", "status": "invalid_status"}).status_code == 400
    # Invalid difficulty in create
    assert client.post("/projects/", json={"roadmap_id": rm_id, "title": "Bad", "difficulty": "super_hard"}).status_code == 400
    # Non-existent roadmap
    assert client.post("/projects/", json={"roadmap_id": 99999, "title": "Bad"}).status_code == 404
    # Non-existent topic
    assert client.post("/projects/", json={"roadmap_id": rm_id, "topic_id": 99999, "title": "Bad"}).status_code == 404
    # Status update invalid status
    assert client.patch(f"/projects/{p1['id']}/status", json={"status": "bogus"}).status_code == 400
    # 404 for non-existent project
    assert client.get("/projects/99999").status_code == 404
    assert client.patch("/projects/99999", json={"title": "Missing"}).status_code == 404
    assert client.delete("/projects/99999").status_code == 404

    # Cleanup
    client.post("/system/reset")


def test_ai_planner_endpoints():
    # 0. Clean reset
    client.post("/system/reset")

    # 1. Ollama status check
    status_res = client.get("/ai/ollama/status")
    assert status_res.status_code == 200
    status_data = status_res.json()
    assert "connected" in status_data
    assert "endpoint" in status_data
    assert "models" in status_data

    # 2. Validation error on empty subject
    assert client.post("/ai/plans/generate", json={"subject": "   "}).status_code == 400

    # 3. Generate Study Plan (runs built-in offline generator if Ollama is not running)
    gen_res = client.post("/ai/plans/generate", json={
        "subject": "Distributed Systems with Raft",
        "proficiency": "advanced",
        "hours_per_week": 15,
        "target_weeks": 4,
        "focus_area": "Consensus, Replication & Benchmarking",
        "custom_instructions": "Focus on fault tolerance and network partitions",
    })
    assert gen_res.status_code == 201
    plan = gen_res.json()
    plan_id = plan["id"]
    assert plan["subject"] == "Distributed Systems with Raft"
    assert plan["proficiency"] == "advanced"
    assert plan["hours_per_week"] == 15
    assert plan["target_weeks"] == 4
    assert len(plan["plan_markdown"]) > 100
    assert plan["structured_data"] is not None
    assert len(plan["structured_data"]["phases"]) >= 2
    assert plan["roadmap_id"] is None

    # 4. List plans
    plans_list = client.get("/ai/plans/").json()
    assert len(plans_list) == 1
    assert plans_list[0]["id"] == plan_id

    # 5. Get plan by ID
    single_plan = client.get(f"/ai/plans/{plan_id}")
    assert single_plan.status_code == 200
    assert single_plan.json()["id"] == plan_id

    # 6. Import Plan as Active Roadmap
    import_res = client.post(f"/ai/plans/{plan_id}/import-roadmap")
    assert import_res.status_code == 201
    import_data = import_res.json()
    roadmap_id = import_data["roadmap_id"]
    assert import_data["phases_created"] >= 2
    assert import_data["topics_created"] >= 4

    # Verify roadmap exists in database
    rm_res = client.get(f"/roadmaps/{roadmap_id}")
    assert rm_res.status_code == 200
    assert "Distributed Systems with Raft" in rm_res.json()["title"]

    # Verify practice projects auto-created and linked
    proj_res = client.get(f"/projects/?roadmap_id={roadmap_id}")
    assert proj_res.status_code == 200
    assert len(proj_res.json()) >= 1

    # Verify plan now references the created roadmap
    updated_plan = client.get(f"/ai/plans/{plan_id}").json()
    assert updated_plan["roadmap_id"] == roadmap_id
    assert updated_plan["roadmap_title"] is not None

    # 7. Delete plan
    del_res = client.delete(f"/ai/plans/{plan_id}")
    assert del_res.status_code == 204
    assert client.get(f"/ai/plans/{plan_id}").status_code == 404

    # 8. Error cases: 404 for missing plan
    assert client.get("/ai/plans/99999").status_code == 404
    assert client.delete("/ai/plans/99999").status_code == 404
    assert client.post("/ai/plans/99999/import-roadmap").status_code == 404

    # Cleanup
    client.post("/system/reset")


def test_study_recall_endpoints():
    # 0. Clean reset
    client.post("/system/reset")

    # 1. Setup Roadmap, Phase, Topic, Note
    rm = client.post("/roadmaps/", json={"title": "Distributed Systems"}).json()
    rm_id = rm["id"]

    ph = client.post("/phases/", json={"roadmap_id": rm_id, "title": "Consensus", "order_index": 1}).json()
    ph_id = ph["id"]

    tp = client.post("/topics/", json={"phase_id": ph_id, "title": "Raft Protocol & Log Replication", "order_index": 1}).json()
    tp_id = tp["id"]

    note_text = (
        "# Raft Protocol Overview\n\n"
        "- **Leader Election**: State machine transition when heartbeat timeout expires\n"
        "- **Log Replication**: Two-phase append entries accepted by majority quorum\n"
        "- **Term Counter**: Monotonically increasing logical clock\n"
        "- **Commit Index**: Index of highest log entry known to be committed\n\n"
        "## Key Invariants\n"
        "- Election Safety: At most one leader can be elected in a given term\n"
        "- Leader Append-Only: A leader never overwrites or truncates its log\n"
    )

    client.put(f"/notes/{tp_id}", json={"content": note_text})

    # 2. Validation error: empty payload
    assert client.post("/recall/generate", json={}).status_code == 400

    # 3. Generate flashcards and quiz from topic note
    gen_res = client.post("/recall/generate", json={
        "topic_id": tp_id,
        "count": 4,
        "generate_flashcards": True,
        "generate_quiz": True,
    })
    assert gen_res.status_code == 201
    gen_data = gen_res.json()
    assert gen_data["generated_cards_count"] >= 3
    assert gen_data["generated_questions_count"] >= 3
    assert gen_data["deck"] is not None
    assert gen_data["quiz"] is not None

    deck_id = gen_data["deck"]["id"]
    quiz_id = gen_data["quiz"]["id"]
    assert gen_data["deck"]["topic_title"] == "Raft Protocol & Log Replication"
    assert gen_data["quiz"]["topic_title"] == "Raft Protocol & Log Replication"

    # 4. List decks
    decks_list = client.get("/recall/decks/").json()
    assert len(decks_list) == 1
    assert decks_list[0]["id"] == deck_id

    # Filter decks by topic_id
    filtered_decks = client.get(f"/recall/decks/?topic_id={tp_id}").json()
    assert len(filtered_decks) == 1

    # 5. Get deck by ID
    single_deck = client.get(f"/recall/decks/{deck_id}").json()
    assert single_deck["id"] == deck_id
    assert len(single_deck["cards"]) >= 3
    card_id = single_deck["cards"][0]["id"]

    # 6. Add card to deck
    new_card_res = client.post(f"/recall/decks/{deck_id}/cards", json={
        "front": "What is Joint Consensus?",
        "back": "Configuration change transition state during cluster membership reconfiguration",
    })
    assert new_card_res.status_code == 201
    assert new_card_res.json()["front"] == "What is Joint Consensus?"

    # 7. Toggle card mastery
    mastery_res = client.patch(f"/recall/cards/{card_id}/mastery?is_mastered=true")
    assert mastery_res.status_code == 200
    assert mastery_res.json()["is_mastered"] is True
    assert mastery_res.json()["review_count"] == 1

    # Verify deck mastered_cards count reflects change
    updated_deck = client.get(f"/recall/decks/{deck_id}").json()
    assert updated_deck["mastered_cards"] == 1

    # 8. Delete card
    del_card = client.delete(f"/recall/cards/{card_id}")
    assert del_card.status_code == 204

    # 9. List quizzes
    quizzes_list = client.get("/recall/quizzes/").json()
    assert len(quizzes_list) == 1
    assert quizzes_list[0]["id"] == quiz_id

    # 10. Get single quiz
    single_quiz = client.get(f"/recall/quizzes/{quiz_id}").json()
    assert single_quiz["id"] == quiz_id
    assert len(single_quiz["questions"]) >= 3
    first_q = single_quiz["questions"][0]
    assert len(first_q["options"]) == 4
    assert 0 <= first_q["correct_index"] <= 3

    # 11. Add question to quiz
    add_q_res = client.post(f"/recall/quizzes/{quiz_id}/questions", json={
        "question": "What happens if candidate split-vote occurs?",
        "options": ["Election times out and new term begins", "System halts", "Random node chosen", "Leader resets term"],
        "correct_index": 0,
        "explanation": "Randomized election timeouts resolve split votes by breaking symmetry",
    })
    assert add_q_res.status_code == 201
    q_id = add_q_res.json()["id"]

    # 12. Delete question
    assert client.delete(f"/recall/questions/{q_id}").status_code == 204

    # 13. Create manual deck and quiz
    custom_deck = client.post("/recall/decks/", json={
        "title": "Custom Algorithm Deck",
        "cards": [{"front": "Front 1", "back": "Back 1"}],
    }).json()
    assert custom_deck["id"] is not None
    assert custom_deck["total_cards"] == 1

    # 14. Delete deck and quiz
    assert client.delete(f"/recall/decks/{deck_id}").status_code == 204
    assert client.get(f"/recall/decks/{deck_id}").status_code == 404
    assert client.delete(f"/recall/quizzes/{quiz_id}").status_code == 204
    assert client.get(f"/recall/quizzes/{quiz_id}").status_code == 404

    # 15. 404 error cases
    assert client.get("/recall/decks/99999").status_code == 404
    assert client.get("/recall/quizzes/99999").status_code == 404
    assert client.delete("/recall/cards/99999").status_code == 404
    assert client.delete("/recall/questions/99999").status_code == 404

    # Cleanup
    client.post("/system/reset")


def test_note_ai_endpoints():
    client.post("/system/reset")

    # 1. Summarize with direct markdown note content (Key Takeaways style)
    note_text = (
        "# Distributed Systems and Consensus\n\n"
        "**Raft Protocol**: A consensus algorithm designed to be easy to understand.\n"
        "**Leader Election**: Randomized election timeouts avoid split-votes between candidates.\n"
        "**Log Replication**: Leaders accept entries from clients and replicate them to followers.\n"
        "Safety is guaranteed through state machine safety and leader completeness.\n"
        "Network partitions are handled gracefully by majority quorum voting.\n"
    )

    res_takeaways = client.post("/note-ai/summarize", json={
        "note_content": note_text,
        "summary_style": "key_takeaways",
        "max_bullets": 4,
    })
    assert res_takeaways.status_code == 200
    data_t = res_takeaways.json()
    assert "### 💡 Key Takeaways" in data_t["summary_markdown"]
    assert len(data_t["key_takeaways"]) > 0
    assert data_t["word_count"] > 10
    assert data_t["reading_time_minutes"] >= 0.1
    assert data_t["model_used"] in ["builtin-offline"] or data_t["model_used"].startswith("ollama:")

    # 2. Summarize with Executive style
    res_exec = client.post("/note-ai/summarize", json={
        "note_content": note_text,
        "summary_style": "executive",
        "max_bullets": 3,
    })
    assert res_exec.status_code == 200
    assert "Executive Summary" in res_exec.json()["summary_markdown"]

    # 3. Summarize with Bullet Points style
    res_bullets = client.post("/note-ai/summarize", json={
        "note_content": note_text,
        "summary_style": "bullet_points",
        "max_bullets": 3,
    })
    assert res_bullets.status_code == 200
    assert "Key Points Summary" in res_bullets.json()["summary_markdown"]

    # 4. Summarize with Cheat Sheet style
    res_cheat = client.post("/note-ai/summarize", json={
        "note_content": note_text,
        "summary_style": "cheat_sheet",
        "max_bullets": 3,
    })
    assert res_cheat.status_code == 200
    assert "Cheat Sheet" in res_cheat.json()["summary_markdown"]
    assert "|" in res_cheat.json()["summary_markdown"]

    # 5. Summarize via topic_id (DB retrieval)
    rm = client.post("/roadmaps/", json={"title": "Systems", "description": "OS"}).json()
    ph = client.post("/phases/", json={"roadmap_id": rm["id"], "title": "Kernel"}).json()
    tp = client.post("/topics/", json={"phase_id": ph["id"], "title": "Memory Paging"}).json()
    tp_id = tp["id"]

    # Before note exists -> 400
    err_res = client.post("/note-ai/summarize", json={"topic_id": tp_id})
    assert err_res.status_code == 400

    # Create note for topic
    client.put(f"/notes/topic/{tp_id}", json={
        "content": (
            "# Virtual Memory & Paging\n\n"
            "**Page Table**: Translates virtual addresses to physical frame addresses.\n"
            "**TLB**: Translation Lookaside Buffer caches recent translations.\n"
            "Page faults occur when requested page is not present in physical RAM.\n"
        )
    })

    # Now summarize via topic_id
    res_db = client.post("/note-ai/summarize", json={
        "topic_id": tp_id,
        "summary_style": "key_takeaways",
    })
    assert res_db.status_code == 200
    assert "Memory Paging" in res_db.json()["summary_markdown"]
    assert len(res_db.json()["key_takeaways"]) >= 1

    # 6. Concept Explainer: Beginner depth
    res_beg = client.post("/note-ai/explain", json={
        "concept": "Event Loop",
        "depth": "beginner",
    })
    assert res_beg.status_code == 200
    data_beg = res_beg.json()
    assert data_beg["concept"] == "Event Loop"
    assert data_beg["depth"] == "beginner"
    assert "Beginner Guide" in data_beg["explanation_markdown"]
    assert data_beg["analogy"] is not None
    assert len(data_beg["key_points"]) > 0

    # 7. Concept Explainer: Expert depth
    res_exp = client.post("/note-ai/explain", json={
        "concept": "Lock-Free Ring Buffer",
        "depth": "expert",
    })
    assert res_exp.status_code == 200
    data_exp = res_exp.json()
    assert "Technical Deep Dive" in data_exp["explanation_markdown"]
    assert data_exp["example_snippet"] is not None

    # 8. Concept Explainer: Analogies depth
    res_ana = client.post("/note-ai/explain", json={
        "concept": "Garbage Collection",
        "depth": "analogies",
    })
    assert res_ana.status_code == 200
    assert "Mental Model & Analogy" in res_ana.json()["explanation_markdown"]

    # 9. Concept Explainer: Intermediate depth
    res_mid = client.post("/note-ai/explain", json={
        "concept": "Binary Search",
        "depth": "intermediate",
    })
    assert res_mid.status_code == 200
    assert "Concept Breakdown" in res_mid.json()["explanation_markdown"]

    # 10. Error cases
    assert client.post("/note-ai/summarize", json={}).status_code == 400
    assert client.post("/note-ai/summarize", json={"topic_id": 99999}).status_code == 404
    assert client.post("/note-ai/explain", json={"concept": "   "}).status_code == 400
    assert client.post("/note-ai/explain", json={"concept": "a"}).status_code == 422  # min_length=2

    client.post("/system/reset")


def test_document_rag_endpoints():
    client.post("/system/reset")

    # 1. Setup linked hierarchy
    rm = client.post("/roadmaps/", json={"title": "Systems Architecture", "description": "Large-scale systems"}).json()
    rm_id = rm["id"]
    ph = client.post("/phases/", json={"roadmap_id": rm_id, "title": "Data Storage"}).json()
    tp = client.post("/topics/", json={"phase_id": ph["id"], "title": "Replication & Consensus"}).json()
    tp_id = tp["id"]

    # 2. Empty list
    res_empty = client.get("/documents/")
    assert res_empty.status_code == 200
    assert res_empty.json() == []

    # 3. Create Document 1 (Textbook Chapter)
    ddia_content = (
        "# Chapter 5: Replication\n\n"
        "Replication means keeping a copy of the same data on multiple machines connected via a network.\n\n"
        "Leader-based replication (active/passive): One replica is designated as the leader. "
        "When clients write to the database, they send requests to the leader, which writes data locally "
        "and sends data changes to followers as part of a replication log.\n\n"
        "Synchronous vs Asynchronous Replication: In synchronous replication, the leader waits until "
        "a follower confirms write completion before notifying the client. Asynchronous replication "
        "provides higher throughput but risks data loss if the leader fails before replicating."
    )
    res_doc1 = client.post("/documents/", json={
        "title": "Designing Data-Intensive Applications: Chapter 5",
        "doc_type": "textbook",
        "content": ddia_content,
        "topic_id": tp_id,
        "roadmap_id": rm_id,
    })
    assert res_doc1.status_code == 201
    doc1 = res_doc1.json()
    doc1_id = doc1["id"]
    assert doc1["title"] == "Designing Data-Intensive Applications: Chapter 5"
    assert doc1["doc_type"] == "textbook"
    assert doc1["total_chunks"] >= 1
    assert len(doc1["chunks"]) == doc1["total_chunks"]
    assert doc1["chunks"][0]["word_count"] > 10

    # 4. Create Document 2 with explicit page markers (Research Paper)
    raft_content = (
        "--- Page 1 ---\n"
        "# In Search of an Understandable Consensus Algorithm\n\n"
        "Raft is a consensus algorithm for managing a replicated log. It produces a result equivalent "
        "to multi-Paxos, and it is as efficient as Paxos, but its structure makes it more understandable. "
        "Raft separates key elements of consensus, such as leader election, log replication, and safety.\n\n"
        "--- Page 2 ---\n"
        "Leader Election Mechanics: Raft uses a heartbeat mechanism to trigger leader election. "
        "When servers start up, they begin as followers. A server remains in follower state as long as "
        "it receives valid RPCs from a leader or candidate. "
        "To avoid split votes between candidates, election timeouts are randomized from a fixed interval "
        "(e.g., 150-300ms). This ensures that one server times out, wins the election, and sends heartbeats."
    )
    res_doc2 = client.post("/documents/", json={
        "title": "Raft Consensus Paper (Ongaro & Ousterhout)",
        "doc_type": "paper",
        "content": raft_content,
        "topic_id": tp_id,
    })
    assert res_doc2.status_code == 201
    doc2 = res_doc2.json()
    doc2_id = doc2["id"]
    assert doc2["total_pages"] == 2
    # Verify page assignment
    pages_found = {c["page_number"] for c in doc2["chunks"]}
    assert 1 in pages_found or 2 in pages_found

    # 5. List and filter documents
    res_list = client.get("/documents/")
    assert res_list.status_code == 200
    assert len(res_list.json()) == 2

    res_filter_q = client.get("/documents/?q=Raft")
    assert res_filter_q.status_code == 200
    assert len(res_filter_q.json()) == 1
    assert res_filter_q.json()[0]["id"] == doc2_id

    res_filter_rm = client.get(f"/documents/?roadmap_id={rm_id}")
    assert res_filter_rm.status_code == 200
    assert len(res_filter_rm.json()) == 1

    # 6. Retrieve detail of Document 1
    detail_res = client.get(f"/documents/{doc1_id}")
    assert detail_res.status_code == 200
    assert detail_res.json()["id"] == doc1_id
    assert len(detail_res.json()["chunks"]) > 0

    # 7. Perform RAG query
    rag_res = client.post("/documents/query", json={
        "query": "How are split votes avoided during leader election?",
        "top_k": 2,
    })
    assert rag_res.status_code == 200
    rag_data = rag_res.json()
    assert rag_data["query"] == "How are split votes avoided during leader election?"
    assert len(rag_data["citations"]) >= 1
    assert "Leader Election" in rag_data["answer_markdown"] or "election" in rag_data["answer_markdown"].lower()
    assert rag_data["citations"][0]["relevance_score"] > 0.0
    assert rag_data["model_used"] in ["builtin-offline"] or rag_data["model_used"].startswith("ollama:")

    # 8. Query scoped to specific document_id
    scoped_res = client.post("/documents/query", json={
        "query": "What is synchronous replication?",
        "document_ids": [doc1_id],
        "top_k": 1,
    })
    assert scoped_res.status_code == 200
    scoped_data = scoped_res.json()
    assert scoped_data["citations"][0]["document_id"] == doc1_id
    assert "synchronous" in scoped_data["citations"][0]["snippet"].lower()

    # 9. Delete Document 1
    assert client.delete(f"/documents/{doc1_id}").status_code == 204
    assert client.get(f"/documents/{doc1_id}").status_code == 404

    # 10. Error handling
    assert client.get("/documents/99999").status_code == 404
    assert client.delete("/documents/99999").status_code == 404
    assert client.post("/documents/", json={"title": "Short", "content": "too small"}).status_code == 422
    assert client.post("/documents/", json={"title": "Doc", "content": "Long enough content here for testing error", "topic_id": 99999}).status_code == 404
    assert client.post("/documents/query", json={"query": " "}).status_code in [400, 422]

    client.post("/system/reset")


def test_sync_endpoints():
    client.post("/system/reset")

    # 1. Initial Sync Status
    res_status = client.get("/sync/status")
    assert res_status.status_code == 200
    st_data = res_status.json()
    assert "device_id" in st_data
    assert st_data["total_roadmaps"] == 0
    assert st_data["total_notes"] == 0

    # 2. Register Friendly Device Name
    res_reg = client.post("/sync/device/register", json={"device_name": "Udoy Laptop Workstation"})
    assert res_reg.status_code == 200
    assert res_reg.json()["device_name"] == "Udoy Laptop Workstation"

    # 3. Create Sample Study Hierarchy & Items
    rm = client.post("/roadmaps/", json={"title": "Distributed Algorithms", "description": "Consensus & fault tolerance"}).json()
    rm_id = rm["id"]
    ph = client.post("/phases/", json={"roadmap_id": rm_id, "title": "Consensus"}).json()
    tp = client.post("/topics/", json={"phase_id": ph["id"], "title": "Paxos Protocol"}).json()
    tp_id = tp["id"]
    client.post("/subtopics/", json={"topic_id": tp_id, "title": "Phase 1a Prepare"})

    # Note
    client.put(f"/notes/topic/{tp_id}", json={"content": "Paxos achieves consensus on a single value through proposer-acceptor quorum."})

    # Resource
    client.post("/resources/", json={
        "topic_id": tp_id,
        "title": "Paxos Made Simple",
        "url": "https://lamport.azurewebsites.net/pubs/paxos-simple.pdf",
        "resource_type": "pdf",
    })

    # Project
    client.post("/projects/", json={
        "roadmap_id": rm_id,
        "topic_id": tp_id,
        "title": "Paxos KV Store",
        "description": "Multi-Paxos replicated state machine in Rust",
        "difficulty": "hard",
        "status": "in_progress",
    })

    # Flashcard
    client.post("/api/study-recall/generate", json={
        "topic_id": tp_id,
        "deck_title": "Paxos Flashcards",
        "source_text": "Paxos is a consensus protocol. Acceptors promise not to accept older proposals.",
        "generate_flashcards": True,
        "generate_quiz": False,
    })

    # Document
    client.post("/documents/", json={
        "title": "Leslie Lamport: Paxos Paper",
        "doc_type": "paper",
        "content": "--- Page 1 ---\nPaxos consensus basics.\n\n--- Page 2 ---\nLeader election and invariant guarantees.",
        "topic_id": tp_id,
    })

    # 4. Status reflects created entities
    mid_status = client.get("/sync/status").json()
    assert mid_status["total_roadmaps"] == 1
    assert mid_status["total_topics"] == 1
    assert mid_status["total_notes"] == 1
    assert mid_status["total_documents"] == 1

    # 5. Export Encrypted Sync Bundle
    passphrase = "StudyOS@MasterSyncKey2026!"
    export_res = client.post("/sync/export", json={
        "passphrase": passphrase,
        "include_documents": True,
    })
    assert export_res.status_code == 200
    bundle = export_res.json()
    assert bundle["bundle_version"] == "1.0"
    assert "salt_hex" in bundle
    assert "nonce_hex" in bundle
    assert "ciphertext_base64" in bundle
    assert "checksum_sha256" in bundle
    assert bundle["entity_counts"]["roadmaps"] == 1
    assert bundle["entity_counts"]["notes"] == 1
    assert bundle["entity_counts"]["documents"] == 1

    # Ensure ciphertext is not plaintext
    assert "Paxos" not in bundle["ciphertext_base64"]

    # 6. Attempt Import with WRONG passphrase -> Expect 400
    bad_import = client.post("/sync/import", json={
        "passphrase": "WrongPassphrase123!",
        "salt_hex": bundle["salt_hex"],
        "nonce_hex": bundle["nonce_hex"],
        "ciphertext_base64": bundle["ciphertext_base64"],
        "checksum_sha256": bundle["checksum_sha256"],
    })
    assert bad_import.status_code == 400
    assert "Decryption failed" in bad_import.json()["detail"]

    # 7. Clean reset to simulate importing onto a second/fresh device
    client.post("/system/reset")
    assert client.get("/roadmaps/").json() == []
    assert client.get("/documents/").json() == []

    # 8. Successful Import with CORRECT passphrase
    import_res = client.post("/sync/import", json={
        "passphrase": passphrase,
        "salt_hex": bundle["salt_hex"],
        "nonce_hex": bundle["nonce_hex"],
        "ciphertext_base64": bundle["ciphertext_base64"],
        "checksum_sha256": bundle["checksum_sha256"],
        "merge_mode": "merge",
    })
    assert import_res.status_code == 200
    import_data = import_res.json()
    assert import_data["success"] is True
    assert import_data["entities_imported"]["roadmaps"] == 1
    assert import_data["entities_imported"]["notes"] == 1
    assert import_data["entities_imported"]["documents"] == 1

    # 9. Verify restored entities in database
    restored_rm = client.get("/roadmaps/").json()
    assert len(restored_rm) == 1
    assert restored_rm[0]["title"] == "Distributed Algorithms"

    restored_docs = client.get("/documents/").json()
    assert len(restored_docs) == 1
    assert restored_docs[0]["title"] == "Leslie Lamport: Paxos Paper"

    restored_notes = client.get("/notes/").json()
    assert len(restored_notes) == 1
    assert "proposer-acceptor quorum" in restored_notes[0]["content"]

    # 10. Test Backup Export and Restore
    backup_exp = client.post("/sync/backup/export", json={"passphrase": passphrase})
    assert backup_exp.status_code == 200
    backup_data = backup_exp.json()

    client.post("/system/reset")
    assert client.get("/roadmaps/").json() == []

    backup_rest = client.post("/sync/backup/restore", json={
        "passphrase": passphrase,
        "salt_hex": backup_data["salt_hex"],
        "nonce_hex": backup_data["nonce_hex"],
        "ciphertext_base64": backup_data["ciphertext_base64"],
        "checksum_sha256": backup_data["checksum_sha256"],
    })
    assert backup_rest.status_code == 200
    assert len(client.get("/roadmaps/").json()) == 1

    client.post("/system/reset")











