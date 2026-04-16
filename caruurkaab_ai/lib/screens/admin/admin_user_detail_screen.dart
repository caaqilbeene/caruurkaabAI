import 'package:flutter/material.dart';

import '../../services/admin_user_delete_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String displayName;
  final String studentId;

  const AdminUserDetailScreen({
    super.key,
    required this.user,
    required this.displayName,
    required this.studentId,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool _isDeleting = false;

  String _formatJoined(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '--';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    return '${dt.day} $month, ${dt.year}';
  }

  Future<void> _deleteUser() async {
    if (_isDeleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text(
          'User-kan hal taabasho ayaa looga tirtirayaa Firebase + Supabase labadaba.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final userId = widget.user['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;

    setState(() => _isDeleting = true);
    final email = widget.user['email']?.toString();

    try {
      await AdminUserDeleteService.deleteUserEverywhere(
        userId: userId,
        email: (email == null || email.isEmpty) ? null : email,
      );
      if (!mounted) return;
      final message = 'Success: User-ka waa laga saaray.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AdminUserDeleteException
          ? e.message
          : 'Delete failed. Fadlan isku day mar kale.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        widget.user['email']?.toString() ?? widget.user['user_id'].toString();
    final joinedAt = _formatJoined(widget.user['joined_at']?.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'User Detail',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ID: ${widget.studentId}',
                style: const TextStyle(
                  color: Color(0xFF1D5AFF),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Joined $joinedAt',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isDeleting ? null : _deleteUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Delete Permanently',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
