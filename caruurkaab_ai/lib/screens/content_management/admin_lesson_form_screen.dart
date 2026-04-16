// ADMIN CONTENT SCREEN: Add/Edit Lesson.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLessonFormScreen extends StatefulWidget {
  final Map<String, dynamic>? lesson;

  const AdminLessonFormScreen({super.key, this.lesson});

  @override
  State<AdminLessonFormScreen> createState() => _AdminLessonFormScreenState();
}

class _AdminLessonFormScreenState extends State<AdminLessonFormScreen> {
  // CHANGED: Controllers si loo diyaariyo Firestore payload.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  static const String _bucketName = 'lesson-media';

  // CHANGED: Subject + class level (1-4).
  String? _subject;
  int? _classLevel;
  static const List<String> _subjects = [
    'Af Soomaali',
    'English',
    'Xisaab',
    'Saynis',
  ];
  static const List<int> _classLevels = [1, 2, 3, 4];

  // CHANGED: Chapter selection
  String? _selectedChapterId;
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoadingChapters = false;

  // CHANGED: Lesson items (text + image) for mixed content.
  final List<_LessonItemEntry> _lessonItems = [_LessonItemEntry.text()];

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
    final path = 'lessons/${DateTime.now().millisecondsSinceEpoch}-$safeName';

    await storage.uploadBinary(
      path,
      media.bytes,
      fileOptions: FileOptions(contentType: media.contentType, upsert: true),
    );

