#!/usr/bin/env python3
"""
Sync all items from local pantry catalog to Supabase products table.
"""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

SUPABASE_URL = "https://oqhqpkayzkmnbcmbqkmm.supabase.co"
SUPABASE_KEY = "sb_publishable_Nd7hRD_Fp6no6X-NMnbuPQ_pLxJ-iNR"

def get_simulator_pantry_path() -> Path:
    try:
        sim_out = subprocess.run(["xcrun", "simctl", "list", "devices", "booted"], capture_output=True, text=True, timeout=2).stdout
        for line in sim_out.splitlines():
            if "(" in line and ")" in line:
                udid = line.split("(")[1].split(")")[0]
                res = subprocess.run(["xcrun", "simctl", "get_app_container", udid, "com.nkembi.somagym", "data"], capture_output=True, text=True, timeout=2)
                if res.returncode == 0 and res.stdout.strip():
                    p = Path(res.stdout.strip()) / "Documents" / "userData" / "primary_wize_prod" / "pantry_catalog.json"
                    if p.exists():
                        return p
    except Exception:
        pass
    fallback = Path("/Users/parris-campbellnkembi/Developer/GrowWorkspace/Telemetry/Grow/pantry_catalog.json")
    return fallback

def sync_products():
    pantry_path = get_simulator_pantry_path()
    if not pantry_path.exists():
        print(f"Pantry file not found at {pantry_path}")
        return

    with open(pantry_path, "r", encoding="utf-8") as f:
        items = json.load(f)

    print(f"Loaded {len(items)} items from {pantry_path}")

    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }

    records = []
    for item in items:
        barcode = (item.get("barcode") or "").strip()
        item_id = (item.get("id") or "").strip()
        code = barcode if barcode else item_id
        if not code:
            continue

        raw_ns = str(item.get("nutriscore") or "").strip().lower()
        clean_ns = raw_ns if len(raw_ns) <= 4 and raw_ns != "unknown" else ""

        rec = {
            "barcode": code,
            "name": (item.get("name") or "")[:255],
            "brand": (item.get("brand") or "")[:128],
            "category": (item.get("category") or "Lebensmittel")[:64],
            "pack_qty": float(item.get("defaultPackQty") or 1.0),
            "unit": (item.get("unit") or "g")[:32],
            "price_reference": float(item.get("defaultPrice") or 0.0),
            "kcal_100g": float(item.get("kcal100g") or 0.0),
            "protein_100g": float(item.get("protein100g") or 0.0),
            "carbs_100g": float(item.get("carbs100g") or 0.0),
            "fat_100g": float(item.get("fat100g") or 0.0),
            "fiber_100g": float(item.get("fiber100g") or 0.0),
            "nutriscore": clean_ns,
            "source": "pantry_catalog_migration",
            "is_verified": bool(barcode)
        }
        records.append(rec)

    # Batch upsert in chunks of 50
    chunk_size = 50
    total_synced = 0
    endpoint = f"{SUPABASE_URL}/rest/v1/products"

    for i in range(0, len(records), chunk_size):
        chunk = records[i:i + chunk_size]
        data = json.dumps(chunk).encode("utf-8")
        req = urllib.request.Request(endpoint, data=data, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=10) as res:
                if res.status in (200, 201):
                    total_synced += len(chunk)
                    print(f"Synced chunk {i//chunk_size + 1}: {len(chunk)} products (total: {total_synced})")
                else:
                    print(f"Warning: status {res.status} for chunk {i//chunk_size + 1}")
        except urllib.error.HTTPError as e:
            print(f"HTTP error on chunk {i//chunk_size + 1}: {e.code} - {e.read().decode()}", file=sys.stderr)
        except Exception as e:
            print(f"Request failed: {e}", file=sys.stderr)

    print(f"Synchronization complete. Total products synced to Supabase: {total_synced}")

if __name__ == "__main__":
    sync_products()
