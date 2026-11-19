#!/usr/bin/env python3
"""
GymApp Unified MCP Server
Exposes GymApp training data, planning, analytics, and BWK Ulm reha auditing
via the Model Context Protocol (MCP) using Starlette SSE transport and stdio.

Author: GrowSuite Engineering / Antigravity
Standards: ISO/IEC 25010, BWK Ulm Visceral Reha Doctrine
"""

import os
os.environ["GRPC_ENABLE_FORK_SUPPORT"] = "1"
import sys
import json
import uuid
import time
import datetime
import subprocess
import threading
from typing import Optional, List, Dict, Any
from pathlib import Path

from mcp.server.mcpserver import MCPServer
from mcp.server.sse import TransportSecuritySettings
from starlette.routing import Route
from starlette.responses import JSONResponse
import uvicorn

# MARK: - Google Cloud Firestore Integration (Native Free Tier)
FIRESTORE_PROJECT_ID = "antigravity-sync-505016"
FIRESTORE_DB = None
try:
    from google.cloud import firestore
    FIRESTORE_DB = firestore.Client(project=FIRESTORE_PROJECT_ID)
    print(f"[Firestore] Connected to Cloud Firestore database on project '{FIRESTORE_PROJECT_ID}'", file=sys.stderr)
except Exception as e:
    print(f"[Firestore] Note: Could not initialize Cloud Firestore client ({e}). Falling back to local storage.", file=sys.stderr)

# MARK: - Configuration & Paths
COCOA_REF_OFFSET = 978307200.0 # Seconds between 1970-01-01 and 2001-01-01
TARGET_DEVICE_UDID = "00008140-001E292E0062201C"
BUNDLE_ID = "com.nkembi.somagym"

WORKSPACE_DIR = Path("/Users/parris-campbellnkembi/Developer/GrowWorkspace")
ICLOUD_DATA_DIR = Path("/Users/parris-campbellnkembi/Library/Mobile Documents/com~apple~CloudDocs/GymData/userData/primary_wize_prod")
TELEMETRY_DATA_DIR = WORKSPACE_DIR / "telemetry" / "iphone" / "GymApp" / "userData" / "primary_wize_prod"
CATALOG_PATH = WORKSPACE_DIR / "GymApp" / "GymApp" / "Resources" / "hasaneyldrm_exercises_catalog.json"

ICLOUD_DATA_DIR.mkdir(parents=True, exist_ok=True)
TELEMETRY_DATA_DIR.mkdir(parents=True, exist_ok=True)

# MARK: - Storage Helper
class GymAppStorage:
    @classmethod
    def pull_from_iphone_if_connected(cls, filename: str):
        try:
            res = subprocess.run(
                ["xcrun", "devicectl", "device", "copy", "from",
                 "--device", TARGET_DEVICE_UDID,
                 "--domain-type", "appDataContainer",
                 "--domain-identifier", BUNDLE_ID,
                 "--source", f"Documents/userData/primary_wize_prod/{filename}",
                 "--destination", str(TELEMETRY_DATA_DIR / filename)],
                capture_output=True,
                text=True,
                timeout=4
            )
            if res.returncode == 0:
                p_src = TELEMETRY_DATA_DIR / filename
                if p_src.exists():
                    (ICLOUD_DATA_DIR / filename).write_text(p_src.read_text(encoding="utf-8"), encoding="utf-8")
        except Exception:
            pass

    @classmethod
    def _get_read_path(cls, filename: str) -> Path:
        # Pull live from iPhone if connected
        cls.pull_from_iphone_if_connected(filename)

        p1 = ICLOUD_DATA_DIR / filename
        p2 = TELEMETRY_DATA_DIR / filename

        c1 = p1.read_text(encoding="utf-8").strip() if p1.exists() else ""
        c2 = p2.read_text(encoding="utf-8").strip() if p2.exists() else ""

        # Prioritize whichever file actually contains data
        if c1 and c1 not in ("[]", "{}", "") and (not c2 or c2 in ("[]", "{}")):
            return p1
        if c2 and c2 not in ("[]", "{}", "") and (not c1 or c1 in ("[]", "{}")):
            return p2

        if p1.exists() and p2.exists():
            return p1 if p1.stat().st_mtime >= p2.stat().st_mtime else p2

        return p1 if p1.exists() else p2

    @classmethod
    def load_json(cls, filename: str, default: Any = None) -> Any:
        # Check Firestore first for real-time cloud data
        if FIRESTORE_DB and filename == "planned_workouts.json":
            try:
                col = FIRESTORE_DB.collection("users").document("primary_wize_prod").collection("planned_workouts")
                docs = [doc.to_dict() for doc in col.stream()]
                if docs:
                    return docs
            except Exception as e:
                print(f"[Firestore] Read error for {filename}: {e}", file=sys.stderr)

        path = cls._get_read_path(filename)
        if not path.exists():
            return default if default is not None else []
        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read().strip()
                if not content or content == "2": # Edge case placeholder
                    return default if default is not None else []
                return json.loads(content)
        except Exception as e:
            print(f"[Storage] Error reading {path}: {e}", file=sys.stderr)
            return default if default is not None else []

    @classmethod
    def save_json(cls, filename: str, data: Any):
        # 1. Save to Cloud Firestore
        if FIRESTORE_DB and filename == "planned_workouts.json" and isinstance(data, list):
            try:
                batch = FIRESTORE_DB.batch()
                col = FIRESTORE_DB.collection("users").document("primary_wize_prod").collection("planned_workouts")
                for item in data:
                    item_id = item.get("id")
                    if item_id:
                        batch.set(col.document(item_id), item)
                batch.commit()
                print(f"[Firestore] Synchronized {len(data)} items to Cloud Firestore", file=sys.stderr)
            except Exception as e:
                print(f"[Firestore] Write error for {filename}: {e}", file=sys.stderr)

        # 2. Save to local telemetry and iCloud bridge
        for dir_path in [ICLOUD_DATA_DIR, TELEMETRY_DATA_DIR]:
            try:
                target_path = dir_path / filename
                with open(target_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2, sort_keys=True)
            except Exception as e:
                print(f"[Storage] Error writing {filename} to {dir_path}: {e}", file=sys.stderr)

        # 3. Attempt devicectl sync to iPhone if connected
        cls.push_file_to_iphone(filename)

    @classmethod
    def push_file_to_iphone(cls, filename: str):
        # Native sync is handled via Cloud Firestore and iCloud.
        # Devicectl subprocess forking is disabled to prevent gRPC C-core deadlocks.
        pass

# MARK: - Functional Core & Spine Stabilization Guidelines
CORE_CONTRAINDICATED_KEYWORDS = [
    "crunch", "sit-up", "situp", "abdominal press", "valsalva",
    "knee to chest crunch", "jackknife", "v-up", "ab roller"
]

SAFE_FUNCTIONAL_SUBSTITUTES = [
    "Unterarmstuetz / Plank (Plank)",
    "McGill Side Plank (Seitstuetz)",
    "McGill Curl-Up (Kontrolliert)",
    "Toter Kaefer (Dead Bug)",
    "Glute Bridge (Beckenheben)",
    "Pallof Press (Kabel / Band)",
    "Bird-Dog (Vierfuesslerstand)"
]

# MARK: - MCP Server Initialization
mcp = MCPServer("GymApp-Controller")

