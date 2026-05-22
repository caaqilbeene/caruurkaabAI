import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_exam_form_screen.dart';

class AdminExamManagementScreen extends StatefulWidget {
  const AdminExamManagementScreen({super.key});

  @override
  State<AdminExamManagementScreen> createState() =>
      _AdminExamManagementScreenState();
}

class _AdminExamManagementScreenState extends State<AdminExamManagementScreen> {
  bool _isLoading = true;
  bool _isExamsTableMissing = false;
  List<Map<String, dynamic>> _exams = const [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  String? _extractMissingExamColumn(PostgrestException e) {
    final combined = '${e.message} ${e.details} ${e.hint}';

    final pgrst = RegExp(
      r"Could not find the '([^']+)' column of 'exams'",
      caseSensitive: false,
    ).firstMatch(combined);
    if (pgrst != null) return pgrst.group(1);

    final pg = RegExp(
      r'column\s+exams\.([a-zA-Z0-9_]+)\s+does not exist',
      caseSensitive: false,
    ).firstMatch(combined);
    return pg?.group(1);
  }

  Future<void> _loadExams() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isExamsTableMissing = false;
      });
    }

    final selected = <String>[
      'id',
      'title',
      'subject_name',
      'class_level',
      'exam_type',
      'is_active',
      'questions',
      'passing_score',
      'questions_to_answer',
      'created_at',
    ];
    final removed = <String>{};

    try {
      while (true) {
        try {
          final rows = await Supabase.instance.client
              .from('exams')
              .select(selected.join(','))
              .order('created_at', ascending: false);

          if (!mounted) return;
          setState(() {
            _exams = rows.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
          return;
        } on PostgrestException catch (e) {
          if (_isMissingExamsTableError(e)) {
            if (!mounted) return;
            setState(() {
              _exams = const [];
              _isExamsTableMissing = true;
              _isLoading = false;
            });
            return;
          }
          final missing = _extractMissingExamColumn(e);
          final canRecover =
              (e.code == 'PGRST204' || e.code == '42703') &&
              missing != null &&
              selected.contains(missing) &&
              !removed.contains(missing);
          if (!canRecover) rethrow;
          selected.remove(missing);
          removed.add(missing);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _exams = const [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exam load failed: $e')));
    }
  }

  bool _isMissingExamsTableError(PostgrestException e) {
    final code = (e.code ?? '').toString().trim();
    final combined = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    if (code == 'PGRST205' || code == '42P01') {
      return combined.contains('exams');
    }
    return combined.contains("table 'public.exams'") ||
        combined.contains('relation "exams" does not exist');
  }

  Future<void> _openCreateExam() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminExamFormScreen()),
    );
    if (created == true) {
      _loadExams();
    }
  }

  Future<void> _openEditExam(Map<String, dynamic> exam) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminExamFormScreen(exam: Map<String, dynamic>.from(exam)),
      ),
    );
    if (updated == true) {
      _loadExams();
    }
  }

  Future<void> _deleteExam(Map<String, dynamic> exam) async {
    final id = exam['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text('Ma hubtaa inaad exam-kan tirtirayso?'),
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

    if (ok != true) return;

    try {
      await Supabase.instance.client.from('exams').delete().eq('id', id);
      if (!mounted) return;
      setState(() {
        _exams = _exams.where((row) => row['id']?.toString() != id).toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exam deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  String _examTypeLabel(Map<String, dynamic> exam) {
    final type = (exam['exam_type'] ?? '').toString().trim().toLowerCase();
    if (type == 'grand_final') return 'Grand Final';
    return 'Class Final';
  }

  String _subtitle(Map<String, dynamic> exam) {
    if ((exam['exam_type'] ?? '').toString().trim().toLowerCase() ==
        'grand_final') {
      return 'Dhamaadka 4ta fasal';
    }

    final subject = (exam['subject_name'] ?? 'Maado').toString();
    final cls = (exam['class_level'] ?? '').toString();
    return '$subject • Fasalka $cls';
  }

  int _questionCount(Map<String, dynamic> exam) {
    final questions = exam['questions'];
    if (questions is List) return questions.length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'Exam Management',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadExams,
            icon: const Icon(Icons.refresh, color: Color(0xFF1D5AFF)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isExamsTableMissing
            ? _buildExamsTableMissingView()
            : _exams.isEmpty
            ? const Center(
                child: Text(
                  'Weli exam lama darin.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: _exams.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final exam = _exams[index];
                  final active =
                      exam['is_active'] == null || exam['is_active'] == true;

                  return InkWell(
                    onTap: () => _openEditExam(exam),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (exam['title'] ?? 'Final Exam').toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  active ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: active
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _subtitle(exam),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _MiniChip(label: _examTypeLabel(exam)),
                              const SizedBox(width: 8),
                              _MiniChip(
                                label: '${_questionCount(exam)} su’aal',
                              ),
                              const SizedBox(width: 8),
                              _MiniChip(
                                label:
                                    'Pass ${exam['passing_score']?.toString() ?? '60'}%',
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => _deleteExam(exam),
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1D5AFF),
        onPressed: _openCreateExam,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ku dar Final Exam',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildExamsTableMissingView() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 34),
            SizedBox(height: 10),
            Text(
              'Table-ka exams ma jiro',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fadlan ku orod SQL setup-ka final exams gudaha Supabase SQL Editor, kadib dib u fur boggan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
