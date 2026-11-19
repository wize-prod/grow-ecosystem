import urllib.request
import re
import json
import time
import html
import os
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

PANTRY_COMMODITY_MAPPINGS = [
    (r'kartoffel|erdapfel', 'food_1787511011995_10', 'Fruehkartoffeln'),
    (r'zwiebel', 'food_1787510995469_1', 'Bio Zwiebeln'),
    (r'knoblauch', 'food_1787511018317_34', 'Knoblauch'),
    (r'ei|eier', 'food_1787510995665_3', 'EIER BH OKT'),
    (r'olivenöl|olivenoel', 'food_1787511047339_64', 'Natives Olivenoel Extra'),
    (r'haferflocken', 'food_1787510996165_6', 'Haferflocken zart'),
    (r'reis', 'food_1787511013751_18', 'Basmati Reis'),
    (r'nudel|spaghetti|penne|fusilli|pasta', 'food_1787510996417_7', 'Spaghetti'),
    (r'tomate|tomaten|passata', 'food_1787510996764_9', 'Pizza Tomaten'),
    (r'hähnchen|haehnchen|chicken|geflügel', 'food_1787511012921_14', 'Haehnchenbrustfilet'),
    (r'hackfleisch|rinderhack', 'food_1787511012521_12', 'Rinderhackfleisch'),
    (r'milch', 'food_1787510995914_4', 'H-Milch 1.5%'),
    (r'quark|magerquark', 'food_1787511013149_15', 'Magerquark'),
    (r'käse|kaese|gouda|cheddar|mozzarella', 'food_reibekaese', 'Gouda gerieben (light)'),
    (r'gnocchi', 'food_1787511017022_32', 'San Fabio Gnocchi'),
    (r'couscous', 'food_couscous', 'Couscous'),
    (r'feta|schafskäse|hirtenkäse', 'food_feta', 'Feta / Hirtenkaese light'),
    (r'karotte|möhre', 'food_1787511018898_38', 'Karotten / Moehren')
]

def parse_iso_duration(dur):
    if not dur or not isinstance(dur, str):
        return 0
    hours = 0
    mins = 0
    m_h = re.search(r'(\d+)\s*H', dur, re.I)
    if m_h:
        hours = int(m_h.group(1))
    m_m = re.search(r'(\d+)\s*M', dur, re.I)
    if m_m:
        mins = int(m_m.group(1))
    return hours * 60 + mins

def infer_cuisine_from_text(name, ingredients):
    text = (name + " " + " ".join(ingredients)).lower()
    if any(k in text for k in ['teriyaki', 'mie', 'wok', 'ramen', 'soja', 'pak choi', 'kimchi', 'curry', 'edamame', 'sushi', 'tofu', 'chili-knoblauch']):
        if any(k in text for k in ['kimchi', 'bibimbap', 'bulgogi']): return 'Koreanisch'
        if any(k in text for k in ['mie', 'peking', 'süß-sauer', 'suess-sauer', 'chop suey', 'dim sum']): return 'Chinesisch'
        if any(k in text for k in ['curry', 'dal', 'tikka', 'garam', 'naan']): return 'Indisch'
        if any(k in text for k in ['teriyaki', 'miso', 'ramen', 'wasabi']): return 'Japanisch'
        if any(k in text for k in ['pad thai', 'zitronengras', 'kokosmilch']): return 'Thailändisch'
        return 'Ostasiatisch'
    if any(k in text for k in ['taco', 'burrito', 'quesadilla', 'fajita', 'jalapeno', 'guacamole', 'salsa']):
        return 'Mexikanisch'
    if any(k in text for k in ['jerk', 'kochbanane', 'plantain', 'jamaic']):
        return 'Jamaikanisch'
    if any(k in text for k in ['fufu', 'jollof', 'erdnuss-suppe', 'erdnusseintopf', 'egusi']):
        return 'Westafrikanisch'
    if any(k in text for k in ['couscous', 'tagine', 'tajine', 'harissa', 'shakshuka', 'kichererbse']):
        return 'Nordafrikanisch'
    if any(k in text for k in ['hummus', 'falafel', 'kebab', 'tahini', 'shawarma', 'ayran', 'fladenbrot', 'türkisch', 'persisch']):
        return 'Türkisch'
    if any(k in text for k in ['pasta', 'spaghetti', 'gnocchi', 'risotto', 'pizza', 'parmesan', 'pesto', 'lasagne', 'ciabatta']):
        return 'Italienisch'
    if any(k in text for k in ['quiche', 'ratatouille', 'baguette', 'crêpe', 'crepe', 'croissant', 'dijon']):
        return 'Französisch'
    if any(k in text for k in ['arepa', 'empanada', 'chimichurri']):
        return 'Südamerikanisch'
    if any(k in text for k in ['sauerkraut', 'schnitzel', 'reibekuchen', 'kartoffelpuffer', 'spätzle', 'spaetzle', 'knödel', 'knoedel', 'rotkohl', 'bratwurst']):
        return 'Deutsch'
    return 'Deutsch'

