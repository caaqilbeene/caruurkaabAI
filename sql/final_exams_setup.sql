BEGIN;

CREATE TABLE IF NOT EXISTS public.exams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  title text NOT NULL,
  "desc" text NOT NULL DEFAULT '',
  subject_name text NOT NULL,
  class_level integer NOT NULL DEFAULT 1,
  exam_type text NOT NULL DEFAULT 'final_class',
  is_active boolean NOT NULL DEFAULT true,
  notice_text text NOT NULL DEFAULT '',
  passing_score integer NOT NULL DEFAULT 60,
  questions_to_answer integer NOT NULL DEFAULT 10,
  total_questions integer NOT NULL DEFAULT 10,
  duration_minutes integer NOT NULL DEFAULT 0,
  questions jsonb NOT NULL DEFAULT '[]'::jsonb
);

ALTER TABLE public.exams
  ALTER COLUMN class_level SET DEFAULT 1,
  ALTER COLUMN exam_type SET DEFAULT 'final_class',
  ALTER COLUMN is_active SET DEFAULT true,
  ALTER COLUMN passing_score SET DEFAULT 60,
  ALTER COLUMN questions_to_answer SET DEFAULT 10,
  ALTER COLUMN total_questions SET DEFAULT 10,
  ALTER COLUMN duration_minutes SET DEFAULT 0,
  ALTER COLUMN questions SET DEFAULT '[]'::jsonb;

CREATE INDEX IF NOT EXISTS exams_created_idx
  ON public.exams (created_at DESC);

CREATE INDEX IF NOT EXISTS exams_subject_class_idx
  ON public.exams (subject_name, class_level);

CREATE INDEX IF NOT EXISTS exams_type_active_idx
  ON public.exams (exam_type, is_active);

ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE p RECORD;
BEGIN
  FOR p IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'exams'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.exams',
      p.policyname
    );
  END LOOP;
END
$$;

CREATE POLICY exams_select_all
  ON public.exams
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY exams_insert_all
  ON public.exams
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY exams_update_all
  ON public.exams
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY exams_delete_all
  ON public.exams
  FOR DELETE
  TO anon, authenticated
  USING (true);

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.exams
  TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
