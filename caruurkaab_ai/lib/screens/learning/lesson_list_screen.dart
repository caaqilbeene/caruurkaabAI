import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/student_profile_service.dart';
import 'lesson_viewer_screen.dart';

class LessonListScreen extends StatefulWidget {
  final String className;
  final String subjectName;

  const LessonListScreen({
    super.key,
    required this.className,
    required this.subjectName,
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chapters = [];
  Map<String, List<Map<String, dynamic>>> _lessonsByChapter = {};
  List<Map<String, dynamic>> _looseLessons = [];
  Map<String, Map<String, dynamic>?> _nextLessonById = {};
  Map<String, String> _statusByLessonId = {};
  Map<String, bool> _chapterUnlockedById = {};
  Set<String> _completedLessonIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _normalizeSubject(String subject) {
    final s = subject.trim().toLowerCase();
    if (s == 'afsomali' || s == 'af somali' || s == 'af-soomaali') {
      return 'Af Soomaali';
    }
    if (s == 'seynis' || s == 'saynis') {
      return 'Saynis';
    }
    return subject;
  }

  int _parseClassLevel(String className) {
    final match = RegExp(r'\d+').firstMatch(className);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 1;
    }
    return 1;
  }

  Future<void> _fetchData() async {
    try {
      final classLevel = _parseClassLevel(widget.className);
      final subjectName = _normalizeSubject(widget.subjectName);
      final userKeys = StudentProfileService.currentUserKeys();

      final chaptersData = await Supabase.instance.client
          .from('chapters')
          .select()
          .eq('subject_name', subjectName)
          .eq('class_level', classLevel)
          .order('course_order', ascending: true);

      final lessonsData = await Supabase.instance.client
          .from('lessons')
          .select()
          .eq('subject_name', subjectName)
          .eq('class_level', classLevel)
          .order('created_at', ascending: true);

      List<dynamic> progressData = [];
      try {
        final progressQuery = Supabase.instance.client
            .from('lesson_progress')
            .select('lesson_id, completed');
        progressData = userKeys.isEmpty
            ? const []
            : (userKeys.length == 1
                  ? await progressQuery.eq('user_id', userKeys.first)
                  : await progressQuery.inFilter('user_id', userKeys));
      } catch (e) {
        debugPrint("Progress fetch skipped: $e");
      }

      final chapters = List<Map<String, dynamic>>.from(chaptersData);
      final lessons = List<Map<String, dynamic>>.from(lessonsData);
      _completedLessonIds = {
        for (final row in progressData)
          if (row['completed'] == true) row['lesson_id'].toString(),
      };
      _statusByLessonId = {};

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      final List<Map<String, dynamic>> loose = [];

      for (var ch in chapters) {
        grouped[ch['id'].toString()] = [];
      }

      for (var l in lessons) {
        final cId = l['chapter_id']?.toString();
        if (cId != null && grouped.containsKey(cId)) {
          grouped[cId]!.add(l);
        } else {
          loose.add(l);
        }
      }

      for (final entry in grouped.entries) {
        entry.value.sort((a, b) {
          final aTime = a['created_at']?.toString() ?? '';
          final bTime = b['created_at']?.toString() ?? '';
          return aTime.compareTo(bTime);
        });
      }

      loose.sort((a, b) {
        final aTime = a['created_at']?.toString() ?? '';
        final bTime = b['created_at']?.toString() ?? '';
        return aTime.compareTo(bTime);
      });
      _applyGlobalProgressionStatuses(
        chapters: chapters,
        grouped: grouped,
        loose: loose,
      );

      final nextMap = _buildNextLessonMap(chapters, grouped, loose);

      if (mounted) {
        setState(() {
          _chapters = chapters;
          _lessonsByChapter = grouped;
          _looseLessons = loose;
          _nextLessonById = nextMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching learning data: \$e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, Map<String, dynamic>?> _buildNextLessonMap(
    List<Map<String, dynamic>> chapters,
    Map<String, List<Map<String, dynamic>>> grouped,
    List<Map<String, dynamic>> loose,
  ) {
    final ordered = <Map<String, dynamic>>[];

    for (final ch in chapters) {
      final chId = ch['id']?.toString();
      if (chId == null) continue;
      final lessons = grouped[chId] ?? [];
      ordered.addAll(lessons);
    }
    if (loose.isNotEmpty) {
      ordered.addAll(loose);
    }

    final Map<String, Map<String, dynamic>?> nextMap = {};
    for (var i = 0; i < ordered.length; i++) {
      final currentId = ordered[i]['id']?.toString() ?? '';
      if (currentId.isEmpty) continue;
      nextMap[currentId] = i + 1 < ordered.length ? ordered[i + 1] : null;
    }
    return nextMap;
  }

  void _applyGlobalProgressionStatuses({
    required List<Map<String, dynamic>> chapters,
    required Map<String, List<Map<String, dynamic>>> grouped,
    required List<Map<String, dynamic>> loose,
  }) {
    _statusByLessonId = {};
    _chapterUnlockedById = {};

    var previousChapterCompleted = true;

    for (final chapter in chapters) {
      final chapterId = chapter['id']?.toString() ?? '';
      if (chapterId.isEmpty) continue;

      final chapterLessons = grouped[chapterId] ?? const <Map<String, dynamic>>[];
      final chapterUnlocked = previousChapterCompleted;
      _chapterUnlockedById[chapterId] = chapterUnlocked;

      if (!chapterUnlocked) {
        for (final lesson in chapterLessons) {
          final lessonId = lesson['id']?.toString() ?? '';
          if (lessonId.isEmpty) continue;
          _statusByLessonId[lessonId] = 'locked';
        }
        continue;
      }

      var chapterAllCompleted = true;
      var canAccessLesson = true;
      for (final lesson in chapterLessons) {
        final lessonId = lesson['id']?.toString() ?? '';
        if (lessonId.isEmpty) continue;
        final isCompleted = _completedLessonIds.contains(lessonId);

        if (!canAccessLesson) {
          _statusByLessonId[lessonId] = 'locked';
          chapterAllCompleted = false;
          continue;
        }

        if (isCompleted) {
          _statusByLessonId[lessonId] = 'completed';
        } else {
          _statusByLessonId[lessonId] = 'start';
          canAccessLesson = false;
          chapterAllCompleted = false;
        }
      }

      previousChapterCompleted = chapterAllCompleted;
    }

    // Loose lessons: only after all chapters are completed.
    var canAccessLoose = previousChapterCompleted;
    for (final lesson in loose) {
      final lessonId = lesson['id']?.toString() ?? '';
      if (lessonId.isEmpty) continue;
      final isCompleted = _completedLessonIds.contains(lessonId);

      if (!canAccessLoose) {
        _statusByLessonId[lessonId] = 'locked';
        continue;
      }

      if (isCompleted) {
        _statusByLessonId[lessonId] = 'completed';
      } else {
        _statusByLessonId[lessonId] = 'start';
        canAccessLoose = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: Column(
          children: [
            Text(
              _normalizeSubject(widget.subjectName),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.className,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D5AFF), Color(0xFF4A7DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D5AFF).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.className.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Casharrada ${widget.subjectName}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Sii wad barashadaada si aad u gaarto guul!",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Lessons List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_chapters.isEmpty && _looseLessons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text("Wax casharro ah kama jiraan qaybtan."),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._chapters.map((ch) {
                    final chLessons =
                        _lessonsByChapter[ch['id'].toString()] ?? [];
                    final isChapterUnlocked =
                        _chapterUnlockedById[ch['id']?.toString() ?? ''] ??
                        false;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ch['title'] ?? 'Cutubka',
                                  style: TextStyle(
                                    color: isChapterUnlocked
                                        ? const Color(0xFF1D5AFF)
                                        : const Color(0xFF9CA3AF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (!isChapterUnlocked)
                                const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFF9CA3AF),
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                        if (!isChapterUnlocked)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Marka hore dhammee casharrada iyo quiz-ka cutubka hore.',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (chLessons.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 15),
                            child: Text(
                              "Ma jiraan casharro cutubkan ku jira.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: chLessons.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final lesson = chLessons[index];
                              final lessonId = lesson['id']?.toString() ?? '';
                              final nextLesson = _nextLessonById[lessonId];
                              return _buildLessonCard(lesson, nextLesson);
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),

                  if (_looseLessons.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Casharro Kale (Aan Cutub Lahayn)",
                        style: TextStyle(
                          color: Color(0xFF1D5AFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _looseLessons.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final lesson = _looseLessons[index];
                        final lessonId = lesson['id']?.toString() ?? '';
                        final nextLesson = _nextLessonById[lessonId];
                        return _buildLessonCard(lesson, nextLesson);
                      },
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(
    Map<String, dynamic> lesson,
    Map<String, dynamic>? nextLesson,
  ) {
    final classLevel = _parseClassLevel(widget.className);
    final status = _statusByLessonId[lesson['id']?.toString() ?? ''] ?? 'start';
    bool isCompleted = status == 'completed';
    bool isLocked = status == 'locked';
    bool isStart = status == 'start';

    String lessonTitle = lesson['title'] ?? 'Magac La\'aan';
    String lessonSubtitle = (lesson['desc'] ?? '').toString().trim();
    if (lessonSubtitle.isEmpty) {
      lessonSubtitle = "\${lesson['duration_minutes'] ?? 5} daqiiqo";
    } else if (lessonSubtitle.length > 120) {
      lessonSubtitle = "${lessonSubtitle.substring(0, 120)}...";
    }

    Color statusColor;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle;
    } else if (isLocked) {
      statusColor = const Color(0xFF9CA3AF);
      statusIcon = Icons.lock;
    } else {
      statusColor = const Color(0xFF1D5AFF);
      statusIcon = Icons.play_circle_fill;
    }

    return InkWell(
      onTap: isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Fadlan dhammee casharrada hore si aad u furto midkan!",
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonViewerScreen(
                    lessonTitle: lessonTitle,
                    subjectName: widget.subjectName,
                    lessonId: lesson['id'].toString(),
                    classLevel: classLevel,
                    chapterId: lesson['chapter_id']?.toString(),
                    nextLessonId: nextLesson?['id']?.toString(),
                    nextLessonTitle: nextLesson?['title']?.toString(),
                    nextLessonChapterId: nextLesson?['chapter_id']?.toString(),
                  ),
                ),
              );
              _fetchData();
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStart
                ? const Color(0xFF1D5AFF).withValues(alpha: 0.3)
                : const Color(0xFFF3F4F6),
            width: isStart ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 15),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonTitle,
                    style: TextStyle(
                      color: isLocked
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lessonSubtitle,
                    style: TextStyle(
                      color: isLocked
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar & Text
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: isCompleted ? 1.0 : (isLocked ? 0.0 : 0.2),
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isCompleted
                            ? "DHAMMAAD"
                            : (isLocked ? "XIRAN" : "BILOW"),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // "Action" button visual indicator
            if (isStart)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D5AFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "BILOW",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isCompleted)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
