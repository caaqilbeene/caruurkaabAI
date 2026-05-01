// ADMIN SCREEN: Reports-ka maamulka.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeSessions = 0;
  int _newUsersLast7Days = 0;
  String _topStudent = '--';
  String _strugglingStudent = '--';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final rows = await Supabase.instance.client
          .from('student_registry')
          .select('user_id, joined_at');
      final users = List<Map<String, dynamic>>.from(rows);

      final now = DateTime.now().toUtc();
      final weekAgo = now.subtract(const Duration(days: 7));

      var newCount = 0;
      for (final user in users) {
        final joinedRaw = user['joined_at']?.toString();
        if (joinedRaw == null) continue;
        final joined = DateTime.tryParse(joinedRaw)?.toUtc();
        if (joined == null) continue;
        if (joined.isAfter(weekAgo)) {
          newCount++;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalUsers = users.length;
        // NOTE: session tracking table ma jirto hadda,
        // sidaas darteed active sessions waxaa loo isticmaalay tirada users-ka.
        _activeSessions = users.length;
        _newUsersLast7Days = newCount;
        _isLoading = false;
      });

      try {
        final perf = await Supabase.instance.client
            .from('student_performance_summary')
            .select('user_id, accuracy_percent, points_total')
            .order('accuracy_percent', ascending: false);
        if (!mounted) return;
        if (perf.isNotEmpty) {
          final perfList = List<Map<String, dynamic>>.from(perf);
          final top = perfList.first;
          perfList.sort((a, b) {
            final aAcc =
                double.tryParse(a['accuracy_percent']?.toString() ?? '') ?? 0;
            final bAcc =
                double.tryParse(b['accuracy_percent']?.toString() ?? '') ?? 0;
            return aAcc.compareTo(bAcc);
          });
          final struggling = perfList.first;
          setState(() {
            _topStudent = top['user_id']?.toString() ?? '--';
            _strugglingStudent = struggling['user_id']?.toString() ?? '--';
          });
        }
      } catch (_) {
        // Ignore if view not ready.
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const reports = [
      {'title': 'User Growth', 'subtitle': 'Updated now', 'action': 'View'},
      {
        'title': 'Learning Progress',
        'subtitle': 'Updated now',
        'action': 'Download',
      },
      {
        'title': 'Quiz Performance',
        'subtitle': 'Updated now',
        'action': 'View',
      },
      {
        'title': 'Retention Rate',
        'subtitle': 'Last 30 days',
        'action': 'Download',
      },
    ];

    final userGrowth = '+$_newUsersLast7Days';
    final activeSessions = _activeSessions.toString();
    final totalUsers = _totalUsers.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'System Reports',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Overview Statistics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _buildCard('User Growth', userGrowth)),
                const SizedBox(width: 10),
                Expanded(child: _buildCard('Active Sessions', activeSessions)),
              ],
            ),
            const SizedBox(height: 10),
            _buildCard('Total Users', totalUsers),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildCard('Top Student', _topStudent)),
                const SizedBox(width: 10),
                Expanded(child: _buildCard('Needs Help', _strugglingStudent)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Available Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...reports.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFEFF4FF),
                      child: Icon(
                        Icons.description_outlined,
                        color: Color(0xFF1D5AFF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            item['subtitle']!,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['action']!,
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