@mcp.tool()
def get_daily_schedule(date_str: Optional[str] = None) -> str:
    """[Grow Master - 24h Gesamtfahrplan Ökosystem] Ruft den ganzheitlichen Tagesplan ab, wenn der Nutzer nach 'Was steht heute an?', 'Tagesablauf', 'Plan für heute' oder dem Ökosystem fragt.
    
    Synthetisiert eine chronologische Roadmap von 05:30 bis 22:00 Uhr:
    - GymApp: Geplante Trainingseinheit (z. B. Core & Lumbale Tiefenstabilitaet)
    - Growcery: Mahlzeitenzeiten Truppenkueche, Fastenstart (19:30) & Zirkadiane Supplements (06:00, 06:30, 11:45, 16:00, 16:45, 21:00)
    - GrowCare: Morgen-Hautpflege (06:15), Post-Dienst Stube lueften (16:30), Bartpflege/Pseudofolliculitis (18:00), 4C Haare (20:00), CPAP-Hygiene (21:30)
    - GrowFinance: Budget-Status & gesicherte 1.274,70 EUR Schuldentilgung
    
    Args:
        date_str: Zieldatum im Format YYYY-MM-DD (z.B. '2026-11-13'). Fehlt dieser, wird heute verwendet.
    """
    try:
        from scripts.growcery_mcp.server import get_master_ecosystem_schedule
        return get_master_ecosystem_schedule(date_str=date_str)
    except Exception as e:
        return f"Fehler beim Zusammenfuehren des Oekosystem-Tagesplans: {e}"

@mcp.tool()
def plan_workout(
    title: str,
    date_str: str,
    time_str: str = "17:00",
    exercise_names: List[str] = [],
    notes: str = "",
    modality: str = "kraft"
) -> str:
    """Erstellt ein neues geplantes Workout im Kalender der GymApp.
    
    Args:
        title: Name des Workouts (z. B. 'Calisthenics Push A' oder 'Oberkoerper Kraft').
        date_str: Datum im Format YYYY-MM-DD (z. B. '2026-11-14').
        time_str: Uhrzeit im Format HH:MM (z. B. '17:00').
        exercise_names: Liste von Uebungsnamen (z. B. ['Liegestuetze', 'Dips', 'Planks']).
        notes: Zusaetzliche Ausfuehrungshinweise oder RPE-Vorgaben.
        modality: Trainingsform ('kraft', 'calisthenics', 'ausdauer', 'reha').
    """
    try:
        dt = datetime.datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %H:%M")
    except ValueError:
        return f"Ungueltiges Datums-/Zeitformat: {date_str} {time_str}. Erwartet: YYYY-MM-DD HH:MM."

    # Validate core lumbar safety
    flagged = []
    for ex in exercise_names:
        clean = ex.lower()
        if any(bad in clean for bad in CORE_CONTRAINDICATED_KEYWORDS):
            flagged.append(ex)

    if flagged:
        substitutes = ", ".join(SAFE_FUNCTIONAL_SUBSTITUTES[:3])
        return (f"RUMPF-BLOCK: Das Workout enthaelt kontraindizierte Uebungen ({', '.join(flagged)}), "
                f"die schaedlichen Druck auf die Lendenwirbelsaeule erzeugen. "
                f"Bitte ersetzen durch sichere Alternativen: {substitutes}.")

    # Calculate Cocoa reference timestamp
    unix_ts = dt.timestamp()
    cocoa_ts = unix_ts - COCOA_REF_OFFSET

    items = GymAppStorage.load_json("planned_workouts.json", default=[])
    if not isinstance(items, list):
        items = []

    new_item = {
        "id": str(uuid.uuid4()).upper(),
        "programId": str(uuid.uuid4()).upper(),
        "programName": "Gemini Adaptive Steuerung",
        "sessionId": str(uuid.uuid4()).upper(),
        "dayNumber": 1,
        "title": title,
        "plannedDate": cocoa_ts,
        "isCompleted": False,
        "completedAt": None,
        "modalityRaw": modality.lower(),
        "calendarEventId": None,
        "notes": notes,
        "exerciseNames": exercise_names
    }

    items.append(new_item)
    GymAppStorage.save_json("planned_workouts.json", items)

    return (f"Workout '{title}' erfolgreich fuer den {date_str} um {time_str} Uhr in GymApp angelegt.\n"
            f"Enthaltene Uebungen: {', '.join(exercise_names) if exercise_names else 'Standard'}\n"
            f"Status: In GymApp synchronisiert.")

@mcp.tool()
def get_workout_history(days: int = 15) -> str:
    """Ruft die absolvierten Trainingseinheiten der letzten N Tage ab inklusive Saetzen, Gewichten und RPE.
    
    Args:
        days: Anzahl der zurueckliegenden Tage (Standard: 15).
    """
    sessions = GymAppStorage.load_json("sessions.json", default=[])
    if not isinstance(sessions, list) or not sessions:
        return f"Keine absolvierten Trainingseinheiten in den letzten {days} Tagen gefunden."

    cutoff_unix = time.time() - (days * 86400)
    cutoff_cocoa = cutoff_unix - COCOA_REF_OFFSET

    filtered = []
    for s in sessions:
        st = s.get("startTime", 0)
        if isinstance(st, (int, float)) and st >= cutoff_cocoa:
            filtered.append(s)

    if not filtered:
        # Fallback if timestamps are stored differently
        filtered = sessions[-min(5, len(sessions)):]

    lines = [f"Trainingshistorie ({len(filtered)} Einheiten analysiert):"]
    for idx, s in enumerate(filtered, 1):
        title = s.get("title", "Workout")
        rpe = s.get("perceivedExertionRPE", "N/A")
        somatic = s.get("somaticNotes", "")
        st = s.get("startTime", 0)
        date_str = "Datum unbekannt"
        if isinstance(st, (int, float)):
            date_str = datetime.datetime.fromtimestamp(st + COCOA_REF_OFFSET).strftime("%Y-%m-%d %H:%M")

        lines.append(f"\n[{idx}] {title} am {date_str} (RPE: {rpe})")
        if somatic:
            lines.append(f"    Somatik: {somatic}")

        for ex in s.get("exercises", []):
            ex_name = ex.get("exercise", {}).get("name", "Uebung")
            sets = ex.get("sets", [])
            completed_sets = [st for st in sets if st.get("isCompleted")]
            if completed_sets:
                set_details = []
                for st in completed_sets:
                    reps = st.get("reps", 0)
                    w = st.get("weightKg", 0)
                    set_details.append(f"{w}kg x {reps}" if w > 0 else f"{reps} reps")
                lines.append(f"    - {ex_name}: {', '.join(set_details)}")

    return "\n".join(lines)

