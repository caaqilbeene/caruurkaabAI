-- FIX: student_notifications insert/select failures (RLS + schema)
-- Run this in Supabase SQL Editor as `postgres` once.

BEGIN;

CREATE TABLE IF NOT EXISTS public.student_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  kind text NOT NULL DEFAULT 'reminder',
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.student_notifications
  ALTER COLUMN user_id TYPE text USING user_id::text;

ALTER TABLE public.student_notifications
  ALTER COLUMN title TYPE text,
  ALTER COLUMN body TYPE text,
  ALTER COLUMN kind TYPE text;

ALTER TABLE public.student_notifications
  ALTER COLUMN is_read SET DEFAULT false,
  ALTER COLUMN created_at SET DEFAULT now();

UPDATE public.student_notifications
SET is_read = false
WHERE is_read IS NULL;

CREATE INDEX IF NOT EXISTS student_notifications_user_created_idx
  ON public.student_notifications (user_id, created_at DESC);

ALTER TABLE public.student_notifications ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE p RECORD;
BEGIN
  FOR p IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'student_notifications'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.student_notifications',
      p.policyname
    );
  END LOOP;
END
$$;

CREATE POLICY student_notifications_select_all
  ON public.student_notifications
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY student_notifications_insert_all
  ON public.student_notifications
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY student_notifications_update_all
  ON public.student_notifications
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY student_notifications_delete_all
  ON public.student_notifications
  FOR DELETE
  TO anon, authenticated
  USING (true);

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.student_notifications
  TO anon, authenticated;

ALTER TABLE public.student_notifications REPLICA IDENTITY FULL;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.student_notifications;
EXCEPTION
  WHEN duplicate_object THEN NULL;
  WHEN undefined_object THEN NULL;
END
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
