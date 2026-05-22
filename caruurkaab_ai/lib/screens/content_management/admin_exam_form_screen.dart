import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_schema_safe_write_service.dart';


class AdminExamFormScreen extends StatefulWidget {
  final Map<String, dynamic>? exam;

  const AdminExamFormScreen({super.key, this.exam});

  @override
  State<AdminExamFormScreen> createState() => _AdminExamFormScreenState();
}

class _AdminExamFormScreenState extends State<AdminExamFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  final TextEditingController _passingScoreController = TextEditingController(
    text: '60',
  );
  final TextEditingController _questionsToAnswerController =
      TextEditingController(text: '10');

  String _examType = 'final_class';
  String? _subject;
  int? _classLevel;
  bool _isActive = true;
  bool _isSaving = false;

  final List<_ExamQuestionEntry> _questions = [_ExamQuestionEntry()];

  final ImagePicker _imagePicker = ImagePicker();
  static const String _bucketName = 'lesson-media';

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<_PickedMedia?> _pickImage() async {
    if (_isMobilePlatform || kIsWeb) {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      return _PickedMedia(
        bytes: bytes,
        name: picked.name,
        contentType: _inferContentType(picked.name),
      );
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes == null) return null;
    return _PickedMedia(
      bytes: file.bytes!,
      name: file.name,
      contentType: _inferContentType(file.name),
    );
  }

  String _inferContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  Future<String?> _uploadToSupabase(_PickedMedia media) async {
    final storage = Supabase.instance.client.storage.from(_bucketName);
    final safeName = media.name.isEmpty ? 'image' : media.name;
    final path = 'exams/${DateTime.now().millisecondsSinceEpoch}-$safeName';

    await storage.uploadBinary(
      path,
      media.bytes,
      fileOptions: FileOptions(contentType: media.contentType, upsert: true),
    );

    return storage.getPublicUrl(path);
  }

  bool get _isEdit => widget.exam != null;

  @override
  void initState() {
    super.initState();
    _loadForEdit();
  }

  void _loadForEdit() {
    final exam = widget.exam;
    if (exam == null) return;

    _titleController.text = (exam['title'] ?? '').toString();
    _descController.text = (exam['desc'] ?? '').toString();
    _noticeController.text = (exam['notice_text'] ?? '').toString();
    _passingScoreController.text =
        (exam['passing_score'] ?? _passingScoreController.text).toString();
    _questionsToAnswerController.text =
        (exam['questions_to_answer'] ??
                exam['total_questions'] ??
                _questionsToAnswerController.text)
            .toString();

    final rawType = (exam['exam_type'] ?? 'final_class').toString().trim();
    _examType = (rawType == 'grand_final') ? 'grand_final' : 'final_class';

    final rawSubject = (exam['subject_name'] ?? '').toString().trim();
    if (rawSubject.isNotEmpty) {
      final validSubjects = const ['Af Soomaali', 'English', 'Xisaab', 'Saynis'];
      if (validSubjects.contains(rawSubject)) {
        _subject = rawSubject;
      } else {
        final matched = validSubjects.firstWhere(
          (s) => s.toLowerCase() == rawSubject.toLowerCase(),
          orElse: () => '',
        );
        if (matched.isNotEmpty) {
          _subject = matched;
        }
      }
    }

    final rawClass = exam['class_level'];
    final parsedClass = rawClass is int
        ? rawClass
        : int.tryParse(rawClass?.toString() ?? '');
    if (parsedClass != null && parsedClass >= 1 && parsedClass <= 4) {
      _classLevel = parsedClass;
    }

    _isActive = exam['is_active'] == null ? true : exam['is_active'] == true;

    _questions.clear();
    final qList = exam['questions'];
    if (qList is List && qList.isNotEmpty) {
      for (final raw in qList) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final entry = _ExamQuestionEntry();
        entry.type = (map['type'] ?? 'mcq').toString().trim().toLowerCase();
        if (!entry.availableTypes.contains(entry.type)) {
          entry.type = 'mcq';
        }
        entry.questionController.text = (map['question'] ?? '').toString();
        entry.imageUrlController.text = (map['imageUrl'] ?? map['image_url'] ?? '').toString();
        final optionsRaw = map['options'];
        final options = optionsRaw is List
            ? optionsRaw.map((o) => o.toString()).toList()
            : <String>[];
        if (entry.type == 'true_false') {
          final correctIndex = map['correctIndex'] is int
              ? map['correctIndex'] as int
              : int.tryParse((map['correctIndex'] ?? '0').toString()) ?? 0;
          entry.trueFalseValue = correctIndex == 0 ? 'True' : 'False';
        } else if (entry.type == 'short_answer') {
          entry.correctAnswerController.text = (map['correctAnswer'] ?? '')
              .toString();
        } else {
          if (options.isNotEmpty) entry.option1Controller.text = options[0];
          if (options.length > 1) entry.option2Controller.text = options[1];
          if (options.length > 2) entry.option3Controller.text = options[2];

          final correctIndex = map['correctIndex'] is int
              ? map['correctIndex'] as int
              : int.tryParse((map['correctIndex'] ?? '0').toString()) ?? 0;
          if (correctIndex == 0) {
            entry.correctChoice = '1';
          } else if (correctIndex == 1) {
            entry.correctChoice = '2';
          } else {
            entry.correctChoice = '3';
          }
        }
        _questions.add(entry);
      }
    }

    if (_questions.isEmpty) {
      _questions.add(_ExamQuestionEntry());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _noticeController.dispose();
    _passingScoreController.dispose();
    _questionsToAnswerController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    if (_questions.length >= 40) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xadka su’aalaha waa 40.')));
      return;
    }
    setState(() => _questions.add(_ExamQuestionEntry()));
  }

  void _removeQuestion(int index) {
    final entry = _questions.removeAt(index);
    entry.dispose();
    setState(() {});
  }

  Future<void> _saveExam() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan geli magaca exam-ka.')),
      );
      return;
    }

    if (_subject == null || _subject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan dooro maadada.')),
      );
      return;
    }
    if (_classLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan dooro fasalka.')),
      );
      return;
    }

    final passingScore =
        int.tryParse(_passingScoreController.text.trim())?.clamp(1, 100) ?? 60;
    final questionsToAnswer =
        int.tryParse(_questionsToAnswerController.text.trim()) ?? 10;

    final builtQuestions = <Map<String, dynamic>>[];
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final questionText = q.questionController.text.trim();
      if (questionText.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Su’aal ${i + 1} waa madhan.')));
        return;
      }

      final imageUrl = q.imageUrlController.text.trim();
      final safeImageUrl = imageUrl.isEmpty ? null : imageUrl;

      if (q.type == 'short_answer') {
        final answer = q.correctAnswerController.text.trim();
        if (answer.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Su’aal ${i + 1}: geli jawaabta saxda ah.')),
          );
          return;
        }
        builtQuestions.add({
          'type': 'short_answer',
          'question': questionText,
          'imageUrl': safeImageUrl,
          'options': <String>[],
          'correctIndex': 0,
          'correctAnswer': answer,
        });
        continue;
      }

      if (q.type == 'true_false') {
        final correctIndex = q.trueFalseValue == 'False' ? 1 : 0;
        builtQuestions.add({
          'type': 'true_false',
          'question': questionText,
          'imageUrl': safeImageUrl,
          'options': const ['True', 'False'],
          'correctIndex': correctIndex,
          'correctAnswer': q.trueFalseValue,
        });
        continue;
      }

      final options = [
        q.option1Controller.text.trim(),
        q.option2Controller.text.trim(),
        q.option3Controller.text.trim(),
      ];

      if (options.any((o) => o.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Su’aal ${i + 1}: buuxi 3-da doorasho ee jawaabta.'),
          ),
        );
        return;
      }

      final selected = int.tryParse(q.correctChoice) ?? 1;
      final correctIndex = (selected - 1).clamp(0, 2);

      builtQuestions.add({
        'type': q.type == 'fill_blank' ? 'fill_blank' : 'mcq',
        'question': questionText,
        'imageUrl': safeImageUrl,
        'options': options,
        'correctIndex': correctIndex,
        'correctAnswer': options[correctIndex],
      });
    }

    if (builtQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan ku dar ugu yaraan hal su’aal.')),
      );
      return;
    }

    final payload = {
      'title': title,
      'desc': _descController.text.trim(),
      'subject_name': _subject!,
      'class_level': _classLevel!,
      'exam_type': _examType,
      'is_active': _isActive,
      'notice_text': _noticeController.text.trim(),
      'passing_score': passingScore,
      'questions_to_answer': questionsToAnswer,
      'total_questions': builtQuestions.length,
      'duration_minutes': 0,
      'questions': builtQuestions,
    };

    setState(() => _isSaving = true);
    try {
      final result = _isEdit
          ? await SupabaseSchemaSafeWriteService.updateWithFallback(
              table: 'exams',
              payload: payload,
              eqColumn: 'id',
              eqValue: widget.exam!['id'],
            )
          : await SupabaseSchemaSafeWriteService.insertWithFallback(
              table: 'exams',
              payload: payload,
            );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Exam updated.' : 'Exam saved.')),
      );
      if (result.removedColumns.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'DB columns qaar ma jiraan: ${result.removedColumns.join(', ')}',
            ),
          ),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final missingTable =
          raw.contains("table 'public.exams'") ||
          raw.toLowerCase().contains('relation "exams" does not exist');
      final friendly = missingTable
          ? 'Table-ka exams wali lama abuurin gudaha Supabase. Fadlan marka hore ku orod SQL setup-ka exams.'
          : SupabaseSchemaSafeWriteService.friendlyError(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $friendly')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Final Exam' : 'Add Final Exam',
          style: const TextStyle(
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
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: _inputDecoration(hint: 'e.g. Final Exam Af Soomaali'),
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
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: _inputDecoration(hint: 'Faahfaahin kooban...'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Notice Text (TALO AI ogeysiis)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noticeController,
            maxLines: 3,
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: _inputDecoration(
              hint: 'Qoraalka aad rabto in ardayga loogu sheego exam-ka.',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Category',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _subject,
            decoration: _inputDecoration(),
            hint: const Text('Dooro Maadada'),
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
            decoration: _inputDecoration(),
            hint: const Text('Dooro Fasalka'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Fasalka 1')),
              DropdownMenuItem(value: 2, child: Text('Fasalka 2')),
              DropdownMenuItem(value: 3, child: Text('Fasalka 3')),
              DropdownMenuItem(value: 4, child: Text('Fasalka 4')),
            ],
            onChanged: (value) {
              setState(() => _classLevel = value);
            },
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
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ardayga ha ka jawaabo (random)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _questionsToAnswerController,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: _inputDecoration(hint: 'e.g. 10'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Exam active ha ahaado'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 8),
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
              child: _buildQuestionCard(q, index),
            );
          }),
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
              onPressed: _isSaving ? null : _saveExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isSaving
                    ? 'Saving...'
                    : (_isEdit ? 'Update Exam' : 'Save Exam'),
                style: const TextStyle(
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

  Widget _buildQuestionCard(_ExamQuestionEntry q, int index) {
    return Container(
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
          DropdownButtonFormField<String>(
            initialValue: q.type,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem(value: 'mcq', child: Text('MCQ (A/B/C)')),
              DropdownMenuItem(
                value: 'true_false',
                child: Text('True / False'),
              ),
              DropdownMenuItem(
                value: 'fill_blank',
                child: Text('Fill in the blank'),
              ),
              DropdownMenuItem(
                value: 'short_answer',
                child: Text('Qor jawaabta'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => q.type = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: q.questionController,
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: _inputDecoration(
              hint: q.type == 'fill_blank'
                  ? 'e.g. 2 + __ = 5'
                  : 'Gali su’aasha...',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: q.imageUrlController,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: _inputDecoration(
              hint: 'Image URL (optional)',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: q.isUploading
                  ? null
                  : () async {
                      setState(() => q.isUploading = true);
                      try {
                        final media = await _pickImage();
                        if (media == null) {
                          if (mounted) setState(() => q.isUploading = false);
                          return;
                        }
                        final url = await _uploadToSupabase(media);
                        if (!mounted) return;
                        if (url != null) {
                          q.imageUrlController.text = url;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exam question image uploaded!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Upload failed: $e'),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => q.isUploading = false);
                        }
                      }
                    },
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(
                q.isUploading ? 'Uploading...' : 'Select Image',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (q.type == 'short_answer')
            TextField(
              controller: q.correctAnswerController,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              decoration: _inputDecoration(hint: 'Jawaabta saxda ah'),
            )
          else if (q.type == 'true_false')
            DropdownButtonFormField<String>(
              initialValue: q.trueFalseValue,
              decoration: _inputDecoration(),
              items: const [
                DropdownMenuItem(value: 'True', child: Text('True')),
                DropdownMenuItem(value: 'False', child: Text('False')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => q.trueFalseValue = value);
              },
            )
          else ...[
            TextField(
              controller: q.option1Controller,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              decoration: _inputDecoration(hint: 'Doorasho 1'),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: q.option2Controller,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              decoration: _inputDecoration(hint: 'Doorasho 2'),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: q.option3Controller,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              decoration: _inputDecoration(hint: 'Doorasho 3'),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: q.correctChoice,
              decoration: _inputDecoration(),
              items: const [
                DropdownMenuItem(
                  value: '1',
                  child: Text('Correct: Doorasho 1'),
                ),
                DropdownMenuItem(
                  value: '2',
                  child: Text('Correct: Doorasho 2'),
                ),
                DropdownMenuItem(
                  value: '3',
                  child: Text('Correct: Doorasho 3'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => q.correctChoice = value);
              },
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _ExamQuestionEntry {
  final Set<String> availableTypes = const {
    'mcq',
    'true_false',
    'fill_blank',
    'short_answer',
  };

  String type = 'mcq';
  String trueFalseValue = 'True';
  String correctChoice = '1';
  bool isUploading = false;

  final TextEditingController questionController = TextEditingController();
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();
  final TextEditingController option3Controller = TextEditingController();
  final TextEditingController correctAnswerController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  void dispose() {
    questionController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    option3Controller.dispose();
    correctAnswerController.dispose();
    imageUrlController.dispose();
  }
}

class _PickedMedia {
  final Uint8List bytes;
  final String name;
  final String contentType;

  const _PickedMedia({
    required this.bytes,
    required this.name,
    required this.contentType,
  });
}