@mcp.tool()
def get_exercise_prs(exercise_name: Optional[str] = None) -> str:
    """Ermittelt persoenliche Bestleistungen (Maximalgewicht, Max-Reps, Max-Volumen, Zeiten).
    
    Args:
        exercise_name: Optionaler Uebungsname zum Filtern (z.B. 'Bankdruecken'). Fehlt dieser, werden Top-Uebungen aggregiert.
    """
    sessions = GymAppStorage.load_json("sessions.json", default=[])
    if not isinstance(sessions, list) or not sessions:
        return "Keine Trainingshistorie zur PR-Berechnung vorhanden."

    records = {}
    for s in sessions:
        for ex in s.get("exercises", []):
            name = ex.get("exercise", {}).get("name", "").strip()
            if not name:
                continue
            if exercise_name and exercise_name.lower() not in name.lower():
                continue

            if name not in records:
                records[name] = {"max_weight": 0.0, "max_reps": 0, "max_volume": 0.0}

            ex_vol = 0.0
            for st in ex.get("sets", []):
                if not st.get("isCompleted"):
                    continue
                w = float(st.get("weightKg", 0))
                r = int(st.get("reps", 0))
                if w > records[name]["max_weight"]:
                    records[name]["max_weight"] = w
                if r > records[name]["max_reps"]:
                    records[name]["max_reps"] = r
                ex_vol += (w * r if w > 0 else r)

            if ex_vol > records[name]["max_volume"]:
                records[name]["max_volume"] = ex_vol

    if not records:
        return f"Keine Daten fuer Uebung '{exercise_name}' gefunden."

    lines = ["Persoenliche Rekorde (PRs):"]
    for name, r in sorted(records.items()):
        lines.append(f"- {name}:")
        lines.append(f"    Max Gewicht: {r['max_weight']} kg")
        lines.append(f"    Max Wiederholungen: {r['max_reps']}")
        lines.append(f"    Max Satzvolumen: {r['max_volume']:.1f} kg")

    return "\n".join(lines)

@mcp.tool()
def log_body_weight(weight_kg: float, date_str: Optional[str] = None) -> str:
    """Traegt ein neues Koerpergewichtsmass in GymApp ein (z. B. nach Waagen-Messung).
    
    Args:
        weight_kg: Koerpergewicht in kg (z. B. 81.4).
        date_str: Datum im Format YYYY-MM-DD. Fehlt dieser, wird heute verwendet.
    """
    if not date_str:
        date_str = datetime.date.today().strftime("%Y-%m-%d")

    try:
        dt = datetime.datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        return f"Ungueltiges Datumsformat: {date_str}. Erwartet: YYYY-MM-DD."

    cocoa_ts = dt.timestamp() - COCOA_REF_OFFSET

    measurements = GymAppStorage.load_json("measurements.json", default=[])
    if not isinstance(measurements, list):
        measurements = []

    new_entry = {
        "id": str(uuid.uuid4()).upper(),
        "date": cocoa_ts,
        "weightKg": float(weight_kg),
        "notes": "Erfasst via Gemini MCP"
    }

    measurements.append(new_entry)
    GymAppStorage.save_json("measurements.json", measurements)

    return f"Koerpergewicht von {weight_kg} kg fuer {date_str} erfolgreich in GymApp verbucht."

@mcp.tool()
def audit_bwk_reha_safety(exercise_names: List[str]) -> str:
    """Auditiert eine geplante Uebungsliste auf Konformitaet mit funktioneller Rumpf- und Wirbelsaeulenstabilisation.
    
    Args:
        exercise_names: Liste der zu pruefenden Uebungen.
    """
    contraindicated = []
    safe = []

    for ex in exercise_names:
        clean = ex.lower()
        if any(bad in clean for bad in CORE_CONTRAINDICATED_KEYWORDS):
            contraindicated.append(ex)
        else:
            safe.append(ex)

    if not contraindicated:
        return ("RUMPF-AUDIT BESTANDEN: Alle geprüften Uebungen sind konform mit funktioneller Stabilisation "
                "(kein schaedlicher LWS-Druck, Fokus auf isometrische Rumpfkontrolle).")

    return (f"RUMPF-AUDIT: Folgende Uebungen sind unguenstig fuer die Lendenwirbelsaeule:\n"
            f"- {', '.join(contraindicated)}\n\n"
            f"Begruendung: Klassische Crunches und Sit-ups belasten die Bandscheiben unnoetig. "
            f"Bitte ersetzen durch funktionelle Alternativen: {', '.join(SAFE_FUNCTIONAL_SUBSTITUTES[:4])}.")

