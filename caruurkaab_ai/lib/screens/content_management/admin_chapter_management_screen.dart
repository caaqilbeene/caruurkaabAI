import 'package:caruurkaab_ai/screens/content_management/admin_chapter_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminChapterManagementScreen extends StatefulWidget {
  const AdminChapterManagementScreen({super.key});

  @override
  State<AdminChapterManagementScreen> createState() =>
      _AdminChapterManagementScreenState();
}

class _AdminChapterManagementScreenState
    extends State<AdminChapterManagementScreen> {
  late Future<List<Map<String, dynamic>>> _futureChapters;

  @override
  void initState() {
    super.initState();
    _futureChapters = _loadChapters();
  }

  Future<List<Map<String, dynamic>>> _loadChapters() {
    return Supabase.instance.client
        .from('chapters')
        .select()
        .order('course_order', ascending: true);
  }

  void _refreshChapters() {
    setState(() {
      _futureChapters = _loadChapters();
    });
  }

  Future<void> _openEditChapter(Map<String, dynamic> chapter) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminChapterFormScreen(chapter: chapter),
      ),
    );
    if (updated == true) {
      _refreshChapters();
    }
  }

  Future<void> _deleteChapter(Map<String, dynamic> chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Cutub'),
          content: const Text(
            'Ma hubtaa inaad si joogto ah u tirtirayso cutubkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('chapters')
          .delete()
          .eq('id', chapter['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cutubka waa la tirtiray!')));
      _refreshChapters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'Maamul Cutubyada (Chapters)',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureChapters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Qalad ayaa dhacay: \${snapshot.error}"));
          }
          final chapters = snapshot.data ?? [];
          if (chapters.isEmpty) {
            return const Center(
              child: Text("Wax cutubyo ah laguma darin wali."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(chapter['id'] ?? index),
                  background: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D5AFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Row(
                      children: [
                        Icon(Icons.edit, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete, color: Colors.white),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await _openEditChapter(chapter);
                      return false;
                    } else {
                      await _deleteChapter(chapter);
                      return false;
                    }
                  },
                  child: InkWell(
                    onTap: () => _openEditChapter(chapter),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter['title'] ?? 'Magac La\'aan',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${chapter['subject_name']} - Fasalka ${chapter['class_level']} | Tartib: ${chapter['course_order']}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1D5AFF),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminChapterFormScreen()),
          );
          if (created == true) {
            _refreshChapters();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Abuur Cutub', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
