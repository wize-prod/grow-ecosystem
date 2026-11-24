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
    workspace_pantry = Path("/Users/parris-campbellnkembi/Developer/GrowWorkspace/Growcery_Pantry_Database.json")

    merged_by_code = {}

    def ingest_items(raw_items):
        for item in raw_items:
            barcode = (item.get("barcode") or "").strip()
            item_id = (item.get("id") or "").strip()
            code = barcode if barcode else item_id
            if not code:
                continue
            if code not in merged_by_code:
                merged_by_code[code] = item
            else:
                # Prefer richer record with storePrices or higher metadata completeness
                if item.get("storePrices") and not merged_by_code[code].get("storePrices"):
                    merged_by_code[code] = item

    if pantry_path.exists():
        with open(pantry_path, "r", encoding="utf-8") as f:
            sim_items = json.load(f)
            if isinstance(sim_items, list):
                ingest_items(sim_items)
                print(f"Loaded {len(sim_items)} items from {pantry_path}")

    if workspace_pantry.exists():
        with open(workspace_pantry, "r", encoding="utf-8") as f:
            ws_data = json.load(f)
            ws_items = ws_data.get("items", []) if isinstance(ws_data, dict) else ws_data
            ingest_items(ws_items)
            print(f"Loaded {len(ws_items)} items from {workspace_pantry}")

    if not merged_by_code:
        print("No pantry items found to sync.")
        return

    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }

    records = []
    store_price_records = []

    for code, item in merged_by_code.items():
        barcode = (item.get("barcode") or "").strip()
        raw_ns = str(item.get("nutriscore") or "").strip().lower()
        clean_ns = raw_ns if len(raw_ns) <= 4 and raw_ns != "unknown" else ""

        rec = {
            "barcode": code[:64],
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
            "fiber_100g": float(item.get("fiber100g") or item.get("fiber") or 0.0),
            "nutriscore": clean_ns,
            "source": "pantry_catalog_migration",
            "is_verified": bool(barcode)
        }
        records.append(rec)

        sp_map = item.get("storePrices") or {}
        if isinstance(sp_map, dict) and sp_map:
            for chain, price in sp_map.items():
                try:
                    p_val = float(price)
                    if p_val > 0:
                        store_price_records.append({
                            "barcode": code[:64],
                            "store_chain": str(chain)[:64].upper(),
                            "branch_name": "Standard",
                            "price_eur": round(p_val, 2),
                            "recorded_by": "pantry_sync",
                            "receipt_line_raw": (item.get("name") or "")[:255]
                        })
                except Exception:
                    pass
        elif float(item.get("defaultPrice") or 0.0) > 0:
            chain = (item.get("store") or "STANDARD").strip().upper()
            store_price_records.append({
                "barcode": code[:64],
                "store_chain": chain[:64],
                "branch_name": "Standard",
                "price_eur": round(float(item.get("defaultPrice")), 2),
                "recorded_by": "pantry_sync",
                "receipt_line_raw": (item.get("name") or "")[:255]
            })

    # Also ingest receipt line items if present
    receipts_path = pantry_path.parent / "receipts.json"
    if receipts_path.exists():
        try:
            receipts = json.loads(receipts_path.read_text(encoding="utf-8"))
            for r in receipts:
                chain = (r.get("storeName") or "PENNY").strip().upper()
                for line in r.get("items", []):
                    pid = (line.get("matchedPantryItemId") or "").strip()
                    price = float(line.get("parsedPrice") or 0.0)
                    raw_text = (line.get("rawText") or "").strip()
                    if pid in merged_by_code and price > 0:
                        bc = ((merged_by_code[pid].get("barcode") or "").strip() or pid)[:64]
                        store_price_records.append({
                            "barcode": bc,
                            "store_chain": chain[:64],
                            "branch_name": "Kassenbon",
                            "price_eur": round(price, 2),
                            "recorded_by": "receipt_import",
                            "receipt_line_raw": raw_text[:255]
                        })
        except Exception as e:
            print(f"Receipt parse warning: {e}")

    # 1. Batch upsert products in chunks of 50
    chunk_size = 50
    total_synced = 0
    endpoint = f"{SUPABASE_URL}/rest/v1/products"

    for i in range(0, len(records), chunk_size):
        chunk = records[i:i + chunk_size]
        data = json.dumps(chunk).encode("utf-8")
        req = urllib.request.Request(endpoint, data=data, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=15) as res:
                if res.status in (200, 201):
                    total_synced += len(chunk)
                    print(f"Synced products chunk {i//chunk_size + 1}: {len(chunk)} (total: {total_synced})")
        except urllib.error.HTTPError as e:
            print(f"HTTP error on products chunk {i//chunk_size + 1}: {e.code} - {e.read().decode()}", file=sys.stderr)
        except Exception as e:
            print(f"Products request failed: {e}", file=sys.stderr)

    # 2. Batch insert store_prices (deduplicated by barcode+store_chain+price)
    seen_sp = set()
    unique_sp = []
    for sp in store_price_records:
        key = (sp["barcode"], sp["store_chain"], sp["price_eur"], sp["receipt_line_raw"])
        if key not in seen_sp:
            seen_sp.add(key)
            unique_sp.append(sp)

    sp_endpoint = f"{SUPABASE_URL}/rest/v1/store_prices"
    sp_headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
    }
    sp_synced = 0
    for i in range(0, len(unique_sp), chunk_size):
        chunk = unique_sp[i:i + chunk_size]
        data = json.dumps(chunk).encode("utf-8")
        req = urllib.request.Request(sp_endpoint, data=data, headers=sp_headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=15) as res:
                if res.status in (200, 201):
                    sp_synced += len(chunk)
                    print(f"Synced store_prices chunk {i//chunk_size + 1}: {len(chunk)} (total: {sp_synced})")
        except urllib.error.HTTPError as e:
            print(f"HTTP error on store_prices chunk {i//chunk_size + 1}: {e.code} - {e.read().decode()}", file=sys.stderr)
        except Exception as e:
            print(f"store_prices request failed: {e}", file=sys.stderr)

    print(f"Synchronization complete. Products: {total_synced}, Store Prices: {sp_synced}")

if __name__ == "__main__":
    sync_products()
