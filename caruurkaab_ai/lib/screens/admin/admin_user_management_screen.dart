// ADMIN SCREEN: Maamulka users (liiska users from Supabase student_registry).
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/admin_user_delete_service.dart';
import 'admin_user_detail_screen.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  bool _isLoading = true;
  String _searchText = '';
  List<Map<String, dynamic>> _users = [];
  final Set<String> _deletingUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final rows = await Supabase.instance.client
          .from('student_registry')
          .select('user_id, email, full_name, student_no, joined_at')
          .order('student_no', ascending: true);

      if (!mounted) return;
      setState(() {
        _users = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _displayName(Map<String, dynamic> user) {
    final fullName = user['full_name']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;

    final email = user['email']?.toString().trim() ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'User';
  }

  String _studentId(Map<String, dynamic> user) {
    final no = user['student_no'] as int?;
    if (no == null) return 'STD------';
    return 'STD${no.toString().padLeft(6, '0')}';
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final userId = (user['user_id'] ?? '').toString().trim();
    if (userId.isEmpty || _deletingUserIds.contains(userId)) return;

    final email = (user['email'] ?? '').toString().trim();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('Ma tirtirtaa user-kan?\n\n$email'),
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

    setState(() {
      _deletingUserIds.add(userId);
    });

    try {
      await AdminUserDeleteService.deleteUserEverywhere(
        userId: userId,
        email: email.isEmpty ? null : email,
      );
      if (!mounted) return;
      setState(() {
        _users.removeWhere((u) => (u['user_id'] ?? '').toString() == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User-ka si permanent ah ayaa loo tirtiyay.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is AdminUserDeleteException
          ? e.message
          : 'Delete failed. Fadlan mar kale isku day.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() {
          _deletingUserIds.remove(userId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      final name = _displayName(u).toLowerCase();
      final email = (u['email']?.toString() ?? '').toLowerCase();
      final needle = _searchText.toLowerCase();
      return name.contains(needle) || email.contains(needle);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              onChanged: (value) => setState(() => _searchText = value),
              decoration: InputDecoration(
                hintText: 'Search users by name or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Ma jiro user la helay.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final name = _displayName(user);
                      final email =
                          user['email']?.toString() ??
                          user['user_id'].toString();
                      final userId = (user['user_id'] ?? '').toString();
                      final deleting = _deletingUserIds.contains(userId);
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final deleted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(
                                user: user,
                                displayName: name,
                                studentId: _studentId(user),
                              ),
                            ),
                          );
                          if (deleted == true) {
                            _loadUsers();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFEFF4FF),
                                child: Text(name[0].toUpperCase()),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F7EE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _studentId(user),
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: 'Delete user',
                                onPressed: deleting
                                    ? null
                                    : () => _deleteUser(user),
                                icon: deleting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.delete_forever_rounded,
                                        color: Color(0xFFDC2626),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
