-- =============================================================================
-- Supabase / PostgreSQL Schema Migration: Bestandsverwaltung (user_inventory)
-- Projekt: Grow / GymApp Ecosystem
-- =============================================================================

-- 1. Tabelle: user_inventory (Dynamische Bestaende und Lagerorte je Benutzer)
CREATE TABLE IF NOT EXISTS public.user_inventory (
    user_id VARCHAR(64) DEFAULT 'primary_wize_prod',
    barcode VARCHAR(64) REFERENCES public.products(barcode) ON DELETE CASCADE,
    current_stock_qty NUMERIC(8,2) DEFAULT 0.0,
    storage_location VARCHAR(64) DEFAULT 'Kühlschrank',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, barcode)
);

-- Indizes fuer performante Bestandsabfragen
CREATE INDEX IF NOT EXISTS idx_user_inventory_user ON public.user_inventory (user_id);
CREATE INDEX IF NOT EXISTS idx_user_inventory_barcode ON public.user_inventory (barcode);
CREATE INDEX IF NOT EXISTS idx_user_inventory_stock ON public.user_inventory (current_stock_qty);

-- 2. Row Level Security (RLS) aktivieren
ALTER TABLE public.user_inventory ENABLE ROW LEVEL SECURITY;

-- 3. RLS-Policies fuer Anon-Key Zugriff (Lesen, Schreiben, Loeschen)
DROP POLICY IF EXISTS "Public Read Access for User Inventory" ON public.user_inventory;
CREATE POLICY "Public Read Access for User Inventory"
ON public.user_inventory FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Public All Access for User Inventory" ON public.user_inventory;
CREATE POLICY "Public All Access for User Inventory"
ON public.user_inventory FOR ALL
USING (true)
WITH CHECK (true);

-- 4. Auto-Update Timestamp Trigger
DROP TRIGGER IF EXISTS trigger_user_inventory_updated_at ON public.user_inventory;
CREATE TRIGGER trigger_user_inventory_updated_at
BEFORE UPDATE ON public.user_inventory
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- 5. Konsolidierte View: v_pantry_catalog (Verbindung von Stammdaten, Naehrwerten & Live-Bestand)
CREATE OR REPLACE VIEW public.v_pantry_catalog AS
SELECT 
    p.barcode,
    p.name,
    p.brand,
    p.category,
    p.pack_qty,
    p.unit,
    p.price_reference,
    p.kcal_100g,
    p.protein_100g,
    p.carbs_100g,
    p.fat_100g,
    p.fiber_100g,
    p.nutriscore,
    p.reha_score,
    p.source,
    COALESCE(i.current_stock_qty, 0.0) AS current_stock_qty,
    COALESCE(i.storage_location, 'Kühlschrank') AS storage_location,
    COALESCE(i.user_id, 'primary_wize_prod') AS user_id,
    COALESCE(i.updated_at, p.updated_at) AS last_stock_update
FROM public.products p
LEFT JOIN public.user_inventory i 
    ON p.barcode = i.barcode AND i.user_id = 'primary_wize_prod';

-- 6. RLS fuer View verfuegbar machen
ALTER VIEW public.v_pantry_catalog OWNER TO postgres;
GRANT SELECT ON public.v_pantry_catalog TO anon, authenticated, service_role;