def infer_long_prep(name, instructions):
    text = (name + " " + " ".join(instructions)).lower()
    if 'marinier' in text or 'marinate' in text:
        return 'Marinieren & Beizen'
    if 'pökel' in text or 'brining' in text or 'salzlake' in text:
        return 'Pökeln & Brining'
    if 'schmor' in text or 'brais' in text or 'slow cook' in text or 'schmoren' in text:
        return 'Schmoren & Braising'
    if 'ferment' in text or 'proofing' in text or 'hefeteig gehen' in text or 'gehen lassen' in text:
        return 'Fermentieren & Proofing'
    if 'ruhen lassen' in text or 'durchziehen' in text or 'über nacht' in text or 'ueber nacht' in text:
        return 'Ruhen & Aging'
    return None

def infer_equipment(name, instructions):
    text = (name + " " + " ".join(instructions)).lower()
    eq = []
    if 'airfryer' in text or 'heißluftfritteuse' in text: eq.append('AirFryer / Heißluftfritteuse')
    if 'backofen' in text or 'backen' in text or 'ober-/unterhitze' in text or 'umluft' in text or 'vorgeheizt' in text: eq.append('Backofen')
    if 'auflaufform' in text or 'gratinform' in text: eq.append('Auflaufform')
    if 'backblech' in text or 'backpapier' in text: eq.append('Backblech & Backpapier')
    if 'wok' in text: eq.append('Wok')
    elif 'pfanne' in text or 'anbraten' in text or 'braten' in text: eq.append('Pfanne')
    if 'schmortopf' in text or 'bräter' in text or 'braeter' in text or 'schmoren' in text: eq.append('Schmortopf / Bräter')
    if 'topf' in text or 'kochen' in text or 'wasser kochen' in text: eq.append('Kochtopf')
    if 'pürier' in text or 'puerier' in text or 'mixer' in text or 'blender' in text: eq.append('Pürierstab / Standmixer')
    if 'reibe' in text or 'hobeln' in text: eq.append('Küchenreibe / Hobel')
    if 'schneiden' in text or 'hacken' in text or 'würfeln' in text: eq.append('Schneidebrett & Kochmesser')
    if 'schüssel' in text or 'schuessel' in text or 'verrühren' in text: eq.append('Rührschüssel')
    if 'sieb' in text or 'abgießen' in text or 'abseihen' in text: eq.append('Sieb / Nudelsieb')

    if not eq:
        eq = ['Schneidebrett & Kochmesser', 'Pfanne', 'Kochtopf']
    return list(dict.fromkeys(eq))

