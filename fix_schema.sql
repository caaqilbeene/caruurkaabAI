-- MAREYNTA XOGTA KAN KALIYA RUN SII (JUST RUN THIS ONE MAIN SCRIPT)

-- 1. Xaqiiji miiska 'lessons' in ay ku jiraan dhammaan safafka
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS title text;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS "desc" text;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS subject_name text;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS class_level integer;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS duration_minutes integer;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS items jsonb;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS created_at timestamp with time zone default timezone('utc'::text, now());

-- 2. Xaqiiji miiska 'chapters' inuu jiro
CREATE TABLE IF NOT EXISTS public.chapters (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  subject_name text not null,
  class_level integer not null,
  course_order integer default 1
);

-- Haddii miiska uu horey u jiray oo ay wax ka dhiman yihiin, bal ku dar:
ALTER TABLE public.chapters ADD COLUMN IF NOT EXISTS title text;
ALTER TABLE public.chapters ADD COLUMN IF NOT EXISTS subject_name text;
ALTER TABLE public.chapters ADD COLUMN IF NOT EXISTS class_level integer;
ALTER TABLE public.chapters ADD COLUMN IF NOT EXISTS course_order integer;

-- 3. Xiriiri 'lessons' iyo 'chapters'
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL;

-- 4. U FUR DHAMMAAN OGGOLAANSHAHA (RLS POLICIES) MIISKA 'chapters'
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.chapters;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.chapters;
DROP POLICY IF EXISTS "Enable update access for all users" ON public.chapters;
DROP POLICY IF EXISTS "Enable delete access for all users" ON public.chapters;

CREATE POLICY "Enable read access for all users" ON public.chapters FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.chapters FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.chapters FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON public.chapters FOR DELETE USING (true);

-- 5. U FUR DHAMMAAN OGGOLAANSHAHA (RLS POLICIES) MIISKA 'lessons'
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.lessons;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.lessons;
DROP POLICY IF EXISTS "Enable update access for all users" ON public.lessons;
DROP POLICY IF EXISTS "Enable delete access for all users" ON public.lessons;

CREATE POLICY "Enable read access for all users" ON public.lessons FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.lessons FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.lessons FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON public.lessons FOR DELETE USING (true);

-- 6. PROGRESS TABLE (Casharka dhameystirka ardayga)
CREATE TABLE IF NOT EXISTS public.lesson_progress (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id text not null,
  lesson_id uuid references public.lessons(id) on delete cascade,
  completed boolean default false,
  completed_at timestamp with time zone
);

CREATE UNIQUE INDEX IF NOT EXISTS lesson_progress_user_lesson_key
  ON public.lesson_progress (user_id, lesson_id);

ALTER TABLE public.lesson_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.lesson_progress;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.lesson_progress;
DROP POLICY IF EXISTS "Enable update access for all users" ON public.lesson_progress;
DROP POLICY IF EXISTS "Enable delete access for all users" ON public.lesson_progress;

CREATE POLICY "Enable read access for all users" ON public.lesson_progress FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON public.lesson_progress FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON public.lesson_progress FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON public.lesson_progress FOR DELETE USING (true);

-- 7. STORAGE BUCKET: lesson-media (Public)
INSERT INTO storage.buckets (id, name, public)
VALUES ('lesson-media', 'lesson-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read lesson-media" ON storage.objects;
DROP POLICY IF EXISTS "Public insert lesson-media" ON storage.objects;
DROP POLICY IF EXISTS "Public update lesson-media" ON storage.objects;
DROP POLICY IF EXISTS "Public delete lesson-media" ON storage.objects;

CREATE POLICY "Public read lesson-media"
  ON storage.objects FOR SELECT USING (bucket_id = 'lesson-media');
CREATE POLICY "Public insert lesson-media"
  ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'lesson-media');
CREATE POLICY "Public update lesson-media"
  ON storage.objects FOR UPDATE USING (bucket_id = 'lesson-media');
CREATE POLICY "Public delete lesson-media"
  ON storage.objects FOR DELETE USING (bucket_id = 'lesson-media');

-- 8. REFRESH SAREEYA (TANI WAA XALINTA CILADDA PGRST204 Ee "Schema Cache")
NOTIFY pgrst, 'reload schema';
