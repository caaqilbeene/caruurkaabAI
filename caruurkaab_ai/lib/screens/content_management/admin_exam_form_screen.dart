// ADMIN CONTENT SCREEN: Add/Edit Exam.
import 'package:flutter/material.dart';

class AdminExamFormScreen extends StatefulWidget {
  const AdminExamFormScreen({super.key});

  @override
  State<AdminExamFormScreen> createState() => _AdminExamFormScreenState();
}

class _AdminExamFormScreenState extends State<AdminExamFormScreen> {
  // CHANGED: Controllers for basic exam info.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _totalQuestionsController = TextEditingController(
    text: '20',
  );
  final TextEditingController _passingScoreController = TextEditingController(
    text: '60',
  );
  final TextEditingController _dateController = TextEditingController();

  String _subject = 'Af Soomaali';
  int _classLevel = 1;

  // CHANGED: Local exam question items (future Firestore).
  final List<_ExamQuestionEntry> _questions = [_ExamQuestionEntry()];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _totalQuestionsController.dispose();
    _passingScoreController.dispose();
    _dateController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_ExamQuestionEntry()));
  }

  void _removeQuestion(int index) {
    final entry = _questions.removeAt(index);
    entry.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'Add / Edit Exam',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Exam Title',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: InputDecoration(
              hintText: 'e.g. Imtixaan Af Soomaali',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 3,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: InputDecoration(
              hintText: 'Faahfaahin kooban...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _subject,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Af Soomaali',
                child: Text('Af Soomaali'),
              ),
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Xisaab', child: Text('Xisaab')),
              DropdownMenuItem(value: 'Saynis', child: Text('Saynis')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _subject = value);
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Class Level',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _classLevel,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Fasalka 1')),
              DropdownMenuItem(value: 2, child: Text('Fasalka 2')),
              DropdownMenuItem(value: 3, child: Text('Fasalka 3')),
              DropdownMenuItem(value: 4, child: Text('Fasalka 4')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _classLevel = value);
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Exam Date',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _dateController,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: InputDecoration(
              hintText: 'e.g. 2026-03-20',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Duration (minutes)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: InputDecoration(
              hintText: 'e.g. 30',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Total Questions',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _totalQuestionsController,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Passing Score (%)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passingScoreController,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Exam Questions',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ..._questions.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Su’aal ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: _questions.length <= 1
                              ? null
                              : () => _removeQuestion(index),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: q.questionController,
                      autocorrect: false,
                      enableSuggestions: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      decoration: InputDecoration(
                        hintText: 'Gali su’aasha...',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildOptionField('Jawaab 1', q.option1Controller),
                    const SizedBox(height: 6),
                    _buildOptionField('Jawaab 2', q.option2Controller),
                    const SizedBox(height: 6),
                    _buildOptionField('Jawaab 3', q.option3Controller),
                    const SizedBox(height: 6),
                    _buildOptionField('Jawaab 4', q.option4Controller),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: q.correctIndex,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Jawaab 1')),
                        DropdownMenuItem(value: 2, child: Text('Jawaab 2')),
                        DropdownMenuItem(value: 3, child: Text('Jawaab 3')),
                        DropdownMenuItem(value: 4, child: Text('Jawaab 4')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => q.correctIndex = value);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Ku dar Su’aal'),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // CHANGED: Local payload (future Firestore).
                // ignore: unused_local_variable
                final payload = {
                  'title': _titleController.text.trim(),
                  'desc': _descController.text.trim(),
                  'subject': _subject,
                  'classLevel': _classLevel,
                  'examDate': _dateController.text.trim(),
                  'durationMinutes':
                      int.tryParse(_durationController.text.trim()) ?? 0,
                  'totalQuestions':
                      int.tryParse(_totalQuestionsController.text.trim()) ??
                      _questions.length,
                  'passingScore':
                      int.tryParse(_passingScoreController.text.trim()) ?? 0,
                  'questions': _questions.map((q) => q.toMap()).toList(),
                  'createdAt': DateTime.now().toIso8601String(),
                };
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Exam',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ExamQuestionEntry {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();
  final TextEditingController option3Controller = TextEditingController();
  final TextEditingController option4Controller = TextEditingController();
  int correctIndex = 1;

  Map<String, dynamic> toMap() {
    return {
      'question': questionController.text.trim(),
      'options': [
        option1Controller.text.trim(),
        option2Controller.text.trim(),
        option3Controller.text.trim(),
        option4Controller.text.trim(),
      ],
      'correctIndex': correctIndex,
    };
  }

  void dispose() {
    questionController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    option3Controller.dispose();
    option4Controller.dispose();
  }
}
