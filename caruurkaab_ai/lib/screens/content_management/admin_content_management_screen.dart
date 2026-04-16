// ADMIN CONTENT SCREEN: maamulka casharada iyo categories.
import 'package:caruurkaab_ai/screens/content_management/admin_exam_management_screen.dart';
import 'package:caruurkaab_ai/screens/content_management/admin_lesson_form_screen.dart';
import 'package:caruurkaab_ai/screens/content_management/admin_chapter_management_screen.dart';
import 'package:caruurkaab_ai/screens/content_management/admin_quiz_management_screen.dart';
import 'package:caruurkaab_ai/screens/content_management/admin_system_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends State<AdminContentManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('lessons')
          .select()
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _lessons = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lessons = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }
  }

  void _refreshLessons() {
    _loadLessons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'Content Management',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Raadi qaybaha waxbarashada...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminChapterManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.folder_special, color: Colors.white),
                label: const Text(
                  'Maamul Cutubyada (Manage Chapters)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D5AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _lessons.isEmpty
                  ? const Center(
                      child: Text("Wax cashar ah laguma darin wali."),
                    )
                  : ListView.separated(
                      itemCount: _lessons.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _lessons[index];
                        final title = item['title'] ?? 'Magac La\'aan';
                        final subject = item['subject_name'] ?? '';
                        final classLevel = item['class_level'] ?? '';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF0FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF1D5AFF),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$subject • Fasalka $classLevel",
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminLessonFormScreen(
                                        lesson: Map<String, dynamic>.from(item),
                                      ),
                                    ),
                                  );
                                  if (updated == true) {
                                    _refreshLessons();
                                  }
                                },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Delete Lesson'),
                                        content: const Text(
                                          'Ma hubtaa inaad si joogto ah u tirtirayso cutubkan?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirmed != true) return;
                                  try {
                                    await Supabase.instance.client
                                        .from('lessons')
                                        .delete()
                                        .eq('id', item['id']);
                                    if (!context.mounted) return;
                                    setState(() {
                                      _lessons.removeWhere(
                                        (l) => l['id'] == item['id'],
                                      );
                                    });
                                    _refreshLessons();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Lesson deleted successfully!',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Delete failed: $e'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D5AFF),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminLessonFormScreen()),
          );
          if (created == true) {
            _refreshLessons();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminQuizManagementScreen(),
              ),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminExamManagementScreen(),
              ),
            );
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminSystemSettingsScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Content',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quizzes'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: 'Exams'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
