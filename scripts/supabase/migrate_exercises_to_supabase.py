#!/usr/bin/env python3
"""
Migrate exercise catalog JSON to Supabase public.exercises table.
"""
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Dict, List

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://oqhqpkayzkmnbcmbqkmm.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "sb_publishable_Nd7hRD_Fp6no6X-NMnbuPQ_pLxJ-iNR")

CATALOG_PATH = Path("/Users/parris-campbellnkembi/Developer/GrowWorkspace/GymApp/GymApp/Resources/hasaneyldrm_exercises_catalog.json")

def clean_exercise(raw: Dict[str, Any]) -> Dict[str, Any]:
    eid = str(raw.get("id", "")).zfill(4)
    name = str(raw.get("name", "")).strip()
    target = str(raw.get("target", "")).strip()
    category = str(raw.get("category", "")).strip()
    body_part = str(raw.get("body_part", "")).strip()
    equipment = str(raw.get("equipment", "")).strip()
    
    primary = [target] if target else []
    secondary = raw.get("secondary_muscles", [])
    if isinstance(secondary, str):
        secondary = [secondary]
    elif not isinstance(secondary, list):
        secondary = []

    steps = raw.get("instruction_steps", [])
    if not isinstance(steps, list):
        steps = [str(steps)]

    instructions_raw = raw.get("instructions", {})
    general_notes = ""
    if isinstance(instructions_raw, dict):
        general_notes = instructions_raw.get("en", "")
    elif isinstance(instructions_raw, str):
        general_notes = instructions_raw

    gif_url = str(raw.get("gif_url", "")).strip()
    image_url = str(raw.get("image", "")).strip()

    # Determine force type and mechanics
    force = "PULL" if any(w in name.lower() for w in ["row", "pull", "curl", "deadlift", "chin"]) else "PUSH"
    mechanics = "COMPOUND" if any(w in name.lower() for w in ["squat", "press", "deadlift", "row", "lunge", "dip", "pull-up"]) else "ISOLATION"

    return {
        "id": eid,
        "name": name,
        "name_de": name,
        "category": category,
        "body_part": body_part,
        "target": target,
        "equipment": equipment,
        "primary_muscles": primary,
        "secondary_muscles": secondary,
        "stabilizers": ["core", "erector_spinae"] if mechanics == "COMPOUND" else [],
        "synergists": secondary,
        "antagonists": [],
        "setup_and_starting_position": f"Setup for {name} using {equipment}." if equipment else f"Setup for {name}.",
        "movement_execution_steps": steps,
        "mental_cues": ["Breathe rhythmically", "Control the eccentric phase"],
        "common_mistakes": ["Using momentum", "Incomplete range of motion"],
        "general_execution_notes": general_notes,
        "youtube_demonstration_url": f"https://www.youtube.com/results?search_query={name.replace(' ', '+')}+form",
        "gif_url": gif_url,
        "image_url": image_url,
        "tracking_mode": "WEIGHT_AND_REPS",
        "default_rest_seconds": 90 if mechanics == "COMPOUND" else 60,
        "difficulty_tier": "INTERMEDIATE",
        "mechanics_type": mechanics,
        "force_type": force,
        "movement_pattern": body_part,
        "regressions": [],
        "progressions": []
    }

def main():
    if not CATALOG_PATH.exists():
        print(f"Catalog file not found at {CATALOG_PATH}", file=sys.stderr)
        sys.exit(1)

    with open(CATALOG_PATH, "r", encoding="utf-8") as f:
        raw_items = json.load(f)

    print(f"Loaded {len(raw_items)} raw exercises from {CATALOG_PATH}")
    cleaned = [clean_exercise(r) for r in raw_items]

    # Save seed file
    seed_path = Path("/Users/parris-campbellnkembi/Developer/GrowWorkspace/scripts/supabase/exercises_seed.json")
    seed_path.parent.mkdir(parents=True, exist_ok=True)
    with open(seed_path, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, indent=2)
    print(f"Wrote {len(cleaned)} cleaned records to {seed_path}")

    # Try uploading batch via PostgREST
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }

    url = f"{SUPABASE_URL}/rest/v1/exercises"
    batch_size = 50
    success = 0

    print("Attempting PostgREST upload (requires table public.exercises to exist)...")
    for i in range(0, min(batch_size, len(cleaned)), batch_size):
        chunk = cleaned[i:i+batch_size]
        payload = json.dumps(chunk).encode("utf-8")
        req = urllib.request.Request(url, data=payload, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req) as resp:
                if resp.status in (200, 201):
                    success += len(chunk)
                    print(f"Uploaded batch {i}..{i+len(chunk)}")
        except urllib.error.HTTPError as e:
            err = e.read().decode()
            print(f"PostgREST response (Status {e.code}): {err}")
            print("Note: Run scripts/supabase/03_create_exercises_catalog.sql in the Supabase SQL editor first.")
            break
        except Exception as ex:
            print(f"Connection error: {ex}")
            break

if __name__ == "__main__":
    main()
