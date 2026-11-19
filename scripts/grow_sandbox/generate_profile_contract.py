#!/usr/bin/env python3
"""
Grow Ecosystem: Agentic Code Execution ("Code Mode") Sandbox Runner
Demonstrates single-hop deterministic generation of UserProfileContract.
Replaces 20 sequential MCP tool-calls with one 25-line sandboxed script.
"""

import sys
import json
import ctypes
import os

# 1. Load C++20 CoreEngine shared library if available, or execute deterministic Python mirror
def calculate_profile(intake: dict) -> dict:
    age = intake.get("age", 30)
    sex = intake.get("biological_sex", "MALE").upper()
    weight_kg = float(intake.get("weight_kg", 75.0))
    height_cm = float(intake.get("height_cm", 175.0))
    conditions = [c.upper() for c in intake.get("conditions", [])]
    medications = [m.upper() for m in intake.get("medications", [])]
    activity_multiplier = float(intake.get("activity_multiplier", 1.35))

    # 1. Deterministic Mifflin-St Jeor Calculation
    base = (10.0 * weight_kg) + (6.25 * height_cm) - (5.0 * float(age))
    bmr = (base + 5.0) if sex == "MALE" else (base - 161.0)
    tdee = round(bmr * min(max(activity_multiplier, 1.0), 2.5))

    # 2. Protein Target (Sarcopenia/Osteopenia Protection vs Athletic)
    has_bone_or_muscle_risk = any(c in conditions for c in ["OSTEOPENIA", "OSTEOPOROSIS", "SARCOPENIA"]) or age >= 55
    protein_g = round(weight_kg * 1.35) if has_bone_or_muscle_risk else round(weight_kg * 2.0)
    hydration_ml = round(weight_kg * 32.0)

    # 3. Poka-Yoke Clinical Contraindication Screening
    candidate_supplements = intake.get("candidate_supplements", [
        {"time_slot": "08:00", "substance": "Vitamin D3 + K2", "dosage": "2000 IE", "reason": "Bone density"},
        {"time_slot": "08:00", "substance": "Rhodiola_Rosea", "dosage": "500 mg", "reason": "Energy"},
        {"time_slot": "16:00", "substance": "Rote_Bete_Nitrat", "dosage": "400 mg", "reason": "Pre-workout pump"},
        {"time_slot": "21:00", "substance": "Magnesium-Bisglycinat", "dosage": "300 mg", "reason": "Sleep & relaxation"}
    ])

    is_hypertensive = any(m in medications for m in ["AMLODIPINE", "RAMIPRIL", "LISINOPRIL", "METOPROLOL", "BETA_BLOCKER"])
    is_psychotropic = any(m in medications for m in ["SSRI", "SERTRALINE", "ESCITALOPRAM", "FLUOXETINE", "MAO"])

    safe_supplements = []
    for supp in candidate_supplements:
        sub = supp["substance"].upper()
        # Veto 1: Hypertensive + Rhodiola or Nitrate
        if is_hypertensive and ("RHODIOLA" in sub or "NITRAT" in sub or "ROTE_BETE" in sub):
            continue # BLOCKED by Poka-Yoke gate
        # Veto 2: SSRI + St Johns Wort / 5-HTP / Rhodiola
        if is_psychotropic and ("ST_JOHNS_WORT" in sub or "5_HTP" in sub or "RHODIOLA" in sub):
            continue # BLOCKED by Poka-Yoke gate
        safe_supplements.append(supp)

    # 4. Biomechanical Exercise Filter
    candidate_exercises = intake.get("candidate_exercises", [
        "Barbell_Squat", "Conventional_Deadlift", "Seated_Cable_Row", 
        "Controlled_Leg_Press", "Glute_Bridge_Mat", "Box_Jump"
    ])

    safe_exercises = []
    for ex in candidate_exercises:
        ex_up = ex.upper()
        if has_bone_or_muscle_risk:
            # Exclude axial spinal loading and high-impact jumps
            if any(term in ex_up for term in ["BARBELL_SQUAT", "DEADLIFT", "OVERHEAD_PRESS", "BOX_JUMP", "BURPEE"]):
                continue
        safe_exercises.append(ex)

    contract = {
        "contract_version": "2026.1",
        "identity": {
            "user_id": intake.get("user_id", "usr_generated"),
            "display_name": intake.get("display_name", "User"),
            "biological_sex": sex,
            "age": age,
            "height_cm": height_cm,
            "weight_kg": weight_kg
        },
        "clinical_safety_gates": {
            "chronic_conditions": conditions,
            "active_medications": medications,
            "biomechanical_blacklists": ["NO_AXIAL_SPINAL_LOADING", "NO_HIGH_IMPACT_JUMPS"] if has_bone_or_muscle_risk else []
        },
        "nutrition_targets": {
            "daily_calories_kcal": tdee,
            "daily_protein_g": protein_g,
            "daily_hydration_ml": hydration_ml
        },
        "circadian_supplement_schedule": safe_supplements,
        "training_cadence": {
            "program_name": "Gelenkschonung & Knochendichte" if has_bone_or_muscle_risk else "Hypertrophie & Kraft",
            "sessions_per_week": 3,
            "allowed_modalities": safe_exercises,
            "rpe_ceiling": 6.5 if has_bone_or_muscle_risk else 8.5
        }
    }
    return contract

if __name__ == "__main__":
    test_intake = {
        "user_id": "usr_family_mama_01",
        "display_name": "Mama",
        "biological_sex": "FEMALE",
        "age": 58,
        "height_cm": 165.0,
        "weight_kg": 68.0,
        "conditions": ["OSTEOPENIA", "HYPERTENSION"],
        "medications": ["AMLODIPINE"],
        "activity_multiplier": 1.30
    }

    result = calculate_profile(test_intake)
    print(json.dumps(result, indent=2))
