-- CaruurKaabAI: Admin -> Supabase Integrity Checks
-- Ku orod SQL Editor si aad u hubiso in xogta admin-ku si sax ah u gasho.

-- 1) Chapters latest
select id, title, subject_name, class_level, course_order, created_at
from public.chapters
order by created_at desc
limit 20;

-- 2) Lessons latest
select id, title, subject_name, class_level, chapter_id, created_at
from public.lessons
order by created_at desc
limit 20;

-- 3) Quizzes latest
select id, title, subject_name, class_level, chapter_id, total_questions, created_at
from public.quizzes
order by created_at desc
limit 20;

-- 4) Quiz questions quick check
select
  id,
  title,
  jsonb_array_length(coalesce(questions, '[]'::jsonb)) as questions_count,
  created_at
from public.quizzes
order by created_at desc
limit 20;

-- 5) Notifications latest (admin messages)
select id, user_id, title, kind, is_read, created_at
from public.student_notifications
order by created_at desc
limit 30;

-- 6) Summary counts
select 'chapters' as table_name, count(*)::bigint as total from public.chapters
union all
select 'lessons', count(*)::bigint from public.lessons
union all
select 'quizzes', count(*)::bigint from public.quizzes
union all
select 'student_notifications', count(*)::bigint from public.student_notifications;
