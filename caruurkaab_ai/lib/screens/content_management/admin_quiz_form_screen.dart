// ADMIN CONTENT SCREEN: Add/Edit Quiz.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_schema_safe_write_service.dart';

class AdminQuizFormScreen extends StatefulWidget {
  final Map<String, dynamic>? quiz;
  const AdminQuizFormScreen({super.key, this.quiz});

  @override
  State<AdminQuizFormScreen> createState() => _AdminQuizFormScreenState();
}

class _AdminQuizFormScreenState extends State<AdminQuizFormScreen> {
  // CHANGED: Controllers for basic quiz info.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _passingScoreController = TextEditingController(
    text: '50',
  );

  String? _subject;
  int? _classLevel;
  List<Map<String, dynamic>> _chapters = [];
  String? _selectedChapterId;
  bool _isLoadingChapters = false;

  // CHANGED: Local question items (future Firestore).
  final List<_QuizQuestionEntry> _questions = [_QuizQuestionEntry()];

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
    final path = 'quizzes/${DateTime.now().millisecondsSinceEpoch}-$safeName';

    await storage.uploadBinary(
      path,
      media.bytes,
      fileOptions: FileOptions(contentType: media.contentType, upsert: true),
    );

    return storage.getPublicUrl(path);
  }

  bool get _isEdit => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    _loadForEdit();
    _fetchChapters();
  }

  void _loadForEdit() {
    final quiz = widget.quiz;
    if (quiz == null) return;

    _titleController.text = (quiz['title'] ?? '').toString();
    _descController.text = (quiz['desc'] ?? '').toString();
    _passingScoreController.text =
        (quiz['passing_score'] ?? _passingScoreController.text).toString();

    final rawSubject = (quiz['subject_name'] ?? '').toString();
    if (rawSubject.isNotEmpty) _subject = rawSubject;

    final rawClass = quiz['class_level'];
    final parsedClass = rawClass is int
        ? rawClass
        : int.tryParse(rawClass?.toString() ?? '');
    if (parsedClass != null) _classLevel = parsedClass;

    _selectedChapterId = quiz['chapter_id']?.toString();
    _questions.clear();
    final qList = quiz['questions'];
    if (qList is List && qList.isNotEmpty) {
      for (final raw in qList) {
        if (raw is! Map) continue;
        final entry = _QuizQuestionEntry();
        entry.type = (raw['type'] ?? 'mcq').toString().trim().toLowerCase();
        if (entry.type != 'true_false' && entry.type != 'fill_blank') {
          entry.type = 'mcq';
        }

        entry.questionController.text = (raw['question'] ?? '').toString();
        entry.imageUrlController.text = (raw['imageUrl'] ?? '').toString();

        if (entry.type == 'true_false') {
          final correctIndex = raw['correctIndex'] is int
              ? raw['correctIndex'] as int
              : int.tryParse((raw['correctIndex'] ?? '0').toString()) ?? 0;
          entry.trueFalseValue = correctIndex == 0 ? 'True' : 'False';
        } else {
          final options = raw['options'];
          if (options is List && options.length >= 3) {
            entry.option1Controller.text = (options[0] ?? '').toString();
            entry.option2Controller.text = (options[1] ?? '').toString();
            entry.option3Controller.text = (options[2] ?? '').toString();
            final correctIndex = raw['correctIndex'];
            if (correctIndex is int &&
                correctIndex >= 0 &&
                correctIndex < options.length) {
              entry.correctAnswerController.text = (options[correctIndex] ?? '')
                  .toString();
            }
          }
        }
        _questions.add(entry);
      }
    }
    if (_questions.isEmpty) {
      _questions.add(_QuizQuestionEntry());
    }
  }

  Future<void> _fetchChapters() async {
    setState(() {
      _isLoadingChapters = true;
      _chapters = [];
      if (!_isEdit) {
        _selectedChapterId = null;
      }
    });
    try {
      final subject = _subject;
      final level = _classLevel;
      if (subject == null || level == null) {
        if (mounted) {
          setState(() {
            _isLoadingChapters = false;
          });
        }
        return;
      }
      final data = await Supabase.instance.client
          .from('chapters')
          .select()
          .eq('subject_name', subject)
          .eq('class_level', level)
          .order('course_order', ascending: true);

      if (mounted) {
        var chapterStillExists = false;
        if (_selectedChapterId != null && _selectedChapterId!.isNotEmpty) {
          chapterStillExists = data.any(
            (row) => row['id']?.toString() == _selectedChapterId,
          );
        }
        setState(() {
          _chapters = List<Map<String, dynamic>>.from(data);
          if (!chapterStillExists) {
            _selectedChapterId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fetch chapters failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingChapters = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _passingScoreController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    if (_questions.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waxaad gaartay xadka 20 su’aal.')),
      );
      return;
    }
    setState(() => _questions.add(_QuizQuestionEntry()));
  }

  void _removeQuestion(int index) {
    final entry = _questions.removeAt(index);
    entry.dispose();
    setState(() {});
  }

  int _defaultPoints() => 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Quiz' : 'Add / Edit Quiz',
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
            'Quiz Title',
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
              hintText: 'e.g. Su’aalaha Af Soomaali',
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
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            hint: const Text('Dooro maaddada'),
            items: const [
              DropdownMenuItem(
                value: 'Af Soomaali',
                child: Text('Af Soomaali', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'English',
                child: Text('English', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'Xisaab',
                child: Text('Xisaab', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'Saynis',
                child: Text('Saynis', overflow: TextOverflow.ellipsis),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _subject = value;
                _selectedChapterId = null;
              });
              _fetchChapters();
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
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            hint: const Text('Dooro fasalka'),
            items: const [
              DropdownMenuItem(
                value: 1,
                child: Text('Fasalka 1', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text('Fasalka 2', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text('Fasalka 3', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 4,
                child: Text('Fasalka 4', overflow: TextOverflow.ellipsis),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _classLevel = value;
                _selectedChapterId = null;
              });
              _fetchChapters();
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Chapter (Cutubka)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('chapter_${_selectedChapterId ?? ''}'),
            initialValue: _selectedChapterId,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text(_isLoadingChapters ? 'Sug...' : 'Dooro cutubka'),
            items: _chapters
                .map(
                  (ch) => DropdownMenuItem<String>(
                    value: ch['id'].toString(),
                    child: Text(
                      ch['title']?.toString() ?? 'Cutub',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isLoadingChapters
                ? null
                : (value) {
                    setState(() {
                      _selectedChapterId = value;
                    });
                  },
          ),
          if (!_isLoadingChapters && _chapters.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Ma jiraan cutubyo la heli karo.',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
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
            'Quiz Questions',
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
                    DropdownButtonFormField<String>(
                      initialValue: q.type,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'mcq', child: Text('MCQ (A/B/C)')),
                        DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                        DropdownMenuItem(value: 'fill_blank', child: Text('Fill in the blank')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => q.type = value);
                      },
                    ),
                    const SizedBox(height: 8),
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
                    TextField(
                      controller: q.imageUrlController,
                      readOnly: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      decoration: InputDecoration(
                        hintText: 'Image URL (optional)',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
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
                                  if (url != null) {
                                    q.imageUrlController.text = url;
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Quiz image uploaded!'),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Upload failed: $e'),
                                      ),
                                    );
                                  }
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
                    if (q.type == 'true_false') ...[
                      DropdownButtonFormField<String>(
                        initialValue: q.trueFalseValue,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'True', child: Text('True')),
                          DropdownMenuItem(value: 'False', child: Text('False')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => q.trueFalseValue = value);
                        },
                      ),
                    ] else ...[
                      _buildOptionField('Jawaab 1', q.option1Controller),
                      const SizedBox(height: 6),
                      _buildOptionField('Jawaab 2', q.option2Controller),
                      const SizedBox(height: 6),
                      _buildOptionField('Jawaab 3', q.option3Controller),
                      const SizedBox(height: 8),
                      TextField(
                        controller: q.correctAnswerController,
                        autocorrect: false,
                        enableSuggestions: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        decoration: InputDecoration(
                          hintText: q.type == 'fill_blank'
                              ? 'Correct Answer (Geli jawaabta saxda ah)'
                              : 'Correct Answer (waxaad qori kartaa A/B/C ama jawaabta saxda ah)',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
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
              onPressed: () async {
                if (_subject == null || _subject!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fadlan dooro maaddada.')),
                  );
                  return;
                }
                if (_classLevel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fadlan dooro fasalka.')),
                  );
                  return;
                }
                if (_selectedChapterId == null || _selectedChapterId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fadlan dooro cutubka.')),
                  );
                  return;
                }
                final questions = <Map<String, dynamic>>[];
                for (final q in _questions) {
                  final question = q.questionController.text.trim();
                  if (question.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fadlan buuxi su’aasha.')),
                    );
                    return;
                  }

                  if (q.type == 'true_false') {
                    final correctIndex = q.trueFalseValue == 'False' ? 1 : 0;
                    questions.add({
                      'type': 'true_false',
                      'question': question,
                      'imageUrl': q.imageUrlController.text.trim(),
                      'options': const ['True', 'False'],
                      'correctIndex': correctIndex,
                      'correctAnswer': q.trueFalseValue,
                      'points': _defaultPoints(),
                    });
                    continue;
                  }

                  final options = [
                    q.option1Controller.text.trim(),
                    q.option2Controller.text.trim(),
                    q.option3Controller.text.trim(),
                  ];
                  final correctText = q.correctAnswerController.text.trim();
                  final correctIndex = q.resolveCorrectIndex(
                    correctText,
                    options,
                  );
                  if (options.any((o) => o.isEmpty) || correctText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fadlan buuxi su’aasha, 3‑da jawaab, iyo correct‑ka.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (correctIndex == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Correct‑ka waa inuu ka mid noqdaa 3‑da jawaab (ama A/B/C).',
                        ),
                      ),
                    );
                    return;
                  }
                  questions.add({
                    'type': q.type,
                    'question': question,
                    'imageUrl': q.imageUrlController.text.trim(),
                    'options': options,
                    'correctIndex': correctIndex,
                    'correctAnswer': options[correctIndex],
                    'points': _defaultPoints(),
                  });
                }

                final payload = {
                  'title': _titleController.text.trim(),
                  'desc': _descController.text.trim(),
                  'subject_name': _subject,
                  'class_level': _classLevel,
                  'chapter_id':
                      int.tryParse(_selectedChapterId!) ?? _selectedChapterId,
                  'lesson_id': null,
                  'duration_minutes': 0,
                  'total_questions': _questions.length,
                  'passing_score':
                      int.tryParse(_passingScoreController.text.trim()) ?? 0,
                  'default_question_seconds': 45,
                  'questions': questions,
                };

                try {
                  final result = _isEdit
                      ? await SupabaseSchemaSafeWriteService.updateWithFallback(
                          table: 'quizzes',
                          payload: payload,
                          eqColumn: 'id',
                          eqValue: widget.quiz!['id'],
                        )
                      : await SupabaseSchemaSafeWriteService.insertWithFallback(
                          table: 'quizzes',
                          payload: payload,
                        );
                  if (!context.mounted) return;
                  final successText = _isEdit
                      ? 'Quiz updated successfully!'
                      : 'Quiz saved successfully!';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(successText)));

                  if (result.removedColumns.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "DB-ga wali ma hayo columns cusub: ${result.removedColumns.join(', ')}. Laakiin quiz-ka waa la kaydiyay.",
                        ),
                      ),
                    );
                    if (result.removedColumns.contains('lesson_id')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fiiro: lesson_id column ma jiro, marka quiz-ku cashar gaar ah kuma xirmayo.',
                          ),
                        ),
                      );
                    }
                  }
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  final friendly = SupabaseSchemaSafeWriteService.friendlyError(
                    e,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Save failed: $friendly')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEdit ? 'Update Quiz' : 'Save Quiz',
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

class _QuizQuestionEntry {
  String type = 'mcq';
  String trueFalseValue = 'True';
  final TextEditingController questionController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();
  final TextEditingController option3Controller = TextEditingController();
  final TextEditingController correctAnswerController = TextEditingController();
  bool isUploading = false;

  int? resolveCorrectIndex(String correct, List<String> options) {
    final raw = correct.trim();
    if (raw.isEmpty) return null;

    final upper = raw.toUpperCase();
    final letterMatch = RegExp(r'\b(A|B|C)\b').firstMatch(upper);
    if (letterMatch != null) {
      final letter = letterMatch.group(1);
      if (letter == 'A') return 0;
      if (letter == 'B') return 1;
      if (letter == 'C') return 2;
    }

    String normalize(String value) {
      final cleaned = value.trim().toLowerCase();
      final noLabel = cleaned
          .replaceFirst(RegExp(r'^[a-c][\\).\\-\\s]+'), '')
          .trim();
      return noLabel.replaceAll(RegExp(r'[^a-z0-9\\s]'), '').trim();
    }

    final target = normalize(raw);
    for (var i = 0; i < options.length; i++) {
      final optionRaw = options[i].trim();
      if (optionRaw.toLowerCase() == raw.toLowerCase()) return i;
      if (normalize(optionRaw) == target) return i;
    }
    return null;
  }

  void dispose() {
    questionController.dispose();
    imageUrlController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    option3Controller.dispose();
    correctAnswerController.dispose();
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
