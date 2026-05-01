-- CaruurKaab AI - Advanced Features Upgrade
-- Run this in Supabase SQL Editor
-- Safe/idempotent script (can be run multiple times).

-- =========================================================
-- 1) Quiz table upgrades
-- =========================================================
ALTER TABLE public.quizzes
  ADD COLUMN IF NOT EXISTS difficulty text DEFAULT 'medium',
  ADD COLUMN IF NOT EXISTS default_question_seconds integer DEFAULT 10,
  ADD COLUMN IF NOT EXISTS ai_generated boolean DEFAULT false;

ALTER TABLE public.quizzes
  DROP CONSTRAINT IF EXISTS quizzes_difficulty_check;
ALTER TABLE public.quizzes
  ADD CONSTRAINT quizzes_difficulty_check
  CHECK (difficulty IN ('easy', 'medium', 'hard'));

ALTER TABLE public.quizzes
  DROP CONSTRAINT IF EXISTS quizzes_default_question_seconds_check;
ALTER TABLE public.quizzes
  ADD CONSTRAINT quizzes_default_question_seconds_check
  CHECK (default_question_seconds BETWEEN 5 AND 120);

-- =========================================================
-- 2) Student quiz progress (advanced tracking)
-- =========================================================
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

-- Keep one record per user per lesson per day (daily progression snapshot).
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

-- =========================================================
-- 3) Daily challenge table
-- =========================================================
CREATE TABLE IF NOT EXISTS public.student_daily_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  challenge_date date NOT NULL DEFAULT (now() AT TIME ZONE 'utc')::date,
  target_questions integer NOT NULL DEFAULT 5,
  answered_questions integer NOT NULL DEFAULT 0,
  correct_questions integer NOT NULL DEFAULT 0,
  completed boolean NOT NULL DEFAULT false,
  points_earned integer NOT NULL DEFAULT 0,
  reward_claimed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS student_daily_challenges_user_date_uq
  ON public.student_daily_challenges (user_id, challenge_date);

CREATE OR REPLACE FUNCTION public.student_daily_challenges_set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS student_daily_challenges_set_updated_at ON public.student_daily_challenges;
CREATE TRIGGER student_daily_challenges_set_updated_at
BEFORE UPDATE ON public.student_daily_challenges
FOR EACH ROW
EXECUTE FUNCTION public.student_daily_challenges_set_updated_at();

-- =========================================================
-- 4) Notification queue (basic)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.student_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  kind text NOT NULL DEFAULT 'reminder',
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS student_notifications_user_created_idx
  ON public.student_notifications (user_id, created_at DESC);

-- =========================================================
-- 4b) User question inbox (chatbot asked questions)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.student_question_inbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  user_email text,
  user_name text,
  question text NOT NULL,
  response text NOT NULL DEFAULT '',
  source text NOT NULL DEFAULT 'chatbot',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS student_question_inbox_user_created_idx
  ON public.student_question_inbox (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS student_question_inbox_created_idx
  ON public.student_question_inbox (created_at DESC);

-- =========================================================
-- 5) RLS (same open policy style used by existing project)
-- =========================================================
ALTER TABLE public.student_quiz_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_daily_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_question_inbox ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read access for all users" ON public.student_quiz_progress;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.student_quiz_progress;
DROP POLICY IF EXISTS "Enable update access for all users" ON public.student_quiz_progress;
DROP POLICY IF EXISTS "Enable delete access for all users" ON public.student_quiz_progress;
CREATE POLICY "Enable read access for all users"
  ON public.student_quiz_progress FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users"
  ON public.student_quiz_progress FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users"
  ON public.student_quiz_progress FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users"
  ON public.student_quiz_progress FOR DELETE USING (true);

DROP POLICY IF EXISTS "Enable read access for all users" ON public.student_daily_challenges;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.student_daily_challenges;
DROP POLICY IF EXISTS "Enable update access for all users" ON public.student_daily_challenges;
DROP POLICY IF EXISTS "Enable delete access for all users" ON public.student_daily_challenges;
CREATE POLICY "Enable read access for all users"
  ON public.student_daily_challenges FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users"
  ON public.student_daily_challenges FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users"
  ON public.student_daily_challenges FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users"
  ON public.student_daily_challenges FOR DELETE USING (true);

DROP POLICY IF EXISTS "Enable read access for all users" ON public.student_notifications;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.student_notifications;
DROP POLICY IF EXISTS "Enable update access for all users" ON public.student_notifications;
DROP POLICY IF EXISTS "Enable delete access for all users" ON public.student_notifications;
CREATE POLICY "Enable read access for all users"
  ON public.student_notifications FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users"
  ON public.student_notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users"
  ON public.student_notifications FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users"
  ON public.student_notifications FOR DELETE USING (true);

DROP POLICY IF EXISTS "Enable read access for all users" ON public.student_question_inbox;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.student_question_inbox;
DROP POLICY IF EXISTS "Enable update access for all users" ON public.student_question_inbox;
DROP POLICY IF EXISTS "Enable delete access for all users" ON public.student_question_inbox;
CREATE POLICY "Enable read access for all users"
  ON public.student_question_inbox FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users"
  ON public.student_question_inbox FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users"
  ON public.student_question_inbox FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users"
  ON public.student_question_inbox FOR DELETE USING (true);

-- =========================================================
-- 6) Helpful analytics view for admin reports
-- =========================================================
CREATE OR REPLACE VIEW public.student_performance_summary AS
SELECT
  user_id,
  COALESCE(SUM(correct_count), 0) AS correct_total,
  COALESCE(SUM(wrong_count), 0) AS wrong_total,
  COALESCE(SUM(total_points), 0) AS points_total,
  COALESCE(MAX(level), 1) AS level_current,
  CASE
    WHEN COALESCE(SUM(correct_count + wrong_count), 0) = 0 THEN 0
    ELSE ROUND(
      (COALESCE(SUM(correct_count), 0)::numeric /
      NULLIF(COALESCE(SUM(correct_count + wrong_count), 0), 0)) * 100, 1
    )
  END AS accuracy_percent
FROM public.student_quiz_progress
GROUP BY user_id;

NOTIFY pgrst, 'reload schema';