def parse_ingredient_line(line):
    line = html.unescape(line).strip()
    if line.endswith(':'):
        return None  # Section title (e.g. "Für die Soße:")

    m = re.match(r'^([\d\,\.]+)\s*([a-zA-ZäöüÄÖÜß]+)?\s+(.*)$', line)
    raw_amt = 100.0
    unit = 'g'
    name = line

    if m:
        amt_str = m.group(1).replace(',', '.')
        try:
            raw_amt = float(amt_str)
        except:
            raw_amt = 100.0
        unit_cand = (m.group(2) or '').strip()
        name_cand = (m.group(3) or '').strip()
        if unit_cand.lower() in ['g', 'ml', 'l', 'kg', 'el', 'tl', 'stk', 'prise', 'bund', 'dose', 'zehe', 'zehen', 'packung']:
            unit = unit_cand
            name = name_cand
        else:
            if unit_cand:
                name = f"{unit_cand} {name_cand}"
            unit = 'Stk' if raw_amt < 10 else 'g'
    elif re.match(r'^[a-zA-ZäöüÄÖÜß]', line):
        raw_amt = 1.0
        unit = 'Prise'
        name = line

    matched_id = None
    for pattern, p_id, p_name in PANTRY_COMMODITY_MAPPINGS:
        if re.search(pattern, name, re.I):
            matched_id = p_id
            break

    if not matched_id:
        slug = re.sub(r'[^a-zA-Z0-9]', '_', name.lower())[:30]
        matched_id = f"penny_{slug}"

    grams = raw_amt
    if unit.lower() in ['kg', 'l']: grams = raw_amt * 1000.0
    elif unit.lower() == 'el': grams = raw_amt * 15.0
    elif unit.lower() == 'tl': grams = raw_amt * 5.0
    elif unit.lower() in ['stk', 'zehe', 'zehen']: grams = raw_amt * 25.0
    elif unit.lower() == 'prise': grams = 2.0

    return {
        "id": f"ing_{int(time.time() * 1000) % 10000000}_{re.sub(r'[^a-zA-Z0-9]', '', name)[:10]}",
        "pantryItemId": matched_id,
        "name": name,
        "grams": round(grams, 1),
        "unit": unit,
        "rawAmount": round(raw_amt, 2)
    }

def fetch_recipe(url):
    req = urllib.request.Request(
        url,
        headers={
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'de-DE,de;q=0.9',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        }
    )
    for attempt in range(2):
        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                html_text = resp.read().decode('utf-8', errors='ignore')
            break
        except Exception as e:
            if attempt == 1:
                return None
            time.sleep(0.5)

    m = re.search(r'<script[^>]*type=[\"\']application/ld\+json[\"\'][^>]*>(.*?)</script>', html_text, re.DOTALL)
    if not m:
        return None
    try:
        data = json.loads(m.group(1))
        if isinstance(data, list):
            data = data[0]
        if data.get('@type') != 'Recipe':
            return None
    except:
        return None

    raw_name = data.get('name', '').strip()
    if not raw_name:
        return None
    name = html.unescape(raw_name)

    slug = url.rstrip('/').split('/')[-1]
    recipe_id = f"penny_{slug}"

    servings = 2
    raw_yield = data.get('recipeYield')
    if raw_yield:
        m_y = re.search(r'\d+', str(raw_yield))
        if m_y:
            servings = max(1, int(m_y.group(0)))

    prep_min = parse_iso_duration(data.get('prepTime'))
    cook_min = parse_iso_duration(data.get('cookTime'))
    total_min = parse_iso_duration(data.get('totalTime'))
    if prep_min == 0 and cook_min == 0 and total_min > 0:
        prep_min = min(15, total_min)
        cook_min = max(0, total_min - prep_min)
    if prep_min == 0: prep_min = 15
    if cook_min == 0: cook_min = 20

    raw_ings = data.get('recipeIngredient', [])
    ingredients = []
    for line in raw_ings:
        parsed = parse_ingredient_line(line)
        if parsed:
            ingredients.append(parsed)

    raw_inst = data.get('recipeInstructions', [])
    instructions = []
    if isinstance(raw_inst, list):
        for item in raw_inst:
            if isinstance(item, dict):
                text = item.get('text', '') or item.get('name', '')
            else:
                text = str(item)
            cleaned = re.sub(r'^(?:(?:Schritt\s+)?\d+[\.\)\:\-]\s*)+', '', text.strip())
            cleaned = html.unescape(cleaned)
            if cleaned:
                instructions.append(cleaned)
    elif isinstance(raw_inst, str):
        instructions = [html.unescape(re.sub(r'^(?:(?:Schritt\s+)?\d+[\.\)\:\-]\s*)+', '', s.strip())) for s in raw_inst.split('\n') if s.strip()]

    images = data.get('image', [])
    image_url = None
    if isinstance(images, list) and images:
        image_url = images[0]
    elif isinstance(images, str) and images:
        image_url = images

    category = "Mittagessen"
    l_name = name.lower()
    if any(k in l_name for k in ['frühstück', 'pancake', 'müsli', 'porridge', 'smoothie', 'toast']):
        category = "Frühstück"
    elif any(k in l_name for k in ['snack', 'riegel', 'dip', 'fingerfood', 'chips', 'cookie', 'kuchen', 'muffin']):
        category = "Snack"
    elif any(k in l_name for k in ['suppe', 'stew', 'eintopf', 'salat', 'bowl']):
        category = "Abendessen"

    ing_names = [i['name'] for i in ingredients]
    cuisine = infer_cuisine_from_text(name, ing_names)
    equipment = infer_equipment(name, instructions)
    long_prep = infer_long_prep(name, instructions)

    return {
        "id": recipe_id,
        "name": name,
        "category": category,
        "ingredients": ingredients,
        "instructions": instructions,
        "imageFileName": None,
        "imageUrl": image_url,
        "prepTimeMinutes": prep_min,
        "cookTimeMinutes": cook_min,
        "servings": servings,
        "cuisineType": cuisine,
        "equipment": equipment,
        "longPreparationType": long_prep
    }

