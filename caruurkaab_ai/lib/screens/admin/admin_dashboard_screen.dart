import 'dart:async';

import 'package:caruurkaab_ai/screens/admin/admin_reports_screen.dart';
import 'package:caruurkaab_ai/screens/admin/admin_user_management_screen.dart';
import 'package:caruurkaab_ai/screens/content_management/admin_content_management_screen.dart';
import 'package:caruurkaab_ai/screens/content_management/admin_quiz_form_screen.dart';
import 'package:caruurkaab_ai/screens/content_management/admin_quiz_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;


  int _totalUsers = 0;
  int _totalLessons = 0;
  int _totalQuizzes = 0;
  int _totalExams = 0;
  int _newUsersLast7Days = 0;

  final List<_AdminAlert> _alerts = [];
  final List<_DirectQuestionPreview> _directQuestions = [];
  final List<_AdminUserOption> _allUsers = [];
  final List<_AdminUserOption> _recentUsers = [];
  final List<_UserQuestionRecord> _userQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _alerts.clear();
      _directQuestions.clear();
      _allUsers.clear();
      _recentUsers.clear();
      _userQuestions.clear();
    });

    try {
      final db = Supabase.instance.client;

      final usersRows = await db
          .from('student_registry')
          .select('user_id,email,full_name,student_no,joined_at')
          .order('joined_at', ascending: false);
      final users = List<Map<String, dynamic>>.from(usersRows);

      for (final row in users) {
        final option = _AdminUserOption.fromRegistryRow(row);
        if (option.userId.isEmpty) continue;
        if (_allUsers.any((u) => u.userId == option.userId)) continue;
        _allUsers.add(option);
      }
      _recentUsers.addAll(_allUsers.take(6));
      _totalUsers = _allUsers.length;

      final nowUtc = DateTime.now().toUtc();
      final weekAgo = nowUtc.subtract(const Duration(days: 7));
      var newUsers = 0;
      for (final user in _allUsers) {
        final joined = user.joinedAt?.toUtc();
        if (joined != null && joined.isAfter(weekAgo)) {
          newUsers++;
        }
      }
      _newUsersLast7Days = newUsers;

      _totalLessons = await _safeCount('lessons');
      _totalQuizzes = await _safeCount('quizzes');
      _totalExams = await _safeCount('exams');

      await Future.wait([
        _loadDirectQuestions(),
        _loadAlertsFromDatabase(),
        _loadUserQuestionInbox(),
      ]);

      _appendSystemAlerts();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<int> _safeCount(String table) async {
    try {
      final rows = await Supabase.instance.client.from(table).select('id');
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _loadDirectQuestions() async {
    try {
      final rows = await Supabase.instance.client
          .from('quizzes')
          .select('title,questions,created_at')
          .order('created_at', ascending: false)
          .limit(12);
      for (final raw in rows) {
        final quiz = Map<String, dynamic>.from(raw);
        final title = (quiz['title'] ?? 'Quiz').toString().trim();
        final createdAt = DateTime.tryParse(
          quiz['created_at']?.toString() ?? '',
        )?.toLocal();
        final questions = quiz['questions'];
        if (questions is! List) continue;

        for (final qRaw in questions) {
          if (qRaw is! Map) continue;
          final qMap = Map<String, dynamic>.from(qRaw);
          final text = (qMap['question'] ?? '').toString().trim();
          if (text.isEmpty) continue;
          _directQuestions.add(
            _DirectQuestionPreview(
              question: text,
              sourceQuiz: title,
              createdAt: createdAt,
            ),
          );
          if (_directQuestions.length >= 10) return;
        }
      }
    } catch (_) {
      // Skip if table or column unavailable.
    }
  }

  Future<void> _loadAlertsFromDatabase() async {
    try {
      final rows = await Supabase.instance.client
          .from('student_notifications')
          .select('title,body,kind,is_read,created_at,user_id')
          .order('created_at', ascending: false)
          .limit(16);

      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final title = (row['title'] ?? '').toString().trim();
        final body = (row['body'] ?? '').toString().trim();
        if (title.isEmpty && body.isEmpty) continue;

        final toUser = _labelForUserId((row['user_id'] ?? '').toString());
        final bodyWithTarget = body.isEmpty
            ? 'To: $toUser'
            : '$body\nTo: $toUser';

        _alerts.add(
          _AdminAlert(
            title: title.isEmpty ? 'Notification' : title,
            body: bodyWithTarget,
            read: row['is_read'] == true,
            timestamp: DateTime.tryParse(row['created_at']?.toString() ?? ''),
            target: _targetFromKind((row['kind'] ?? '').toString()),
          ),
        );
      }
    } catch (_) {
      // Table may not exist yet.
    }
  }

  Future<void> _loadUserQuestionInbox() async {
    try {
      final rows = await Supabase.instance.client
          .from('student_question_inbox')
          .select(
            'user_id,user_email,user_name,question,response,source,created_at',
          )
          .order('created_at', ascending: false)
          .limit(30);

      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final question = (row['question'] ?? row['message'] ?? '')
            .toString()
            .trim();
        if (question.isEmpty) continue;

        final userId = (row['user_id'] ?? '').toString().trim();
        final userEmail = (row['user_email'] ?? '').toString().trim();
        final userName = (row['user_name'] ?? '').toString().trim();
        final source = (row['source'] ?? 'chatbot').toString().trim();

        var displayName = userName;
        if (displayName.isEmpty) {
          displayName = _labelForUserId(userId);
        }
        if ((displayName.isEmpty || displayName == '--') &&
            userEmail.isNotEmpty) {
          displayName = userEmail;
        }

        _userQuestions.add(
          _UserQuestionRecord(
            userId: userId,
            userLabel: displayName.isEmpty ? 'User' : displayName,
            userEmail: userEmail,
            question: question,
            answer: (row['response'] ?? '').toString().trim(),
            source: source,
            createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
          ),
        );
      }
    } catch (_) {
      // Optional feature: table may not exist yet.
    }
  }

  _AlertTarget _targetFromKind(String kind) {
    final k = kind.trim().toLowerCase();
    if (k.contains('user')) return _AlertTarget.users;
    if (k.contains('report')) return _AlertTarget.reports;
    if (k.contains('quiz') || k.contains('content') || k.contains('question')) {
      return _AlertTarget.questions;
    }
    return _AlertTarget.dashboard;
  }

  void _appendSystemAlerts() {
    if (_newUsersLast7Days > 0) {
      _alerts.insert(
        0,
        _AdminAlert(
          title: 'New Registrations',
          body:
              'Waxaa ku soo biiray $_newUsersLast7Days user 7dii maalmood ee la soo dhaafay.',
          read: false,
          timestamp: DateTime.now(),
          target: _AlertTarget.users,
        ),
      );
    }

    if (_userQuestions.isNotEmpty) {
      final first = _userQuestions.first;
      _alerts.insert(
        0,
        _AdminAlert(
          title: 'User Question Inbox',
          body: '${first.userLabel}: ${_shorten(first.question, 70)}',
          read: false,
          timestamp: first.createdAt,
          target: _AlertTarget.inbox,
        ),
      );
    }

    if (_directQuestions.isNotEmpty) {
      _alerts.insert(
        0,
        _AdminAlert(
          title: 'Su’aalo Direct Ready',
          body:
              '${_directQuestions.length} su’aalood ayaa diyaar u ah review/edit.',
          read: false,
          timestamp: DateTime.now(),
          target: _AlertTarget.questions,
        ),
      );
    }
  }

  int get _unreadCount => _alerts.where((e) => !e.read).length;

  void _openAlert(_AdminAlert alert) {
    switch (alert.target) {
      case _AlertTarget.users:
        _openUsers();
        break;
      case _AlertTarget.reports:
        _openReports();
        break;
      case _AlertTarget.questions:
        _openDirectQuestions();
        break;
      case _AlertTarget.inbox:
        _openQuestionInboxSheet();
        break;
      case _AlertTarget.dashboard:
        break;
    }
  }

  void _openNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.66,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notifications Center',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),

                      if (_unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$_unreadCount New',
                            style: const TextStyle(
                              color: Color(0xFF3730A3),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _alerts.isEmpty
                        ? const Center(
                            child: Text(
                              'Weli notification ma jirto.',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _alerts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _alerts[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _openAlert(item);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: item.read
                                          ? const Color(0xFFE5E7EB)
                                          : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: const TextStyle(
                                                color: Color(0xFF111827),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(item.timestamp),
                                            style: const TextStyle(
                                              color: Color(0xFF9CA3AF),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.body.trim().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          item.body,
                                          style: const TextStyle(
                                            color: Color(0xFF4B5563),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openQuestionInboxSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'User Question Inbox',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_userQuestions.length} total',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _userQuestions.isEmpty
                        ? const Center(
                            child: Text(
                              'Weli su’aalo user lama keydin.',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _userQuestions.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _userQuestions[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.userLabel,
                                            style: const TextStyle(
                                              color: Color(0xFF111827),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(item.createdAt),
                                          style: const TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.userEmail.trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          item.userEmail,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.question,
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (item.answer.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Jawaab: ${_shorten(item.answer, 180)}',
                                        style: const TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      'Source: ${item.source}',
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }





  String _labelForUserId(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return '--';

    for (final user in _allUsers) {
      if (user.userId == id) return user.displayName;
    }

    if (id.contains('@')) {
      return id.split('@').first;
    }

    if (id.length > 10) {
      return '${id.substring(0, 8)}...';
    }
    return id;
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'now';
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _shorten(String text, int length) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= length) return clean;
    return '${clean.substring(0, length)}...';
  }

  int _questionCountForUser(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return 0;
    return _userQuestions.where((q) => q.userId == id).length;
  }

  void _openUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminUserManagementScreen()),
    );
  }

  void _openReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
    );
  }

  void _openContent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminContentManagementScreen()),
    );
  }

  void _openDirectQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminQuizManagementScreen()),
    );
  }

  void _openCreateDirectQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminQuizFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FC),
        elevation: 0,
        title: const Text(
          'Admin Command Center',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh, color: Color(0xFF1D5AFF)),
          ),

          Stack(
            children: [
              IconButton(
                onPressed: _openNotificationsSheet,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1D5AFF),
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 2),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 14),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 34),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    'Load failed: $_error',
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              _buildQuickActions(),
              const SizedBox(height: 14),
              _buildOverviewStats(),
              const SizedBox(height: 14),
              _buildDirectQuestionsSection(),
              const SizedBox(height: 14),
              _buildRecentUsersSection(),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            _openUsers();
          } else if (index == 2) {
            _openReports();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_rounded),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Overview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalUsers Users • $_totalLessons Lessons • $_totalQuizzes Quizzes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hal meel ayaad ka maamuleysaa users, reports, su’aalo, iyo notifications.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('New 7d: +$_newUsersLast7Days'),
              _pill('Inbox: ${_userQuestions.length} su’aalood'),
              _pill('Alerts: $_unreadCount unread'),
              _pill('Direct Q: ${_directQuestions.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: _actionCard(
                    icon: Icons.assessment_rounded,
                    title: 'Reports',
                    subtitle: 'Open analytics',
                    color: const Color(0xFF0EA5E9),
                    onTap: _openReports,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _actionCard(
                    icon: Icons.folder_special_rounded,
                    title: 'Content Studio',
                    subtitle: 'Lessons & chapters',
                    color: const Color(0xFF6366F1),
                    onTap: _openContent,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _actionCard(
                    icon: Icons.quiz_rounded,
                    title: 'Su’aalo Direct',
                    subtitle: 'Quiz questions',
                    color: const Color(0xFF059669),
                    onTap: _openDirectQuestions,
                  ),
                ),

              ],
            );
          },
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 114),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard('Total Users', '$_totalUsers', Icons.group_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Quizzes',
            '$_totalQuizzes',
            Icons.quiz_rounded,
            iconColor: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Exams',
            '$_totalExams',
            Icons.fact_check_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon, {
    Color iconColor = const Color(0xFF1D5AFF),
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectQuestionsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openCreateDirectQuestion,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Add Questions'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            backgroundColor: const Color(0xFF1D5AFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUsersSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Users',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: _openUsers, child: const Text('View All')),
            ],
          ),
          if (_recentUsers.isEmpty)
            const Text(
              'User data lama helin.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            ..._recentUsers.map((user) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: _openUsers,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE0E7FF),
                  child: Text(
                    user.displayName.isEmpty
                        ? 'U'
                        : user.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  user.displayName,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  user.emailOrId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_questionCountForUser(user.userId)} Q',
                        style: const TextStyle(
                          color: Color(0xFF3730A3),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(user.joinedAt),
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

enum _AlertTarget { dashboard, users, reports, questions, inbox }

class _AdminAlert {
  final String title;
  final String body;
  final bool read;
  final DateTime? timestamp;
  final _AlertTarget target;

  const _AdminAlert({
    required this.title,
    required this.body,
    required this.read,
    required this.timestamp,
    required this.target,
  });
}

class _DirectQuestionPreview {
  final String question;
  final String sourceQuiz;
  final DateTime? createdAt;

  const _DirectQuestionPreview({
    required this.question,
    required this.sourceQuiz,
    required this.createdAt,
  });
}

class _AdminUserOption {
  final String userId;
  final String email;
  final String displayName;
  final DateTime? joinedAt;

  const _AdminUserOption({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.joinedAt,
  });

  String get emailOrId => email.trim().isNotEmpty ? email.trim() : userId;

  factory _AdminUserOption.fromRegistryRow(Map<String, dynamic> row) {
    final userId = (row['user_id'] ?? '').toString().trim();
    final email = (row['email'] ?? '').toString().trim();
    final fullName = (row['full_name'] ?? '').toString().trim();

    var display = fullName;
    if (display.isEmpty && email.isNotEmpty && email.contains('@')) {
      display = email.split('@').first;
    }
    if (display.isEmpty && userId.isNotEmpty) {
      display = userId.length > 12 ? userId.substring(0, 10) : userId;
    }
    if (display.isEmpty) display = 'User';

    return _AdminUserOption(
      userId: userId,
      email: email,
      displayName: display,
      joinedAt: DateTime.tryParse((row['joined_at'] ?? '').toString()),
    );
  }
}

class _UserQuestionRecord {
  final String userId;
  final String userLabel;
  final String userEmail;
  final String question;
  final String answer;
  final String source;
  final DateTime? createdAt;

  const _UserQuestionRecord({
    required this.userId,
    required this.userLabel,
    required this.userEmail,
    required this.question,
    required this.answer,
    required this.source,
    required this.createdAt,
  });
}