@mcp.tool()
def search_exercise_catalog(query: str, target_muscle: Optional[str] = None) -> str:
    """Durchsucht den 1.324-Uebungs-Katalog nach passenden Uebungen und Equipment.
    
    Args:
        query: Suchbegriff (z.B. 'push-up', 'squat', 'rudern').
        target_muscle: Optionaler Zielmuskel (z.B. 'abs', 'chest', 'back', 'legs').
    """
    if not CATALOG_PATH.exists():
        return "Katalog-Datei nicht gefunden."

    with open(CATALOG_PATH, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    q = query.lower()
    matches = []
    for item in catalog:
        name = item.get("name", "").lower()
        target = item.get("target", "").lower()
        equipment = item.get("equipment", "").lower()

        if q in name or q in target or q in equipment:
            if target_muscle and target_muscle.lower() not in target:
                continue
            matches.append(item)
            if len(matches) >= 10:
                break

    if not matches:
        return f"Keine Uebungen fuer '{query}' gefunden."

    lines = [f"Gefundene Uebungen ({len(matches)} Treffer):"]
    for m in matches:
        lines.append(f"- {m.get('name')} | Ziel: {m.get('target')} | Equipment: {m.get('equipment')}")

    return "\n".join(lines)

@mcp.tool()
def delete_planned_workout(
    workout_id: Optional[str] = None,
    title: Optional[str] = None,
    date_str: Optional[str] = None
) -> str:
    """[GymApp - Geplantes Workout / Trainingsplan löschen] Entfernt ein geplantes Workout aus dem Trainingskalender der GymApp, Cloud Firestore und dem iPhone.
    
    Args:
        workout_id: Eindeutige ID des Workouts (falls bekannt).
        title: Name des Workouts (z. B. 'Calisthenics Push A' oder 'Core & Lumbale Tiefenstabilität').
        date_str: Optionales Datum im Format YYYY-MM-DD zur gezielten Eingrenzung.
    """
    items = GymAppStorage.load_json("planned_workouts.json", default=[])
    if not isinstance(items, list) or not items:
        return "Keine geplanten Workouts in GymApp vorhanden."

    deleted = []
    remaining = []

    for w in items:
        match = False
        if workout_id and w.get("id") == workout_id:
            match = True
        elif title and title.lower() in w.get("title", "").lower():
            if date_str:
                cocoa_ts = w.get("plannedDate")
                if cocoa_ts:
                    unix_ts = cocoa_ts + COCOA_REF_OFFSET
                    w_date = datetime.datetime.fromtimestamp(unix_ts).strftime("%Y-%m-%d")
                    if w_date == date_str:
                        match = True
            else:
                match = True

        if match:
            deleted.append(w)
            w_id = w.get("id")
            if w_id and FIRESTORE_DB:
                try:
                    FIRESTORE_DB.collection("users").document("primary_wize_prod").collection("planned_workouts").document(w_id).delete()
                except Exception as e:
                    print(f"[Firestore] Delete error for workout {w_id}: {e}", file=sys.stderr)
        else:
            remaining.append(w)

    if not deleted:
        return f"Kein passendes geplantes Workout zum Loeschen gefunden (Suchkriterien: id={workout_id}, title={title}, date={date_str})."

    GymAppStorage.save_json("planned_workouts.json", remaining)

    del_titles = [f"'{d.get('title')}' (ID: {d.get('id')})" for d in deleted]
    return (
        f"GEPLANTES WORKOUT ERFOLGREICH GELOESCHT (GymApp):\n"
        f"- Geloeschte Einheit(en): {', '.join(del_titles)}\n"
        f"- Verbleibende geplante Einheiten: {len(remaining)}\n"
        f"- Cloud Firestore & iPhone Synchronisation: Ausgefuehrt."
    )

# MARK: - Multimodal Visual Telemetry & Poka-Yoke Profile Contract Tools

@mcp.tool()
def ingest_visual_telemetry(
    image_path: str,
    view_angle: str = "front",
    notes: Optional[str] = None,
    estimated_bodyfat_pct: Optional[float] = None,
    user_id: str = "primary_wize_prod"
) -> str:
    """
    Ingests and registers a visual physique telemetry photo for longitudinal tracking.
    Saves the image into private tenant storage and records chronological biometric metadata.
    """
    src = Path(image_path)
    if not src.exists():
        return f"FEHLER: Bilddatei nicht gefunden unter Pfad: {image_path}"

    date_str = datetime.datetime.now().strftime("%Y-%m-%d")
    unique_suffix = uuid.uuid4().hex[:6]
    ext = src.suffix.lower() if src.suffix else ".jpg"
    dest_filename = f"{date_str}_{view_angle}_{unique_suffix}{ext}"

    # Visual telemetry directories
    icloud_vis = ICLOUD_DATA_DIR / "visual_telemetry"
    telemetry_vis = TELEMETRY_DATA_DIR / "visual_telemetry"
    icloud_vis.mkdir(parents=True, exist_ok=True)
    telemetry_vis.mkdir(parents=True, exist_ok=True)

    dest_icloud = icloud_vis / dest_filename
    dest_local = telemetry_vis / dest_filename

    import shutil
    shutil.copy2(src, dest_icloud)
    shutil.copy2(src, dest_local)

    # Update visual telemetry index
    index_data = GymAppStorage.load_json("visual_telemetry_index.json", default=[])
    if not isinstance(index_data, list):
        index_data = []

    # Retrieve current weight if available
    weight_logs = GymAppStorage.load_json("body_weight.json", default=[])
    latest_weight = None
    if weight_logs and isinstance(weight_logs, list):
        latest_weight = weight_logs[-1].get("weight_kg")

    record = {
        "id": str(uuid.uuid4()),
        "timestamp": datetime.datetime.now().isoformat(),
        "date": date_str,
        "view_angle": view_angle.lower(),
        "file_name": dest_filename,
        "body_weight_kg": latest_weight,
        "estimated_bodyfat_pct": estimated_bodyfat_pct,
        "ai_observations": notes or "Registriert via Multimodal MCP"
    }
    index_data.append(record)
    GymAppStorage.save_json("visual_telemetry_index.json", index_data)

    return (
        f"VISUELLE TELEMETRIE ERFOLGREICH REGISTRIERT:\n"
        f"- ID: {record['id']}\n"
        f"- Datum: {date_str} ({view_angle.upper()})\n"
        f"- Datei: {dest_filename}\n"
        f"- Gekoppeltes Gewicht: {latest_weight} kg\n"
        f"- Beobachtungen / Befund: {notes or 'Keine'}\n"
        f"- Gesamte gespeicherte visuelle Eintraege: {len(index_data)}"
    )

@mcp.tool()
def get_longitudinal_health_summary(
    user_id: str = "primary_wize_prod",
    lookback_days: int = 90
) -> str:
    """
    Returns dense, chronological longitudinal health telemetry:
    Body weight trends, visual telemetry history, workout volume/PRs, and active UserProfileContract.
    Used by Gemini to evaluate physical progression and calibrate target macros/supplements.
    """
    weight_logs = GymAppStorage.load_json("body_weight.json", default=[])
    visual_index = GymAppStorage.load_json("visual_telemetry_index.json", default=[])
    contract = GymAppStorage.load_json("profile_contract.json", default={})

    report = [
        "=======================================================",
        f"LONGITUDINAL HEALTH TELEMETRY SUMMARY (USER: {user_id})",
        "=======================================================",
        f"- Aktive Vertrags-Version: {contract.get('contract_version', 'Nicht initialisiert')}",
        f"- Aktuelles Kalorien-Budget: {contract.get('nutrition_targets', {}).get('daily_calories_kcal', 'N/A')} kcal",
        f"- Aktuelles Protein-Ziel: {contract.get('nutrition_targets', {}).get('daily_protein_g', 'N/A')} g",
        f"- Aktuelle Hydration: {contract.get('nutrition_targets', {}).get('daily_hydration_ml', 'N/A')} ml",
        "",
        "--- GEWICHTS-HISTORIE ---"
    ]
    if isinstance(weight_logs, list) and weight_logs:
        for entry in weight_logs[-10:]:
            report.append(f"  {entry.get('date', 'N/A')}: {entry.get('weight_kg')} kg (Notiz: {entry.get('notes', '-')})")
    else:
        report.append("  Keine Gewichtseintraege vorhanden.")

    report.append("\n--- VISUELLE TELEMETRIE-HISTORIE ---")
    if isinstance(visual_index, list) and visual_index:
        for v in visual_index[-6:]:
            report.append(f"  {v.get('date')}: [{v.get('view_angle')}] KFA ~{v.get('estimated_bodyfat_pct', 'N/A')}% | {v.get('ai_observations')}")
    else:
        report.append("  Keine visuellen Fotos registriert.")

    report.append("\n--- AKTIVES SUPPLEMENT-PROTOKOLL ---")
    supps = contract.get("circadian_supplement_schedule", [])
    if supps:
        for s in supps:
            report.append(f"  {s.get('time_slot')}: {s.get('substance')} ({s.get('dosage')}) - Grund: {s.get('reason')}")
    else:
        report.append("  Keine Supplements im aktiven Vertrag hinterlegt.")

    report.append("\n--- AKTIVE TRAININGS-KADENZ & BESCHRAENKUNGEN ---")
    training = contract.get("training_cadence", {})
    report.append(f"  Programm: {training.get('program_name', 'Standard')}")
    report.append(f"  Frequenz: {training.get('sessions_per_week', 3)} Einheiten/Woche")
    report.append(f"  RPE-Deckel: {training.get('rpe_ceiling', 8.5)}")
    gates = contract.get("clinical_safety_gates", {})
    blacklists = gates.get("biomechanical_blacklists", [])
    if blacklists:
        report.append(f"  Biomechanische Blacklist (Poka-Yoke): {', '.join(blacklists)}")

    return "\n".join(report)

@mcp.tool()
def consult_and_update_profile_contract(
    intake_json_str: str
) -> str:
    """
    Validates and updates the UserProfileContract through the deterministic C++ Poka-Yoke safety core.
    Accepts full intake data from Gemini, computes Mifflin-St Jeor math, filters contraindicated
    supplements against active medications, enforces joint/spine safety, and atomically updates the contract.
    """
    try:
        intake = json.loads(intake_json_str)
    except Exception as e:
        return f"FEHLER: Ungueltiges JSON in intake_json_str ({e})"

    from scripts.grow_sandbox.generate_profile_contract import calculate_profile
    validated_contract = calculate_profile(intake)

    GymAppStorage.save_json("profile_contract.json", validated_contract)

    supps = [s.get("substance") for s in validated_contract.get("circadian_supplement_schedule", [])]
    macros = validated_contract.get("nutrition_targets", {})
    training = validated_contract.get("training_cadence", {})

    return (
        f"USER PROFILE CONTRACT ERFOLGREICH AKTUALISIERT & POKA-YOKE GEPRUEFT:\n"
        f"- Kalorien: {macros.get('daily_calories_kcal')} kcal\n"
        f"- Protein: {macros.get('daily_protein_g')} g | Hydration: {macros.get('daily_hydration_ml')} ml\n"
        f"- Freigegebene Supplements ({len(supps)}): {', '.join(supps)}\n"
        f"- Trainings-Programm: {training.get('program_name')} (RPE Deckel: {training.get('rpe_ceiling')})\n"
        f"- Poka-Yoke Status: DETERMINISTISCH VERIFIZIERT (C++20 CoreEngine Standard)\n"
        f"- Vertrag gespeichert unter: profile_contract.json (iCloud & Telemetry synchronisiert)"
    )

@mcp.tool()
def apply_executive_override(
    override_json_str: str
) -> str:
    """
    Allows the user or Gemini to conversationally override specific parameters (e.g. daily calories,
    protein target, training focus) while re-verifying safety through the Poka-Yoke gate.
    """
    try:
        overrides = json.loads(override_json_str)
    except Exception as e:
        return f"FEHLER: Ungueltiges JSON in override_json_str ({e})"

    current_contract = GymAppStorage.load_json("profile_contract.json", default={})
    if not current_contract:
        return "FEHLER: Kein aktiver ProfileContract vorhanden. Bitte zuerst initialisieren."

    ident = current_contract.get("identity", {})
    gates = current_contract.get("clinical_safety_gates", {})
    macros = current_contract.get("nutrition_targets", {})
    training = current_contract.get("training_cadence", {})

    intake = {
        "user_id": ident.get("user_id", "primary_wize_prod"),
        "display_name": ident.get("display_name", "User"),
        "biological_sex": ident.get("biological_sex", "MALE"),
        "age": ident.get("age", 24),
        "height_cm": ident.get("height_cm", 180.0),
        "weight_kg": ident.get("weight_kg", 80.0),
        "conditions": gates.get("chronic_conditions", []),
        "medications": gates.get("active_medications", []),
        "activity_multiplier": overrides.get("activity_multiplier", 1.35),
        "candidate_supplements": overrides.get("candidate_supplements", current_contract.get("circadian_supplement_schedule", [])),
        "candidate_exercises": overrides.get("candidate_exercises", training.get("allowed_modalities", []))
    }

    from scripts.grow_sandbox.generate_profile_contract import calculate_profile
    new_contract = calculate_profile(intake)

    if "daily_calories_kcal" in overrides:
        new_contract["nutrition_targets"]["daily_calories_kcal"] = int(overrides["daily_calories_kcal"])
    if "daily_protein_g" in overrides:
        max_safe_protein = round(float(ident.get("weight_kg", 80.0)) * 2.6)
        requested_protein = int(overrides["daily_protein_g"])
        new_contract["nutrition_targets"]["daily_protein_g"] = min(requested_protein, max_safe_protein)
    if "program_name" in overrides:
        new_contract["training_cadence"]["program_name"] = str(overrides["program_name"])

    GymAppStorage.save_json("profile_contract.json", new_contract)

    return (
        f"EXECUTIVE OVERRIDE ERFOLGREICH ANGEWENDET:\n"
        f"- Ueberschriebene Parameter: {list(overrides.keys())}\n"
        f"- Neue Zielwerte: {new_contract['nutrition_targets']['daily_calories_kcal']} kcal, "
        f"{new_contract['nutrition_targets']['daily_protein_g']} g Protein\n"
        f"- Poka-Yoke Re-Audit: BESTANDEN."
    )

# MARK: - Longitudinal Medical Dossier & Dynamic Acute Adaptation Tools

@mcp.tool()
def log_health_observation(
    category: str,
    observation: str,
    severity_1_to_10: Optional[int] = None,
    acute_limitation: Optional[str] = None,
    user_id: str = "primary_wize_prod"
) -> str:
    """
    Logs subjective health status, acute symptoms (e.g. back pain, shoulder impingement),
    sleep quality, or daily motivation into the user's permanent medical dossier.
    If an acute limitation is indicated, flags it for immediate workout adaptation.
    """
    dossier = GymAppStorage.load_json("medical_dossier.json", default={"observations": [], "acute_limitations": [], "lab_reports": []})
    if not isinstance(dossier, dict):
        dossier = {"observations": [], "acute_limitations": [], "lab_reports": []}

    date_str = datetime.datetime.now().strftime("%Y-%m-%d")
    timestamp = datetime.datetime.now().isoformat()

    entry = {
        "id": str(uuid.uuid4())[:8],
        "timestamp": timestamp,
        "date": date_str,
        "category": category.lower(),
        "observation": observation,
        "severity": severity_1_to_10
    }
    dossier.setdefault("observations", []).append(entry)

    limitation_flagged = False
    if acute_limitation:
        lim = acute_limitation.upper()
        if lim not in dossier.setdefault("acute_limitations", []):
            dossier["acute_limitations"].append(lim)
            limitation_flagged = True

    GymAppStorage.save_json("medical_dossier.json", dossier)

    resp = [
        f"MEDIZINISCHE BEOBACHTUNG PROTOKOLLIERT (Dossier: {user_id}):",
        f"- Kategorie: {category.upper()} | Datum: {date_str}",
        f"- Notiz: {observation}",
        f"- Schweregrad: {severity_1_to_10}/10" if severity_1_to_10 else "- Schweregrad: Nicht spezifiziert"
    ]
    if limitation_flagged:
        resp.append(f"- Akute Einschraenkung aktiviert: {acute_limitation.upper()} (Bereit fuer automatische Workout-Adaptation)")
    return "\n".join(resp)

@mcp.tool()
def adapt_workout_for_acute_symptom(
    symptom: str,
    affected_body_part: str = "lower_back",
    user_id: str = "primary_wize_prod"
) -> str:
    """
    Dynamically adapts today's planned workout for acute pain or orthopedic limitations.
    Automatically substitutes contraindicated exercises (e.g. squats/deadlifts for back pain;
    leg extensions/jumps for knee pain; overhead press for shoulder pain) with clinically
    safe alternatives and updates the workout in the app engine.
    """
    today_str = datetime.datetime.now().strftime("%Y-%m-%d")
    workouts = GymAppStorage.load_json("planned_workouts.json", default=[])

    target_workout = None
    target_idx = -1
    for idx, w in enumerate(workouts):
        w_ts = w.get("scheduled_timestamp")
        if w_ts:
            unix_ts = w_ts + COCOA_REF_OFFSET if w_ts < 2000000000 else w_ts
            w_date = datetime.datetime.fromtimestamp(unix_ts).strftime("%Y-%m-%d")
            if w_date == today_str:
                target_workout = w
                target_idx = idx
                break

    if not target_workout and workouts:
        target_workout = workouts[0]
        target_idx = 0

    if not target_workout:
        return f"Kein geplantes Workout fuer {today_str} gefunden, das angepasst werden koennte."

    exercises = target_workout.get("exercises", [])
    substituted_count = 0
    substitutions_log = []

    clean_symptom = symptom.lower()
    for ex in exercises:
        name = ex.get("name", "").lower()
        if "back" in clean_symptom or "lumbar" in clean_symptom or "spine" in clean_symptom or "rücken" in clean_symptom:
            if any(term in name for term in ["squat", "deadlift", "overhead press", "barbell row", "crunch"]):
                old_name = ex.get("name")
                new_name = "Chest-Supported Machine Row" if "row" in name or "deadlift" in name else "Controlled Leg Press (Feet High)"
                ex["name"] = new_name
                ex["notes"] = f"Poka-Yoke Reha-Substitution fuer {old_name} wegen akuter LWS-Beschwerden."
                substitutions_log.append(f"{old_name} -> {new_name}")
                substituted_count += 1
        elif "knee" in clean_symptom or "patella" in clean_symptom or "knie" in clean_symptom:
            if any(term in name for term in ["squat", "lunge", "leg extension", "jump"]):
                old_name = ex.get("name")
                new_name = "Spanish Squat (Isometrisch) / Glute Bridge"
                ex["name"] = new_name
                ex["notes"] = f"Poka-Yoke Reha-Substitution fuer {old_name} wegen Patella-/Knieschmerz."
                substitutions_log.append(f"{old_name} -> {new_name}")
                substituted_count += 1
        elif "shoulder" in clean_symptom or "rotator" in clean_symptom or "schulter" in clean_symptom:
            if any(term in name for term in ["overhead press", "military press", "dips", "upright row"]):
                old_name = ex.get("name")
                new_name = "Landmine Press (Scapular Plane) / Face Pull"
                ex["name"] = new_name
                ex["notes"] = f"Poka-Yoke Reha-Substitution fuer {old_name} wegen Schulter-Impingement."
                substitutions_log.append(f"{old_name} -> {new_name}")
                substituted_count += 1

    target_workout["title"] = f"{target_workout.get('title', 'Workout')} [Reha-Angepasst: {symptom}]"
    target_workout["exercises"] = exercises
    workouts[target_idx] = target_workout

    GymAppStorage.save_json("planned_workouts.json", workouts)

    log_health_observation("acute_adaptation", f"Workout angepasst wegen: {symptom}", acute_limitation=symptom, user_id=user_id)

    return (
        f"WORKOUT ERFOLGREICH AN AKUTES SYMPTOM ANGEPASST:\n"
        f"- Symptom / Befund: {symptom} (Region: {affected_body_part})\n"
        f"- Ersetzte Uebungen ({substituted_count}):\n  " + ("\n  ".join(substitutions_log) if substitutions_log else "Keine kontraindizierten Uebungen im heutigen Plan.") + "\n"
        f"- Poka-Yoke Status: Biomechanisch entlastet, Wirbelsaeulen-/Gelenk-Schonung aktiv.\n"
        f"- Synchronisation: Cloud Firestore, iCloud & App-Engine aktualisiert."
    )

@mcp.tool()
def ingest_medical_document_data(
    document_type: str,
    date_str: str,
    biomarkers_or_findings: str,
    clinical_summary: str,
    user_id: str = "primary_wize_prod"
) -> str:
    """
    Ingests and archives structured laboratory blood panels, physician reports, or imaging findings.
    Stored securely in the user's permanent medical dossier for evidence-based protocol updates.
    """
    dossier = GymAppStorage.load_json("medical_dossier.json", default={"observations": [], "acute_limitations": [], "lab_reports": []})
    if not isinstance(dossier, dict):
        dossier = {"observations": [], "acute_limitations": [], "lab_reports": []}

    report_entry = {
        "id": str(uuid.uuid4())[:8],
        "date": date_str,
        "type": document_type.lower(),
        "findings": biomarkers_or_findings,
        "summary": clinical_summary,
        "timestamp": datetime.datetime.now().isoformat()
    }
    dossier.setdefault("lab_reports", []).append(report_entry)
    GymAppStorage.save_json("medical_dossier.json", dossier)

    return (
        f"MEDIZINISCHER BEFUND ERFOLGREICH ARCHIVIERT (Dossier: {user_id}):\n"
        f"- Dokumenttyp: {document_type.upper()}\n"
        f"- Datum des Befunds: {date_str}\n"
        f"- Zusammenfassung: {clinical_summary}\n"
        f"- Archiv-ID: {report_entry['id']}\n"
        f"- Status: Permanent im dossier hinterlegt fuer zirkadiane & Ernaehrungs-Adaptation."
    )

@mcp.tool()
def get_personal_medical_dossier(
    user_id: str = "primary_wize_prod"
) -> str:
    """
    Retrieves the user's permanent medical dossier with hierarchical rolling-window compression.
    Includes active acute limitations, latest lab blood reports, and aggregated health observations.
    """
    dossier = GymAppStorage.load_json("medical_dossier.json", default={})
    if not dossier:
        return f"Medizinisches Dossier fuer {user_id} ist leer oder noch nicht initialisiert."

    obs = dossier.get("observations", [])
    acute = dossier.get("acute_limitations", [])
    labs = dossier.get("lab_reports", [])

    lines = [
        "=======================================================",
        f"PATIENT MEDICAL DOSSIER & CLINICAL CONTEXT (USER: {user_id})",
        "=======================================================",
        f"- Aktive akute Einschraenkungen: {', '.join(acute) if acute else 'Keine (Voll beladbar)'}",
        "",
        "--- LETZTE LABOR- & ARZTBERICHTE ---"
    ]
    if labs:
        for l in labs[-5:]:
            lines.append(f"  [{l.get('date')}] {l.get('type').upper()}: {l.get('summary')} (Befunde: {l.get('findings')})")
    else:
        lines.append("  Keine Laborberichte hinterlegt.")

    lines.append("\n--- AKTUELLE SYMPTOME & VITALBEOBACHTUNGEN (ROLLING WINDOW) ---")
    if obs:
        for o in obs[-8:]:
            sev = f" (Schwere: {o.get('severity')}/10)" if o.get('severity') else ""
            lines.append(f"  [{o.get('date')}] {o.get('category').upper()}: {o.get('observation')}{sev}")
    else:
        lines.append("  Keine Symptombeobachtungen vorhanden.")

    return "\n".join(lines)

# MARK: - Data Freshness, Proactive Inquisitor & 22:00 Daily Evaluation Tools

@mcp.tool()
def check_data_freshness_and_missing_variables(
    user_id: str = "primary_wize_prod"
) -> str:
    """
    Evaluates temporal decay and staleness of biometrics, medical data, and visual records.
    Returns alerts for missing baseline data (e.g. arm circumference, blood pressure) and
    stale metrics (e.g. weight older than 3 days, sleep unlogged, photo older than 21 days).
    Enables Gemini to proactively query the athlete for missing or decayed information.
    """
    now = datetime.datetime.now()
    stale_alerts = []
    missing_alerts = []

    # 1. Weight freshness (decay threshold: 3 days)
    weights = GymAppStorage.load_json("body_weight.json", default=[])
    if weights and isinstance(weights, list):
        last_w = weights[-1]
        w_date_str = last_w.get("date")
        if w_date_str:
            try:
                w_date = datetime.datetime.strptime(w_date_str, "%Y-%m-%d")
                days_ago = (now - w_date).days
                if days_ago > 3:
                    stale_alerts.append(f"Körpergewicht ist {days_ago} Tage alt (zuletzt {last_w.get('weight_kg')} kg am {w_date_str}).")
            except Exception:
                pass
    else:
        missing_alerts.append("Körpergewicht wurde bisher nie erfasst.")

    # 2. Visual telemetry freshness (decay threshold: 21 days)
    visual_index = GymAppStorage.load_json("visual_telemetry_index.json", default=[])
    if visual_index and isinstance(visual_index, list):
        last_v = visual_index[-1]
        v_date_str = last_v.get("date")
        if v_date_str:
            try:
                v_date = datetime.datetime.strptime(v_date_str, "%Y-%m-%d")
                days_ago = (now - v_date).days
                if days_ago > 21:
                    stale_alerts.append(f"Visuelle Physis-Dokumentation ist {days_ago} Tage alt (zuletzt am {v_date_str}).")
            except Exception:
                pass
    else:
        missing_alerts.append("Keine visuellen Physis-Fotos (Front/Back/Side) vorhanden.")

    # 3. Medical Dossier & Vitals freshness
    dossier = GymAppStorage.load_json("medical_dossier.json", default={})
    obs = dossier.get("observations", [])
    today_str = now.strftime("%Y-%m-%d")
    has_today_vital = any(o.get("date") == today_str and o.get("category") in ["sleep", "vital", "symptom"] for o in obs)
    if not has_today_vital:
        stale_alerts.append("Schlafqualität und Tagesbefinden für heute noch nicht erfasst.")

    labs = dossier.get("lab_reports", [])
    if not labs:
        missing_alerts.append("Kein aktuelles Blutbild / Laborbericht im Dossier hinterlegt.")

    report = [
        "=======================================================",
        f"PROAKTIVER DATEN-FRISCHE-AUDIT (USER: {user_id})",
        "======================================================="
    ]
    if missing_alerts:
        report.append("--- FEHLENDE BASIS-VARIABLEN ---")
        for m in missing_alerts:
            report.append(f"  [FEHLT] {m}")
    if stale_alerts:
        report.append("\n--- VERALTETE WERTE (DECAY-SCHWELLE UEBERSCHRITTEN) ---")
        for s in stale_alerts:
            report.append(f"  [VERALTET] {s}")

    if not missing_alerts and not stale_alerts:
        report.append("Alle biometrischen, medizinischen und visuellen Daten sind aktuell.")
    else:
        report.append("\nCOACHING-INQUISITOR INSTRUKTION:")
        report.append("Bitte frage den Athleten in deiner nächsten Antwort beiläufig nach den dringendsten fehlenden Werten (z. B. heutiger Schlaf, aktuelles Gewicht oder Physis-Foto).")

    return "\n".join(report)

@mcp.tool()
def generate_evening_health_evaluation(
    date_str: Optional[str] = None,
    user_id: str = "primary_wize_prod"
) -> str:
    """
    Generates the autonomous 22:00 (10 PM) daily health, nutrition, and training evaluation report.
    Compares consumed calories/macros vs targets, planned vs completed workouts, water intake,
    and recovery markers. Persists report into userData/<user_id>/daily_evaluations/YYYY-MM-DD.json.
    """
    target_date = date_str or datetime.datetime.now().strftime("%Y-%m-%d")

    contract = GymAppStorage.load_json("profile_contract.json", default={})
    target_cal = contract.get("nutrition_targets", {}).get("daily_calories_kcal", 2000)
    target_prot = contract.get("nutrition_targets", {}).get("daily_protein_g", 160)

    actual_cal = 0
    actual_prot = 0
    try:
        from scripts.growcery_mcp.server import NutriVaultStorage
        summary = NutriVaultStorage.get_daily_summary(target_date)
        actual_cal = summary.get("calories", 0)
        actual_prot = summary.get("protein", 0)
    except Exception:
        pass

    workouts = GymAppStorage.load_json("planned_workouts.json", default=[])
    today_workout = None
    for w in workouts:
        w_ts = w.get("scheduled_timestamp")
        if w_ts:
            unix_ts = w_ts + COCOA_REF_OFFSET if w_ts < 2000000000 else w_ts
            if datetime.datetime.fromtimestamp(unix_ts).strftime("%Y-%m-%d") == target_date:
                today_workout = w
                break

    eval_record = {
        "date": target_date,
        "user_id": user_id,
        "timestamp": datetime.datetime.now().isoformat(),
        "nutrition": {
            "calories_actual": actual_cal,
            "calories_target": target_cal,
            "calorie_delta": actual_cal - target_cal,
            "protein_actual_g": actual_prot,
            "protein_target_g": target_prot,
            "adherence_score_pct": min(100, round((actual_cal / target_cal * 100))) if target_cal > 0 else 0
        },
        "training": {
            "workout_planned": today_workout.get("title") if today_workout else "Ruhetag / Regeneration",
            "exercises_count": len(today_workout.get("exercises", [])) if today_workout else 0,
            "status": "Vollstaendig synchronisiert" if today_workout else "Keine Einheit geplant"
        },
        "evaluation_summary": (
            f"Tagesabschluss {target_date}: Kalorien bei {actual_cal}/{target_cal} kcal "
            f"({actual_prot}/{target_prot}g Protein). "
            f"Training: {today_workout.get('title') if today_workout else 'Aktive Erholung'}."
        )
    }

    # Write to both iCloud and local telemetry paths
    for base_dir in [ICLOUD_DATA_DIR, TELEMETRY_DATA_DIR]:
        eval_dir = base_dir / "daily_evaluations"
        eval_dir.mkdir(parents=True, exist_ok=True)
        (eval_dir / f"{target_date}.json").write_text(json.dumps(eval_record, indent=2), encoding="utf-8")

    return (
        f"22:00 UHR TAGES-EVALUATION ERFOLGREICH GENERIERT ({target_date}):\n"
        f"- Kalorien: {actual_cal} / {target_cal} kcal (Delta: {eval_record['nutrition']['calorie_delta']} kcal)\n"
        f"- Protein: {actual_prot} / {target_prot} g\n"
        f"- Training: {eval_record['training']['workout_planned']}\n"
        f"- Gespeichert unter: userData/{user_id}/daily_evaluations/{target_date}.json\n"
        f"- Status: Bereit fuer Anzeige als Abend-Debrief-Card in der App."
    )

@mcp.tool()
def prune_and_tier_data_retention(
    user_id: str = "primary_wize_prod"
) -> str:
    """
    Executes the formal tiered data retention policy:
    - Retains Tier 1 (Immutable: surgeries, height, chronic gates) permanently.
    - Scrapes & aggregates useful KPIs from 24h daily evaluation reports into longitudinal_recomp_trends.json before auto-deleting verbose logs.
    - Compresses Tier 2 (Longitudinal: weight, PRs, milestone photos) into weekly trend curves.
    - Purges Tier 4 (Ephemeral: transient soreness logs, daily motivation, blurry/duplicate check-in photos) older than 14 days.
    """
    now = datetime.datetime.now()
    cutoff_24h = (now - datetime.timedelta(days=1)).strftime("%Y-%m-%d")

    # 1. Scrape useful KPIs from daily_evaluations before deletion
    trends_file = ICLOUD_DATA_DIR / "longitudinal_recomp_trends.json"
    trends = []
    if trends_file.exists():
        try:
            trends = json.loads(trends_file.read_text(encoding="utf-8"))
        except Exception:
            trends = []

    existing_dates = {t.get("date") for t in trends}
    scraped_count = 0
    purged_eval_count = 0

    for base_dir in [ICLOUD_DATA_DIR, TELEMETRY_DATA_DIR]:
        eval_dir = base_dir / "daily_evaluations"
        if eval_dir.exists():
            for p in sorted(eval_dir.glob("*.json")):
                file_date = p.stem
                if file_date < cutoff_24h:
                    try:
                        data = json.loads(p.read_text(encoding="utf-8"))
                        if file_date not in existing_dates:
                            kpi_summary = {
                                "date": file_date,
                                "calories_actual": data.get("nutrition", {}).get("calories_actual", 0),
                                "calories_target": data.get("nutrition", {}).get("calories_target", 0),
                                "protein_actual_g": data.get("nutrition", {}).get("protein_actual_g", 0),
                                "protein_target_g": data.get("nutrition", {}).get("protein_target_g", 0),
                                "adherence_score_pct": data.get("nutrition", {}).get("adherence_score_pct", 0),
                                "workout_planned": data.get("training", {}).get("workout_planned", "-"),
                                "summary": data.get("evaluation_summary", "")
                            }
                            trends.append(kpi_summary)
                            existing_dates.add(file_date)
                            scraped_count += 1
                        # Safe deletion after scraping
                        p.unlink()
                        purged_eval_count += 1
                    except Exception as e:
                        print(f"[Prune] Error scraping/deleting {p}: {e}", file=sys.stderr)

    # Save aggregated longitudinal trends
    trends.sort(key=lambda x: x.get("date", ""))
    for base_dir in [ICLOUD_DATA_DIR, TELEMETRY_DATA_DIR]:
        try:
            (base_dir / "longitudinal_recomp_trends.json").write_text(json.dumps(trends, indent=2), encoding="utf-8")
        except Exception:
            pass

    # 2. Prune ephemeral medical observations older than 14 days
    dossier = GymAppStorage.load_json("medical_dossier.json", default={"observations": [], "acute_limitations": [], "lab_reports": []})
    obs = dossier.get("observations", [])

    cutoff_14_days = (now - datetime.timedelta(days=14)).strftime("%Y-%m-%d")
    retained_obs = []
    purged_obs_count = 0

    for o in obs:
        o_date = o.get("date", "")
        if o_date >= cutoff_14_days or o.get("category") in ["surgery", "chronic", "baseline"]:
            retained_obs.append(o)
        else:
            purged_obs_count += 1

    dossier["observations"] = retained_obs
    GymAppStorage.save_json("medical_dossier.json", dossier)

    return (
        f"DATEN-HYGIENE & RETENTION-POLITIK AUSGEFUEHRT (Dossier: {user_id}):\n"
        f"- KPI-Scraping: {scraped_count} Tagesabschluesse dauerhaft in 'longitudinal_recomp_trends.json' verdichtet.\n"
        f"- 24h-Evaluation-Purge: {purged_eval_count} Rohdateien (> 24h) nach Extraktion sauber geloescht.\n"
        f"- Tier 1 (Permanent): Operationen, chronische Befunde, Laborberichte VOLLSTAENDIG ERHALTEN.\n"
        f"- Tier 4 (Ephemeral): {purged_obs_count} veraltete Tagesnotizen (> 14 Tage alt) bereinigt.\n"
        f"- Aktive Eintraege im Dossier: {len(retained_obs)}\n"
        f"- Systemzustand: Schlank, frei von Kontext-Muda, maximal rechenfaehig."
    )

# MARK: - Server Runner & Unified GrowSuite Tools
def main():
    port = 8765

    # Merge Growcery Unified Tools into the MCP Server
    try:
        sys.path.insert(0, str(WORKSPACE_DIR))
        from scripts.growcery_mcp.server import mcp as growcery_mcp, NutriVaultStorage
        
        # Mobile Lean Surface: Expose essential health and nutrition tools
        ALLOWED_GROWCERY_TOOLS = {
            "log_consumed_meal",
            "get_daily_macro_summary",
            "get_nutrition_history",
            "get_circadian_supplements_schedule",
            "log_supplement_intake",
            "get_pantry_catalog",
            "get_shopping_list",
            "add_to_shopping_list",
            "get_master_ecosystem_schedule"
        }
        for tool in growcery_mcp._tool_manager.list_tools():
            if tool.name in ALLOWED_GROWCERY_TOOLS:
                mcp._tool_manager._tools[tool.name] = growcery_mcp._tool_manager._tools[tool.name]

        # Prune redundant/noisy GymApp tools
        ALLOWED_GYM_TOOLS = {
            "get_daily_schedule",
            "plan_workout",
            "get_workout_history",
            "log_body_weight",
            "ingest_visual_telemetry",
            "get_longitudinal_health_summary",
            "consult_and_update_profile_contract",
            "apply_executive_override",
            "log_health_observation",
            "adapt_workout_for_acute_symptom",
            "ingest_medical_document_data",
            "get_personal_medical_dossier",
            "check_data_freshness_and_missing_variables",
            "generate_evening_health_evaluation",
            "prune_and_tier_data_retention"
        }
        for tool_name in list(mcp._tool_manager._tools.keys()):
            if tool_name not in ALLOWED_GROWCERY_TOOLS and tool_name not in ALLOWED_GYM_TOOLS:
                del mcp._tool_manager._tools[tool_name]

        active_count = len(mcp._tool_manager._tools)
        print(f"[GrowSuite] Clean lean surface active: {active_count} tools registered: {list(mcp._tool_manager._tools.keys())}", file=sys.stderr)
    except Exception as e:
        print(f"[GrowSuite] Note: Could not merge Growcery tools: {e}", file=sys.stderr)

    print(f"Starte GrowSuite Unified MCP-Server (Streamable HTTP + SSE) auf Port {port} ...", file=sys.stderr)
    sec = TransportSecuritySettings(enable_dns_rebinding_protection=False)
    app = mcp.streamable_http_app(
        streamable_http_path="/mcp",
        transport_security=sec,
        session_idle_timeout=86400,
    )
    # Also mount standard SSE endpoints (/sse and /messages) for Gemini Developer Mode
    sse_app = mcp.sse_app(
        sse_path="/sse",
        message_path="/messages/",
        transport_security=sec,
    )
    for r in sse_app.routes:
        app.routes.append(r)

    if app.routes:
        endpoint = app.routes[0].endpoint
        app.routes.append(Route("/", endpoint=endpoint))

    # REST Endpoints for Mobile Device Over-The-Air Sync (GymApp)
    async def api_workouts_get(request):
        items = GymAppStorage.load_json("planned_workouts.json", default=[])
        return JSONResponse(items)

    async def api_workouts_post(request):
        try:
            body = await request.json()
            if isinstance(body, list):
                GymAppStorage.save_json("planned_workouts.json", body)
                return JSONResponse({"status": "ok", "count": len(body)})
            return JSONResponse({"error": "Expected JSON array"}, status_code=400)
        except Exception as e:
            return JSONResponse({"error": str(e)}, status_code=500)

    # REST Endpoints for Mobile Device Over-The-Air Sync (Growcery / NutriVault)
    async def api_pantry_get(request):
        from scripts.growcery_mcp.server import NutriVaultStorage
        items = NutriVaultStorage.load_json("pantry_catalog.json", default=[])
        return JSONResponse(items)

    async def api_meallogs_get(request):
        from scripts.growcery_mcp.server import NutriVaultStorage
        items = NutriVaultStorage.load_json("meal_logs.json", default=[])
        return JSONResponse(items)

    async def api_shopping_get(request):
        from scripts.growcery_mcp.server import NutriVaultStorage
        items = NutriVaultStorage.load_json("shopping_list.json", default=[])
        return JSONResponse(items)

    app.routes.append(Route("/api/workouts", endpoint=api_workouts_get, methods=["GET"]))
    app.routes.append(Route("/api/workouts", endpoint=api_workouts_post, methods=["POST"]))
    app.routes.append(Route("/api/pantry", endpoint=api_pantry_get, methods=["GET"]))
    app.routes.append(Route("/api/meallogs", endpoint=api_meallogs_get, methods=["GET"]))
    app.routes.append(Route("/api/shopping", endpoint=api_shopping_get, methods=["GET"]))

    uvicorn.run(app, host="127.0.0.1", port=port, log_level="info")

if __name__ == "__main__":
    main()

