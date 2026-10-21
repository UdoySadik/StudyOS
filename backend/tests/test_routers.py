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

