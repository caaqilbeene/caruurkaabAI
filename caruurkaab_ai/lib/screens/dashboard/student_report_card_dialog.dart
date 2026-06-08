import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  Future<void> _printReportCard() async {
    final pdf = pw.Document();

    pw.ImageProvider? logoImage;
    try {
      logoImage = await imageFromAssetBundle('assets/images/logo.jpeg');
    } catch (_) {}

    final studentName = widget.profile.fullName ?? 'Arday';
    final studentId = widget.profile.studentId;
    final classLevel = 'Class ${widget.classLevel}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null)
                  pw.Center(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      width: 60,
                      height: 60,
                      child: pw.Image(logoImage),
                    ),
                  ),
                pw.Center(
                  child: pw.Text(
                    "WARQADA CADEYNTA NATIIJADA",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    "CaruurKaab AI - Learning Platform",
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.SizedBox(width: 120, child: pw.Text("Magaca Ardayga:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Text(studentName),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.SizedBox(width: 120, child: pw.Text("Admission ID:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Text(studentId),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.SizedBox(width: 120, child: pw.Text("Class Level:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Text(classLevel),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                pw.Text(
                  "Imtixaanka dhexe - Term 1",
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Subject Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Cutubyada (40)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Final Exam (60)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("TOTAL (100)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Grade", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ..._examResults.map((result) {
                      final subjectName = result['subjectName'] as String;
                      final score = result['score'] as SubjectScoreData;
                      final totalScoreVal = score.totalScore;
                      final gradeStr = score.hasTakenFinal ? _getGrade(totalScoreVal) : 'Lama Gelin';

                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(subjectName)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(score.chapterScoreOutOf40.round().toString())),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(score.finalScoreOutOf60.round().toString())),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(score.totalScore.round().toString())),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(gradeStr)),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 50),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Date Issued: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text("School Principal Signature"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              // Centered Logo & Title below it
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Warqada Cadeynta Natiijada',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
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
                    _infoRow('Magaca ardayga', widget.profile.fullName ?? 'Arday'),
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
                'Imtixaanka dhexe - Term 1',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
  
              // Results List
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
                Column(
                  children: _examResults.map((result) {
                    final subjectName = result['subjectName'] as String;
                    final score = result['score'] as SubjectScoreData;
                    final double totalScoreVal = score.totalScore;
                    final String gradeStr = score.hasTakenFinal ? _getGrade(totalScoreVal) : 'Lama Gelin';
  
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(11),
                                topRight: Radius.circular(11),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  subjectName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !score.hasTakenFinal
                                        ? const Color(0xFFE2E8F0)
                                        : (totalScoreVal >= 50
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFFEF2F2)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Grade: $gradeStr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: !score.hasTakenFinal
                                          ? const Color(0xFF64748B)
                                          : (totalScoreVal >= 50
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _scoreRow('Cutubyada (40)', score.chapterScoreOutOf40.round().toString()),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          _scoreRow('Final Exam (60)', score.finalScoreOutOf60.round().toString()),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          _scoreRow('TOTAL (100)', score.totalScore.round().toString(), isBold: true),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              if (!_isLoading && _examResults.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _printReportCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print, color: Colors.white),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Daabac Warqada Cadeynta (Print PDF)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: isBold ? const Color(0xFF1D5AFF) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
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
