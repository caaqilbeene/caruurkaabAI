// ADMIN CONTENT SCREEN: Exam Management.
import 'package:caruurkaab_ai/screens/content_management/admin_exam_form_screen.dart';
import 'package:flutter/material.dart';

class AdminExamManagementScreen extends StatefulWidget {
  const AdminExamManagementScreen({super.key});

  @override
  State<AdminExamManagementScreen> createState() =>
      _AdminExamManagementScreenState();
}

class _AdminExamManagementScreenState extends State<AdminExamManagementScreen> {
  @override
  Widget build(BuildContext context) {
    const exams = [
      {
        'title': 'Cilmi Bulsho (Social Studies)',
        'date': 'Oct 30, 2025 • 41 Arday',
        'status': 'Active',
        'progress': 0.45,
      },
      {
        'title': 'Cilmi Bulsho: Taariikhda',
        'date': 'Oct 22, 2025 • 50 Arday',
        'status': 'Dhamaaday',
        'progress': 1.0,
      },
      {
        'title': 'Luqadda Soomaaliyeed',
        'date': 'Nov 02, 2025 • 52 Arday',
        'status': 'Sugitaan',
        'progress': 0.0,
      },
    ];

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1D5AFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heerka Socodka Guud',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 6),
                Text(
                  '65% Waa Dhamaaday',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...exams.map(
            (exam) => Padding(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exam['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          exam['status'] as String,
                          style: const TextStyle(
                            color: Color(0xFF1D5AFF),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam['date'] as String,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: exam['progress'] as double,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: (exam['progress'] as double) >= 1.0
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1D5AFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // CHANGED: Open exam form screen.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminExamFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Qorshee Imtixaan Cusub',
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
        ],
      ),
    );
  }
}
