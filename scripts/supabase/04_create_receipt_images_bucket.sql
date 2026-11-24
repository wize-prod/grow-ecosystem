-- =============================================================================
-- Supabase Storage Bucket: receipt_images (Komprimierte Belege 150-250 KB)
-- Projekt: Grow / GymApp Ecosystem
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'receipt_images',
    'receipt_images',
    false,
    1048576, -- 1 MB Hard-Limit (Zielgroesse nach Komprimierung: 150-250 KB)
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies fuer Storage Objects im Bucket receipt_images
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow upload to receipt_images'
    ) THEN
        CREATE POLICY "Allow upload to receipt_images"
        ON storage.objects FOR INSERT
        TO anon, authenticated
        WITH CHECK (bucket_id = 'receipt_images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow read from receipt_images'
    ) THEN
        CREATE POLICY "Allow read from receipt_images"
        ON storage.objects FOR SELECT
        TO anon, authenticated
        USING (bucket_id = 'receipt_images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow update in receipt_images'
    ) THEN
        CREATE POLICY "Allow update in receipt_images"
        ON storage.objects FOR UPDATE
        TO anon, authenticated
        USING (bucket_id = 'receipt_images');
    END IF;
END $$;