def get_sitemap_recipe_urls():
    sitemap_url = 'https://www.penny.de/.rest/sitemap/sitemap-clever-kochen.xml'
    req = urllib.request.Request(sitemap_url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=15) as resp:
        xml_data = resp.read().decode('utf-8', errors='ignore')

    locs = re.findall(r'<loc>([^<]+)</loc>', xml_data)
    recipe_urls = [
        u.strip() for u in locs
        if '/clever-kochen/rezepte-und-ernaehrung/' in u and
        '/Interviews/' not in u and
        u.rstrip('/') != 'https://www.penny.de/clever-kochen/rezepte-und-ernaehrung'
    ]
    # Remove duplicates
    seen = set()
    deduped = []
    for u in recipe_urls:
        if u not in seen:
            seen.add(u)
            deduped.append(u)
    return deduped

def main():
    output_path = "/Users/parris-campbellnkembi/Developer/GrowWorkspace/NutriVaultApp/NutriVaultApp/Resources/penny_recipes.json"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    existing_recipes = {}
    if os.path.exists(output_path):
        try:
            with open(output_path, 'r', encoding='utf-8') as f:
                loaded = json.load(f)
                for r in loaded:
                    existing_recipes[r['id']] = r
            print(f"Loaded {len(existing_recipes)} existing recipes from {output_path}")
        except Exception as e:
            print("Error loading existing:", e)

    print("Fetching sitemap URLs...")
    all_urls = get_sitemap_recipe_urls()
    print(f"Total target recipe URLs found in sitemap: {len(all_urls)}")

    to_fetch = [u for u in all_urls if f"penny_{u.rstrip('/').split('/')[-1]}" not in existing_recipes]
    print(f"URLs to scrape: {len(to_fetch)} (already cached: {len(existing_recipes)})")

    recipes = list(existing_recipes.values())

    if not to_fetch:
        print("All recipes already scraped!")
        return

    count = 0
    start_time = time.time()

    # Use 2 workers with gentle pacing to prevent CDN rate limits
    with ThreadPoolExecutor(max_workers=2) as executor:
        future_to_url = {executor.submit(fetch_recipe, url): url for url in to_fetch}
        for future in as_completed(future_to_url):
            url = future_to_url[future]
            try:
                recipe = future.result()
                if recipe:
                    recipes.append(recipe)
                    count += 1
                    if count % 25 == 0 or count == len(to_fetch):
                        elapsed = time.time() - start_time
                        print(f"Progress: {len(recipes)} / {len(all_urls)} recipes (scraped {count} in {elapsed:.1f}s)")
                        with open(output_path, 'w', encoding='utf-8') as f:
                            json.dump(recipes, f, ensure_ascii=False, indent=2)
            except Exception as e:
                pass
            time.sleep(0.08)

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(recipes, f, ensure_ascii=False, indent=2)

    print(f"Done! Saved {len(recipes)} recipes to {output_path}")

if __name__ == '__main__':
    main()
