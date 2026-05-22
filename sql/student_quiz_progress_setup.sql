BEGIN;

CREATE TABLE IF NOT EXISTS public.student_quiz_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  lesson_id text,
  quiz_id text,
  correct_count integer NOT NULL DEFAULT 0,
  wrong_count integer NOT NULL DEFAULT 0,
  level integer NOT NULL DEFAULT 1,
  total_points integer NOT NULL DEFAULT 0,
  badges jsonb NOT NULL DEFAULT '[]'::jsonb,
  attempt_date date NOT NULL DEFAULT (now() AT TIME ZONE 'utc')::date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS student_quiz_progress_user_idx
  ON public.student_quiz_progress (user_id);
CREATE INDEX IF NOT EXISTS student_quiz_progress_attempt_date_idx
  ON public.student_quiz_progress (attempt_date DESC);
CREATE INDEX IF NOT EXISTS student_quiz_progress_user_lesson_idx
  ON public.student_quiz_progress (user_id, lesson_id);
CREATE UNIQUE INDEX IF NOT EXISTS student_quiz_progress_user_lesson_day_uq
  ON public.student_quiz_progress (user_id, lesson_id, attempt_date);

CREATE OR REPLACE FUNCTION public.student_quiz_progress_set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS student_quiz_progress_set_updated_at ON public.student_quiz_progress;
CREATE TRIGGER student_quiz_progress_set_updated_at
BEFORE UPDATE ON public.student_quiz_progress
FOR EACH ROW
EXECUTE FUNCTION public.student_quiz_progress_set_updated_at();

ALTER TABLE public.student_quiz_progress ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE p RECORD;
BEGIN
  FOR p IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'student_quiz_progress'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.student_quiz_progress',
      p.policyname
    );
  END LOOP;
END
$$;

CREATE POLICY student_quiz_progress_select_all
  ON public.student_quiz_progress
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY student_quiz_progress_insert_all
  ON public.student_quiz_progress
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY student_quiz_progress_update_all
  ON public.student_quiz_progress
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY student_quiz_progress_delete_all
  ON public.student_quiz_progress
  FOR DELETE
  TO anon, authenticated
  USING (true);

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.student_quiz_progress
  TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
