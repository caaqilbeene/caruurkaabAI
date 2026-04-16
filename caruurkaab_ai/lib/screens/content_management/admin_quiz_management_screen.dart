// ADMIN CONTENT SCREEN: Quiz Management.
import 'package:caruurkaab_ai/screens/content_management/admin_quiz_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminQuizManagementScreen extends StatefulWidget {
  const AdminQuizManagementScreen({super.key});

  @override
  State<AdminQuizManagementScreen> createState() =>
      _AdminQuizManagementScreenState();
}

class _AdminQuizManagementScreenState extends State<AdminQuizManagementScreen> {
  Future<List<Map<String, dynamic>>> _futureQuizzes = Future.value([]);

  @override
  void initState() {
    super.initState();
    _futureQuizzes = _fetchQuizzes();
  }

  Future<List<Map<String, dynamic>>> _fetchQuizzes() {
    return Supabase.instance.client
        .from('quizzes')
        .select()
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'Quiz Management',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // CHANGED: Open quiz form screen.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminQuizFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Abuur Quiz Cusub',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureQuizzes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text("Qalad ayaa dhacay: ${snapshot.error}"),
                );
              }
              final quizList = snapshot.data ?? [];
              if (quizList.isEmpty) {
                return const Center(
                  child: Text("Wax quiz ah laguma darin wali."),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quizList.length,
                itemBuilder: (context, index) {
                  final quiz = quizList[index];
                  final title = quiz['title'] ?? 'Quiz La\'aan';
                  final subject = quiz['subject_name'] ?? '';
                  final totalQs = quiz['total_questions'] ?? 0;
                  final durationM = quiz['duration_minutes'] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$subject • $totalQs Su'aalo • $durationM daqiiqo",
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminQuizFormScreen(quiz: quiz),
                                      ),
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _futureQuizzes = _fetchQuizzes();
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF0FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Wax ka beddel',
                                        style: TextStyle(
                                          color: Color(0xFF1D5AFF),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Tirtir Quiz?'),
                                      content: const Text(
                                        'Ma hubtaa inaad si joogto ah u tirtirto quiz‑kan?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Maya'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Haa, tirtir'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) return;
                                  try {
                                    await Supabase.instance.client
                                        .from('quizzes')
                                        .delete()
                                        .eq('id', quiz['id']);
                                    if (!context.mounted) return;
                                    setState(() {
                                      _futureQuizzes = _fetchQuizzes();
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Quiz waa la tirtiray!'),
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
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
