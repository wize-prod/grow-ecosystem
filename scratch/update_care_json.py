import json

with open("/Users/parris-campbellnkembi/Developer/GrowWorkspace/backup_growcery/care_products.json", "r") as f:
    products = {p["id"]: p for p in json.load(f)}

with open("/Users/parris-campbellnkembi/Developer/GrowWorkspace/backup_growcery/care_routines.json", "r") as f:
    routines = json.load(f)

# Existing IDs
existing_ids = [r["id"] for r in routines]

new_routines = [
    {
        "id": "routine_post_dienst_reset",
        "title": "Post-Dienst Somatischer Reset",
        "category": "Nachmittag",
        "defaultFrequency": "Taeglich",
        "defaultHour": 16,
        "defaultMinute": 30,
        "estimatedMinutes": 5,
        "clinicalRationale": "Uebergang vom Dienstbetrieb (Dienstschluss 16:30 Uhr). Kasernenkleidung ablegen, Haende waschen, Stube lueften zur Vorbereitung auf das Training.",
        "products": [products["prod_cerave_cleanser"]],
        "steps": [
            {
                "id": "A1B2C3D4-E5F6-4A1B-8C2D-3E4F5A6B7C8D",
                "number": 1,
                "title": "Dienstkleidung ablegen & Lueften",
                "instruction": "Dienstkleidung ablegen, Fenster oeffnen, Sportkleidung anlegen.",
                "keyToolOrIngredient": "Frische Sportbekleidung"
            },
            {
                "id": "B2C3D4E5-F6A1-4B2C-9D3E-4F5A6B7C8D9E",
                "number": 2,
                "title": "Haende waschen & Reset",
                "instruction": "Haende gruendlich waschen. Pre-Workout-Hydratation vorbereiten.",
                "keyToolOrIngredient": "CeraVe Hydrating Cleanser"
            }
        ]
    },
    {
        "id": "routine_post_shower_hydration",
        "title": "Post-Workout Dusch- & Schweissreinigung",
        "category": "Abend",
        "defaultFrequency": "Taeglich",
        "defaultHour": 17,
        "defaultMinute": 45,
        "estimatedMinutes": 8,
        "clinicalRationale": "Obligatorische Beseitigung von Schweiss, Salzkristallen und Stoffwechselabbauprodukten direkt nach Trainingsende. Verhindert Follikelokklusion durch Cremes und beugt Folliculitis vor.",
        "products": [products["prod_cerave_cleanser"], products["prod_cerave_cream"]],
        "steps": [
            {
                "id": "C3D4E5F6-A1B2-4C3D-AE4F-5A6B7C8D9E0F",
                "number": 1,
                "title": "Schweiss- & Hautreinigung (Cleanser)",
                "instruction": "Direkt nach dem Training Gesicht, Hals und Rumpf mit CeraVe Hydrating Cleanser und lauwarmem Wasser gruendlich abwaschen.",
                "keyToolOrIngredient": "CeraVe Hydrating Cleanser"
            },
            {
                "id": "D4E5F6A1-B2C3-4D4E-BF5A-6B7C8D9E0F1A",
                "number": 2,
                "title": "Haut sanft abtupfen",
                "instruction": "Haut mit sauberem Handtuch vorsichtig abtupfen (nicht reiben). Haut minimal feucht lassen.",
                "keyToolOrIngredient": "Sauberes Duschhandtuch"
            },
            {
                "id": "E5F6A1B2-C3D4-4E5F-C06B-7C8D9E0F1A2B",
                "number": 3,
                "title": "Barriere-Repair (Creme)",
                "instruction": "CeraVe Feuchtigkeitscreme auf die noch leicht feuchte Haut auftragen zur TEWL-Minimierung.",
                "keyToolOrIngredient": "CeraVe Feuchtigkeitscreme"
            }
        ]
    },
    {
        "id": "routine_wochenende_tiefenreinigung",
        "title": "Wochenend-Tiefenreinigung & Skalp-Detox",
        "category": "Wochenende",
        "defaultFrequency": "Woechentlich",
        "defaultHour": 10,
        "defaultMinute": 0,
        "estimatedMinutes": 20,
        "clinicalRationale": "Intensive Tiefenreinigung von Kopfhaut und Follikeln zur Rueckstandsbeseitigung und Foerderung der Mikrozirkulation.",
        "products": [products["prod_mielle_oil"], products["prod_cantu_leavein"], products["prod_shea_castor"]],
        "steps": [
            {
                "id": "F6A1B2C3-D4E5-4F6A-D17C-8D9E0F1A2B3C",
                "number": 1,
                "title": "Kopfhaut-Peeling & Massage",
                "instruction": "Mielle Rosemary Mint Oel einmassieren und 15 Minuten unter warmem Handtuch einwirken lassen.",
                "keyToolOrIngredient": "Mielle Rosemary Mint Oil"
            },
            {
                "id": "A2B3C4D5-E6F7-4A2B-E28D-9E0F1A2B3C4D",
                "number": 2,
                "title": "Sanfte Haarwaesche",
                "instruction": "Sulfatfreies Shampoo nutzen und gruendlich mit lauwarmem Wasser ausspuelen.",
                "keyToolOrIngredient": "Cantu Cleansing Shampoo"
            },
            {
                "id": "B3C4D5E6-F7A8-4B3C-F39E-0F1A2B3C4D5E",
                "number": 3,
                "title": "Deep Conditioning & LOC",
                "instruction": "Leave-In Conditioner auftragen und mit Castor Oil versiegeln.",
                "keyToolOrIngredient": "Cantu Leave-In & Jamaican Castor Oil"
            }
        ]
    }
]

for nr in new_routines:
    if nr["id"] not in existing_ids:
        routines.append(nr)

with open("/Users/parris-campbellnkembi/Developer/GrowWorkspace/backup_growcery/care_routines.json", "w") as f:
    json.dump(routines, f, indent=2, ensure_ascii=False)

print(f"Updated backup_growcery/care_routines.json - Total routines: {len(routines)}")
