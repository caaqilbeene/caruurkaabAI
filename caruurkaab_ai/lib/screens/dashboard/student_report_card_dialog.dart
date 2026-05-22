import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/student_profile_record.dart';
import '../../services/final_exam_service.dart';

class StudentReportCardDialog extends StatefulWidget {
  final StudentProfileRecord profile;
  final int classLevel;

  const StudentReportCardDialog({
    super.key,
    required this.profile,
    required this.classLevel,
  });

  static void show(
    BuildContext context,
    StudentProfileRecord profile,
    int classLevel,
  ) {
    showDialog(
      context: context,
      builder: (_) => StudentReportCardDialog(
        profile: profile,
        classLevel: classLevel,
      ),
    );
  }

  @override
  State<StudentReportCardDialog> createState() =>
      _StudentReportCardDialogState();
}

class _StudentReportCardDialogState extends State<StudentReportCardDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _examResults = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      final db = Supabase.instance.client;
      final examsRows = await db
          .from('exams')
          .select('id, subject_name')
          .eq('exam_type', 'final_class')
          .eq('class_level', widget.classLevel)
          .eq('is_active', true);

      List<Map<String, dynamic>> results = [];
      for (final row in examsRows) {
        final examId = row['id'].toString();
        final subjectName = row['subject_name'].toString();
        final score = await FinalExamService.fetchCombinedSubjectScore(
          subjectName,
          widget.classLevel,
          examId,
        );
        if (score != null) {
          results.add({
            'subjectName': subjectName,
            'score': score,
          });
        }
      }

      if (mounted) {
        setState(() {
          _examResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Shahaadada Ardayga',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Student Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Student Name', widget.profile.fullName ?? 'Arday'),
                  const SizedBox(height: 4),
                  _infoRow('Admn No (ID)', widget.profile.studentId),
                  const SizedBox(height: 4),
                  _infoRow('Class Level', 'Class ${widget.classLevel}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Table Header
            const Text(
              'Scholastic Areas - Term 1',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),

            // Results Table
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_examResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Ma jiraan imtixaano firfircoon.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF1F5F9),
                    ),
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(
                        label: Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Cutubyada (40)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Final Exam (60)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('TOTAL (100)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                    rows: _examResults.map((result) {
                      final subjectName = result['subjectName'] as String;
                      final score = result['score'] as SubjectScoreData;
                      return DataRow(cells: [
                        DataCell(Text(subjectName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(score.chapterScoreOutOf40.round().toString())),
                        DataCell(Text(score.finalScoreOutOf60.round().toString())),
                        DataCell(Text(
                          score.totalScore.round().toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          _getGrade(score.totalScore),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: score.totalScore >= 50 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
              fontSize: 13,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