    return storage.getPublicUrl(path);
  }

  @override
  void initState() {
    super.initState();
    _loadForEdit();
    _fetchChapters();
  }

  bool get _isEdit => widget.lesson != null;

  void _loadForEdit() {
    final lesson = widget.lesson;
    if (lesson == null) return;

    _titleController.text = (lesson['title'] ?? '').toString();
    _descController.text = (lesson['desc'] ?? '').toString();
    _imageUrlController.text = (lesson['image_url'] ?? '').toString();
    _durationController.text = (lesson['duration_minutes'] ?? '').toString();

    final rawSubject = (lesson['subject_name'] ?? '').toString();
    _subject = _subjects.contains(rawSubject) ? rawSubject : _subject;

    final rawClass = (lesson['class_level'] ?? _classLevel);
    final parsedClass = rawClass is int
        ? rawClass
        : int.tryParse(rawClass.toString()) ?? _classLevel;
    _classLevel = _classLevels.contains(parsedClass)
        ? parsedClass
        : _classLevel;

    _selectedChapterId = lesson['chapter_id']?.toString();

    _lessonItems.clear();
    final items = lesson['items'];
    if (items is List && items.isNotEmpty) {
      for (final raw in items) {
        if (raw is! Map) continue;
        final type = raw['type']?.toString();
        if (type == 'text') {
          final entry = _LessonItemEntry.text();
          entry.textController.text = (raw['text'] ?? '').toString();
          _lessonItems.add(entry);
        } else if (type == 'image') {
          final entry = _LessonItemEntry.image();
          entry.imageUrlController.text = (raw['imageUrl'] ?? '').toString();
          entry.captionController.text = (raw['caption'] ?? '').toString();
          _lessonItems.add(entry);
        }
      }
    }

    if (_lessonItems.isEmpty) {
      _lessonItems.add(_LessonItemEntry.text());
    }
  }

  Future<void> _fetchChapters() async {
    setState(() {
      _isLoadingChapters = true;
      _chapters = [];
    });
    try {
      if (_subject == null || _classLevel == null) {
        if (mounted) {
          setState(() => _isLoadingChapters = false);
        }
        return;
      }
      final subject = _subject;
      final level = _classLevel;
      if (subject == null || level == null) {
        if (mounted) {
          setState(() => _isLoadingChapters = false);
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
        setState(() {
          _chapters = List<Map<String, dynamic>>.from(data);
          // Auto-select only in edit mode if current chapter exists
          if (_isEdit && _chapters.isNotEmpty) {
            final current = _selectedChapterId;
            final match = current == null
                ? null
                : _chapters.firstWhere(
                    (ch) => ch['id'].toString() == current,
                    orElse: () => {},
                  );
            if (match != null && match.isNotEmpty) {
              _selectedChapterId = current;
            }
          } else {
            _selectedChapterId = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching chapters: \$e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChapters = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    _durationController.dispose();
    for (final item in _lessonItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard-ka waa madhan. Markale copy samee.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      controller.text = text;
      controller.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  Widget _buildPasteButton(TextEditingController controller) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _pasteFromClipboard(controller),
        icon: const Icon(Icons.content_paste),
        label: const Text('Paste Text'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Lesson' : 'Add Lesson',
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
            'Lesson Title',
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
              hintText: 'e.g. Barashada Alifbeetada',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _buildPasteButton(_titleController),
          const SizedBox(height: 12),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _subjects.contains(_subject) ? _subject : null,
            isExpanded: true,
            hint: const Text('Dooro category-ga...'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: _subjects
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
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
            initialValue: _classLevels.contains(_classLevel)
                ? _classLevel
                : null,
            isExpanded: true,
            hint: const Text('Dooro fasalka...'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: _classLevels
                .map(
                  (l) => DropdownMenuItem(
                    value: l,
                    child: Text(
                      'Fasalka $l',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
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
          if (_isLoadingChapters)
            const Center(child: CircularProgressIndicator())
          else if (_subject == null || _classLevel == null)
            const Text(
              'Dooro category-ga iyo fasalka marka hore.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            )
          else if (_chapters.isEmpty)
            const Text(
              'Fadlan abuur cutubyo maadadan ka hor.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            )
          else
            DropdownButtonFormField<String>(
              initialValue:
                  _chapters.any(
                    (ch) => ch['id'].toString() == _selectedChapterId,
                  )
                  ? _selectedChapterId
                  : null,
              isExpanded: true,
              hint: const Text('Dooro cutubka...'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              selectedItemBuilder: (context) {
                return _chapters.map((ch) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ch['title'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: _chapters.map((ch) {
                return DropdownMenuItem<String>(
                  value: ch['id'].toString(),
                  child: Text(
                    ch['title'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedChapterId = value);
              },
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
              hintText: 'e.g. 10',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 6),
          const Text(
            'Qoraalka Casharka (Text + Image)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Halkan ku qor casharkaaga: ku dar Qoraal ama Sawir.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 6),
          ..._lessonItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
                            item.type == _LessonItemType.text
                                ? 'Text Item ${index + 1}'
                                : 'Image Item ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: _lessonItems.length <= 1
                              ? null
                              : () {
                                  final removed = _lessonItems.removeAt(index);
                                  removed.dispose();
                                  setState(() {});
                                },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (item.type == _LessonItemType.text)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: item.textController,
                            maxLines: 6,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            autocorrect: false,
                            enableSuggestions: false,
                            smartDashesType: SmartDashesType.disabled,
                            smartQuotesType: SmartQuotesType.disabled,
                            decoration: InputDecoration(
                              hintText: 'Ku qor casharka halkan...',
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildPasteButton(item.textController),
                        ],
                      ),
                    if (item.type == _LessonItemType.image) ...[
                      TextField(
                        controller: item.imageUrlController,
                        autocorrect: false,
                        enableSuggestions: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        decoration: InputDecoration(
                          hintText: 'Image URL',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: item.isUploading
                              ? null
                              : () async {
                                  setState(() => item.isUploading = true);
                                  try {
                                    final media = await _pickImage();
                                    if (media == null) return;
                                    final url = await _uploadToSupabase(media);
                                    if (url != null) {
                                      item.imageUrlController.text = url;
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Item image uploaded!',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Upload failed: $e'),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => item.isUploading = false);
                                    }
                                  }
                                },
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            item.isUploading ? 'Uploading...' : 'Select Image',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: item.captionController,
                        maxLines: 2,
                        autocorrect: false,
                        enableSuggestions: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        decoration: InputDecoration(
                          hintText: 'Sharaxaad sawirka (optional)',
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _lessonItems.add(_LessonItemEntry.text()));
                  },
                  icon: const Icon(Icons.text_fields),
                  label: const Text('Add Text'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final entry = _LessonItemEntry.image();
                    setState(() => _lessonItems.add(entry));
                    setState(() => entry.isUploading = true);
                    try {
                      final media = await _pickImage();
                      if (media == null) return;
                      final url = await _uploadToSupabase(media);
                      if (url != null) {
                        entry.imageUrlController.text = url;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image uploaded!')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upload failed: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => entry.isUploading = false);
                      }
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Add Image'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (_titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fadlan geli Lesson Title.')),
                  );
                  return;
                }
                if (_subject == null || _subject!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fadlan dooro Category.')),
                  );
                  return;
                }
                if (_classLevel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fadlan dooro Fasalka.')),
                  );
                  return;
                }
                if (_selectedChapterId == null || _selectedChapterId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fadlan dooro Cutubka.')),
                  );
                  return;
                }
                final items = _lessonItems.map((item) => item.toMap()).where((
                  item,
                ) {
                  final type = item['type']?.toString() ?? '';
                  if (type == 'text') {
                    return (item['text']?.toString().trim() ?? '').isNotEmpty;
                  }
                  if (type == 'image') {
                    return (item['imageUrl']?.toString().trim() ?? '')
                        .isNotEmpty;
                  }
                  return false;
                }).toList();
                if (items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fadlan ku dar Qoraal ama Sawir.'),
                    ),
                  );
                  return;
                }

                final textFallback = items
                    .where((it) => it['type'] == 'text')
                    .map((it) => it['text']?.toString().trim() ?? '')
                    .firstWhere((t) => t.isNotEmpty, orElse: () => '');

                final payload = {
                  'title': _titleController.text.trim(),
                  'desc': _descController.text.trim().isNotEmpty
                      ? _descController.text.trim()
                      : textFallback,
                  'subject_name': _subject, // Changed to subject_name
                  'class_level': _classLevel, // Changed to class_level
                  'chapter_id': _selectedChapterId,
                  'duration_minutes':
                      int.tryParse(_durationController.text.trim()) ?? 0,
                  'image_url': null,
                  'items': items,
                  // Supabase handles created_at mostly, but we can pass it if we want
                };

                try {
                  if (_isEdit) {
                    await Supabase.instance.client
                        .from('lessons')
                        .update(payload)
                        .eq('id', widget.lesson!['id']);
                  } else {
                    await Supabase.instance.client
                        .from('lessons')
                        .insert(payload);
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isEdit
                            ? 'Lesson updated successfully!'
                            : 'Lesson saved successfully!',
                      ),
                    ),
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEdit ? 'Update Lesson' : 'Save Lesson',
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
}

enum _LessonItemType { text, image }

class _LessonItemEntry {
  _LessonItemEntry.text() : type = _LessonItemType.text;
  _LessonItemEntry.image() : type = _LessonItemType.image;

  final _LessonItemType type;
  final TextEditingController textController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController captionController = TextEditingController();
  bool isUploading = false;

  Map<String, dynamic> toMap() {
    if (type == _LessonItemType.text) {
      return {'type': 'text', 'text': textController.text.trim()};
    }
    return {
      'type': 'image',
      'imageUrl': imageUrlController.text.trim(),
      'caption': captionController.text.trim(),
    };
  }

  void dispose() {
    textController.dispose();
    imageUrlController.dispose();
    captionController.dispose();
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
