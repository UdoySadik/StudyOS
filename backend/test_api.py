import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_flow():
    print("Testing backend endpoints flow...")
    
    # 1. Create Roadmap
    r = requests.post(f"{BASE_URL}/roadmaps/", json={
        "title": "Computer Science & Systems",
        "description": "Foundational curriculum for computer science"
    })
    assert r.status_code == 201
    roadmap = r.json()
    roadmap_id = roadmap["id"]
    print(f"[OK] Created Roadmap: {roadmap['title']} (ID: {roadmap_id})")

    # 2. Create Phase
    r = requests.post(f"{BASE_URL}/phases/", json={
        "roadmap_id": roadmap_id,
        "title": "Phase 1: Computer Systems",
        "order_index": 1
    })
    assert r.status_code == 201
    phase = r.json()
    phase_id = phase["id"]
    print(f"[OK] Created Phase: {phase['title']} (ID: {phase_id})")

    # 3. Create Topic
    r = requests.post(f"{BASE_URL}/topics/", json={
        "phase_id": phase_id,
        "title": "Topic 1.1: CPU and Memory Hierarchy",
        "order_index": 1
    })
    assert r.status_code == 201
    topic = r.json()
    topic_id = topic["id"]
    print(f"[OK] Created Topic: {topic['title']} (ID: {topic_id})")

    # 4. Create Subtopic
    r = requests.post(f"{BASE_URL}/subtopics/", json={
        "topic_id": topic_id,
        "title": "L1/L2/L3 Cache levels and timing",
        "order_index": 1
    })
    assert r.status_code == 201
    subtopic = r.json()
    print(f"[OK] Created Subtopic: {subtopic['title']}")

    # 5. Set Goal (Target Date)
    r = requests.post(f"{BASE_URL}/goals/", json={
        "roadmap_id": roadmap_id,
        "target_date": "2026-10-31"
    })
    assert r.status_code == 201
    goal = r.json()
    print(f"[OK] Created Goal: Target Date {goal['target_date']}")

    # 6. Check Dashboard Summary
    r = requests.get(f"{BASE_URL}/dashboard/{roadmap_id}")
    assert r.status_code == 200
    dashboard = r.json()
    print("[OK] Dashboard stats fetched successfully:")
    print(json.dumps(dashboard, indent=2))

    # 7. Complete Topic and Check Dashboard again
    r = requests.patch(f"{BASE_URL}/topics/{topic_id}/complete", json={
        "is_completed": True
    })
    assert r.status_code == 200
    print(f"[OK] Marked topic {topic_id} as completed.")

    r = requests.get(f"{BASE_URL}/dashboard/{roadmap_id}")
    assert r.status_code == 200
    dashboard_updated = r.json()
    print("[OK] Updated Dashboard stats:")
    print(f"   Progress: {dashboard_updated['progress']['progress_percent']}%")
    print(f"   Completed: {dashboard_updated['progress']['completed_topics']}")
    print(f"   Remaining: {dashboard_updated['progress']['remaining_topics']}")

if __name__ == "__main__":
    test_flow()
