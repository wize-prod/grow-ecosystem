-- =============================================================================
-- Supabase / PostgreSQL Schema: Zentraler Produkt- & Filialpreiskatalog
-- Projekt: Grow / GymApp Ecosystem
-- =============================================================================

-- 1. Tabelle: products (Stammdaten & Naehrwerte)
CREATE TABLE IF NOT EXISTS public.products (
    barcode VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(128) DEFAULT '',
    category VARCHAR(64) DEFAULT 'Lebensmittel',
    pack_qty NUMERIC(8,2) DEFAULT 1.0,
    unit VARCHAR(32) DEFAULT 'g',
    price_reference NUMERIC(8,2) DEFAULT 0.0,
    kcal_100g NUMERIC(8,2) DEFAULT 0.0,
    protein_100g NUMERIC(8,2) DEFAULT 0.0,
    carbs_100g NUMERIC(8,2) DEFAULT 0.0,
    fat_100g NUMERIC(8,2) DEFAULT 0.0,
    fiber_100g NUMERIC(8,2) DEFAULT 0.0,
    nutriscore VARCHAR(4) DEFAULT '',
    reha_score INTEGER DEFAULT 0,
    source VARCHAR(64) DEFAULT 'openfoodfacts',
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indizes fuer performante Volltextsuche und Filterung
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products (name);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products (category);
CREATE INDEX IF NOT EXISTS idx_products_protein ON public.products (protein_100g DESC);

-- 2. Tabelle: store_prices (Dynamische Filial- und Kassenbon-Preise)
CREATE TABLE IF NOT EXISTS public.store_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode VARCHAR(64) REFERENCES public.products(barcode) ON DELETE CASCADE,
    store_chain VARCHAR(64) NOT NULL,            -- z.B. EDEKA, REWE, LIDL, ALDI
    branch_name VARCHAR(128) DEFAULT '',         -- z.B. Hannover Südstadt, Hildesheimer Str.
    price_eur NUMERIC(8,2) NOT NULL,             -- Reeler Kassenbon- oder Regalpreis
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    recorded_by VARCHAR(64) DEFAULT 'device',    -- Client Device ID
    receipt_line_raw VARCHAR(255) DEFAULT ''     -- Optional: Original Bon-Textzeile (z.B. "JA! MAGERQUARK 500G")
);

-- Indizes fuer schnelle Filialpreis-Abfragen
CREATE INDEX IF NOT EXISTS idx_store_prices_barcode ON public.store_prices (barcode);
CREATE INDEX IF NOT EXISTS idx_store_prices_store ON public.store_prices (store_chain, branch_name);
CREATE INDEX IF NOT EXISTS idx_store_prices_date ON public.store_prices (recorded_at DESC);

-- 3. Row Level Security (RLS) aktivieren
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_prices ENABLE ROW LEVEL SECURITY;

-- 4. Richtlinien fuer den mobilen Client (Anon Key lesend & schreibend)
CREATE POLICY "Public Read Access for Products"
ON public.products FOR SELECT
USING (true);

CREATE POLICY "Public Insert/Update Access for Products"
ON public.products FOR ALL
USING (true)
WITH CHECK (true);

CREATE POLICY "Public Read Access for Store Prices"
ON public.store_prices FOR SELECT
USING (true);

CREATE POLICY "Public Insert Access for Store Prices"
ON public.store_prices FOR INSERT
WITH CHECK (true);

-- 5. Auto-Update Timestamp Trigger
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trigger_products_updated_at ON public.products;
CREATE TRIGGER trigger_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW EXECUTE FUNCTION update_modified_column();
