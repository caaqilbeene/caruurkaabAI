import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/student_achievement_service.dart';
import '../../services/student_class_service.dart';
import '../../services/student_profile_service.dart';

class ProgressScreen extends StatefulWidget {
  final bool isEmbedded;

  const ProgressScreen({super.key, this.isEmbedded = false});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _classLevel = 1;
  List<_SubjectProgress> _subjects = const [];
  _ProgressSummary _summary = const _ProgressSummary.empty();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assigned =
          await StudentClassService.refreshAssignedClassByProgress();
      final classLevel = StudentClassService.extractClassLevel(assigned);
      final userKeys = StudentProfileService.currentUserKeys();

      final db = Supabase.instance.client;
      final lessonsRows = await db
          .from('lessons')
          .select('id,subject_name,duration_minutes,class_level');

      List<dynamic> progressRows = const [];
      if (userKeys.isNotEmpty) {
        final query = db
            .from('lesson_progress')
            .select('lesson_id,completed,completed_at');
        progressRows = userKeys.length == 1
            ? await query.eq('user_id', userKeys.first)
            : await query.inFilter('user_id', userKeys);
      }

      final completedLessonIds = <String>{};
      final completedDays = <DateTime>{};

      for (final raw in progressRows) {
        final row = Map<String, dynamic>.from(raw);
        if (row['completed'] != true) continue;

        final lessonId = row['lesson_id']?.toString();
        if (lessonId != null && lessonId.isNotEmpty) {
          completedLessonIds.add(lessonId);
        }

        final completedAtRaw = row['completed_at']?.toString();
        final completedAt = completedAtRaw == null
            ? null
            : DateTime.tryParse(completedAtRaw)?.toLocal();
        if (completedAt != null) {
          completedDays.add(
            DateTime(completedAt.year, completedAt.month, completedAt.day),
          );
        }
      }

      final bySubject = <String, _SubjectAccumulator>{};
      var totalLessons = 0;
      var completedLessons = 0;
      var completedMinutes = 0;

      for (final raw in lessonsRows) {
        final row = Map<String, dynamic>.from(raw);
        final lessonId = row['id']?.toString();
        if (lessonId == null || lessonId.isEmpty) continue;

        final lessonClass = int.tryParse(row['class_level']?.toString() ?? '');
        if (lessonClass != null && lessonClass > classLevel) continue;

        final subject = _normalizeSubject(
          (row['subject_name'] ?? '').toString().trim(),
        );
        if (subject.isEmpty) continue;

        final duration = int.tryParse(
          row['duration_minutes']?.toString() ?? '',
        );
        final estimatedDuration = duration == null || duration <= 0
            ? 10
            : duration;
        final isCompleted = completedLessonIds.contains(lessonId);

        totalLessons += 1;
        if (isCompleted) {
          completedLessons += 1;
          completedMinutes += estimatedDuration;
        }

        final acc = bySubject.putIfAbsent(subject, () => _SubjectAccumulator());
        acc.total += 1;
        if (isCompleted) acc.completed += 1;
      }

      final achievements =
          await StudentAchievementService.fetchForCurrentUser();

      final subjects =
          bySubject.entries
              .map(
                (entry) => _SubjectProgress(
                  title: entry.key,
                  completed: entry.value.completed,
                  total: entry.value.total,
                  icon: _iconForSubject(entry.key),
                  progressColor: _colorForSubject(entry.key),
                ),
              )
              .toList()
            ..sort((a, b) {
              final percentageDiff = b.percentage.compareTo(a.percentage);
              if (percentageDiff != 0) return percentageDiff;
              return a.title.compareTo(b.title);
            });

      final summary = _ProgressSummary(
        totalLessons: totalLessons,
        completedLessons: completedLessons,
        totalMinutesSpent: completedMinutes,
        completionRate: totalLessons == 0
            ? 0
            : ((completedLessons / totalLessons) * 100).round(),
        currentStreak: _calculateCurrentStreak(completedDays),
        badgesWon: achievements.badgesEarned,
        totalPoints: achievements.totalPoints,
      );

