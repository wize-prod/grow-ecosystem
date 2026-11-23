-- =============================================================================
-- Supabase / PostgreSQL Schema: Zentraler Uebungskatalog
-- Projekt: Grow / GymApp Ecosystem
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS public.exercises (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    name_de VARCHAR(255) DEFAULT '',
    category VARCHAR(128) DEFAULT '',
    body_part VARCHAR(128) DEFAULT '',
    target VARCHAR(128) DEFAULT '',
    equipment VARCHAR(128) DEFAULT '',
    primary_muscles TEXT[] DEFAULT '{}',
    secondary_muscles TEXT[] DEFAULT '{}',
    stabilizers TEXT[] DEFAULT '{}',
    synergists TEXT[] DEFAULT '{}',
    antagonists TEXT[] DEFAULT '{}',
    setup_and_starting_position TEXT DEFAULT '',
    movement_execution_steps TEXT[] DEFAULT '{}',
    mental_cues TEXT[] DEFAULT '{}',
    common_mistakes TEXT[] DEFAULT '{}',
    general_execution_notes TEXT DEFAULT '',
    youtube_demonstration_url TEXT DEFAULT '',
    gif_url TEXT DEFAULT '',
    image_url TEXT DEFAULT '',
    tracking_mode VARCHAR(64) DEFAULT 'WEIGHT_AND_REPS',
    default_rest_seconds INTEGER DEFAULT 90,
    difficulty_tier VARCHAR(32) DEFAULT 'INTERMEDIATE',
    mechanics_type VARCHAR(64) DEFAULT 'COMPOUND',
    force_type VARCHAR(64) DEFAULT 'PUSH',
    movement_pattern VARCHAR(64) DEFAULT '',
    regressions TEXT[] DEFAULT '{}',
    progressions TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indizes fuer Hochgeschwindigkeits-Suche und Filterung
CREATE INDEX IF NOT EXISTS idx_exercises_name ON public.exercises (name);
CREATE INDEX IF NOT EXISTS idx_exercises_target ON public.exercises (target);
CREATE INDEX IF NOT EXISTS idx_exercises_body_part ON public.exercises (body_part);
CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON public.exercises (equipment);
CREATE INDEX IF NOT EXISTS idx_exercises_primary_muscles ON public.exercises USING gin (primary_muscles);
CREATE INDEX IF NOT EXISTS idx_exercises_name_trgm ON public.exercises USING gin (name gin_trgm_ops);

-- RLS (Row Level Security) - Leserechte fuer anon / authenticated
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'exercises' AND policyname = 'Public read access for exercises'
    ) THEN
        CREATE POLICY "Public read access for exercises" ON public.exercises FOR SELECT USING (true);
    END IF;
END $$;