      if (!mounted) return;
      setState(() {
        _classLevel = classLevel;
        _subjects = subjects;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  int _calculateCurrentStreak(Set<DateTime> completedDays) {
    if (completedDays.isEmpty) return 0;

    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);

    if (!completedDays.contains(day)) return 0;

    var streak = 0;
    while (completedDays.contains(day)) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _normalizeSubject(String subject) {
    final s = subject.trim().toLowerCase();
    if (s.isEmpty) return '';
    if (s == 'afsomali' || s == 'af somali' || s == 'af-soomaali') {
      return 'Af-Soomaali';
    }
    if (s == 'english' || s == 'english basics') {
      return 'English Basics';
    }
    if (s == 'xisaab' || s == 'math' || s == 'math & logic') {
      return 'Math & Logic';
    }
    if (s == 'saynis' || s == 'science') {
      return 'Saynis';
    }
    return subject;
  }

  IconData _iconForSubject(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('soomaali')) return Icons.menu_book;
    if (s.contains('english')) return Icons.language;
    if (s.contains('xisaab') || s.contains('math')) return Icons.calculate;
    if (s.contains('saynis') || s.contains('science')) return Icons.science;
    return Icons.school;
  }

  Color _colorForSubject(String subject) {
    final palette = <Color>[
      const Color(0xFF1D5AFF),
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    return palette[subject.length % palette.length];
  }

  String _formatHours(int minutes) {
    if (minutes <= 0) return '0h';
    final hours = minutes / 60;
    if (hours >= 10) return '${hours.toStringAsFixed(0)}h';
    return '${hours.toStringAsFixed(1)}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF1D5AFF),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Caruurkab AI',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            const Text(
              'My Learning Journey',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fasalka $_classLevel: Progress-kaaga dhabta ah ee ku jira database-ka.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xogta lama soo qaadi karin',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF7F1D1D),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _loadProgress,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart,
                    color: Color(0xFF1D5AFF),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Subject Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_subjects.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E9F2)),
                  ),
                  child: const Text(
                    'Weli casharro lama helin ama progress lama diiwaangelin.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ..._subjects.map(_buildSubjectCard),
              const SizedBox(height: 24),
              const Text(
                'Summary Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatGridCard(
                      icon: Icons.access_time_filled,
                      title: 'TIME SPENT',
                      value: _formatHours(_summary.totalMinutesSpent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatGridCard(
                      icon: Icons.check_circle_outline,
                      title: 'LESSONS',
                      value:
                          '${_summary.completedLessons}/${max(0, _summary.totalLessons)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatGridCard(
                      icon: Icons.bolt,
                      title: 'CURRENT STREAK',
                      value: '${_summary.currentStreak} Days',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatGridCard(
                      icon: Icons.emoji_events,
                      title: 'BADGES WON',
                      value: '${_summary.badgesWon}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E9F2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      'Points: ${_summary.totalPoints}',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rate: ${_summary.completionRate}%',
                      style: const TextStyle(
                        color: Color(0xFF1D5AFF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      bottomNavigationBar: widget.isEmbedded ? null : _buildBottomNav(),
    );
  }

  Widget _buildSubjectCard(_SubjectProgress subject) {
    final subtitle = '${subject.completed}/${subject.total} Lessons';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  subject.icon,
                  color: subject.progressColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${subject.percentage}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subject.progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: subject.ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(subject.progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGridCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1D5AFF), size: 24),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E9F2))),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1D5AFF),
        unselectedItemColor: const Color(0xFF94A3B8),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Lessons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _SubjectAccumulator {
  int total = 0;
  int completed = 0;
}

class _SubjectProgress {
  final String title;
  final int completed;
  final int total;
  final IconData icon;
  final Color progressColor;

  const _SubjectProgress({
    required this.title,
    required this.completed,
    required this.total,
    required this.icon,
    required this.progressColor,
  });

  double get ratio {
    if (total <= 0) return 0;
    return completed / total;
  }

  int get percentage => (ratio * 100).round();
}

class _ProgressSummary {
  final int totalLessons;
  final int completedLessons;
  final int totalMinutesSpent;
  final int completionRate;
  final int currentStreak;
  final int badgesWon;
  final int totalPoints;

  const _ProgressSummary({
    required this.totalLessons,
    required this.completedLessons,
    required this.totalMinutesSpent,
    required this.completionRate,
    required this.currentStreak,
    required this.badgesWon,
    required this.totalPoints,
  });

  const _ProgressSummary.empty()
    : totalLessons = 0,
      completedLessons = 0,
      totalMinutesSpent = 0,
      completionRate = 0,
      currentStreak = 0,
      badgesWon = 0,
      totalPoints = 0;
}
