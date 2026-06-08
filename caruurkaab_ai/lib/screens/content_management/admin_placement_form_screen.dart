import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_schema_safe_write_service.dart';

class AdminPlacementFormScreen extends StatefulWidget {
  final Map<String, dynamic>? question;

  const AdminPlacementFormScreen({super.key, this.question});

  @override
  State<AdminPlacementFormScreen> createState() =>
      _AdminPlacementFormScreenState();
}

class _AdminPlacementFormScreenState extends State<AdminPlacementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _promptEmojiController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final ImagePicker _imagePicker = ImagePicker();

  static const String _bucketName = 'placement_images';

  String _subject = 'Seynis';
  String _type = 'mcq';
  int _correctIndex = 0;
  bool _isUploading = false;

  final List<String> _subjects = [
    'Seynis',
    'Xisaab',
    'Af-Soomaali',
    'English',
    'Aqoonta Guud',
    'Aqoonsi Sawir',
  ];

  final Map<String, String> _typeLabels = {
    'mcq': 'Xulasho Dhowr ah (MCQ)',
    'boolean': 'Run ama Galad (True/False)',
    'image': 'Aqoonsi Sawir (Image/Emoji)',
  };

  bool get _isEdit => widget.question != null;

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _loadForEdit();
  }

  void _loadForEdit() {
    final question = widget.question;
    if (question == null) {
      _addOptionField();
      _addOptionField();
      _addOptionField();
      _addOptionField();
      return;
    }

    _questionController.text = (question['question'] ?? '').toString();
    _promptEmojiController.text = (question['prompt_emoji'] ?? '').toString();
    _imageUrlController.text = (question['image_url'] ?? '').toString();

    final rawSubject = (question['subject'] ?? '').toString();
    if (_subjects.contains(rawSubject)) {
      _subject = rawSubject;
    } else if (rawSubject.isNotEmpty) {
      _subject = rawSubject;
    }

    final rawType = (question['type'] ?? 'mcq').toString();
    if (_typeLabels.containsKey(rawType)) {
      _type = rawType;
    }

    _correctIndex = (question['correct_index'] ?? 0) is int
        ? (question['correct_index'] as int)
        : int.tryParse((question['correct_index'] ?? 0).toString()) ?? 0;

    final options = question['options'];
    if (options is List) {
      for (final opt in options) {
        _optionControllers.add(TextEditingController(text: opt.toString()));
      }
    }

    if (_optionControllers.isEmpty) {
      _addOptionField();
    }
  }

  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOptionField(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ugu yaraan waa in labo xulasho ay jirtaa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      final controller = _optionControllers.removeAt(index);
      controller.dispose();
      if (_correctIndex >= _optionControllers.length) {
        _correctIndex = _optionControllers.length - 1;
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _promptEmojiController.dispose();
    _imageUrlController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
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
    final path = 'placement/${DateTime.now().millisecondsSinceEpoch}-$safeName';

    await storage.uploadBinary(
      path,
      media.bytes,
      fileOptions: FileOptions(contentType: media.contentType, upsert: true),
    );

    return storage.getPublicUrl(path);
  }

  Future<void> _handleImageSelection() async {
    setState(() => _isUploading = true);
    try {
      final media = await _pickImage();
      if (media == null) return;
      final url = await _uploadToSupabase(media);
      if (url != null) {
        _imageUrlController.text = url;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sawirka si guul leh ayaa loo geliyay!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelinta sawirka waa uu guuldarraystay: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard-ka waa maran yahay. Markale koobiyeey.'),
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
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => _pasteFromClipboard(controller),
        icon: const Icon(Icons.paste_rounded, size: 16),
        label: const Text('Daji Qoraalka (Paste)', style: TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fadlan qor su\'aasha.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<String> options = [];
    if (_type == 'boolean') {
      options = ['Run', 'Galad'];
      if (_correctIndex >= 2) {
        _correctIndex = 0;
      }
    } else {
      options = _optionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fadlan geli ugu yaraan labo doorasho oo buuxa.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_correctIndex >= options.length) {
        _correctIndex = 0;
      }
    }

    final payload = {
      'subject': _subject,
      'type': _type,
      'question': questionText,
      'options': options,
      'correct_index': _correctIndex,
      'image_url': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      'prompt_emoji': _promptEmojiController.text.trim().isEmpty
          ? null
          : _promptEmojiController.text.trim(),
    };

    try {
      final result = _isEdit
          ? await SupabaseSchemaSafeWriteService.updateWithFallback(
              table: 'placement_questions',
              payload: payload,
              eqColumn: 'id',
              eqValue: widget.question!['id'],
            )
          : await SupabaseSchemaSafeWriteService.insertWithFallback(
              table: 'placement_questions',
              payload: payload,
            );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Su\'aasha si guul leh ayaa loo cusbooneysiiyay!'
                  : 'Su\'aasha si guul leh ayaa loo keydiyay!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (result.removedColumns.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "DB-ga ma hayo columns: ${result.removedColumns.join(', ')}. Su'aasha waa la keydiyay fallbacks.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final friendly = SupabaseSchemaSafeWriteService.friendlyError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cillad ayaa dhacday inta lagu guda jiray keydinta: $friendly'),
            backgroundColor: Colors.red,
          ),
        );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Wax ka beddel Su\'aasha' : 'Kudar Su\'aal Cusub',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              const Text(
                'Maadada (Subject)',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _subject,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _subject = val);
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Nooca Su\'aasha (Question Type)',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _typeLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _type = val;
                      if (_type == 'boolean' && _correctIndex >= 2) {
                        _correctIndex = 0;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Su\'aasha (Question Text)',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ku qor su\'aasha halkan...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Fadlan qor su\'aasha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              _buildPasteButton(_questionController),
              const SizedBox(height: 12),

              const Text(
                'Emoji / Astaanta Su\'aasha (Prompt Emoji - Optional)',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _promptEmojiController,
                decoration: InputDecoration(
                  hintText: 'Tusaale: 🐐 ama 🍎',
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
                'Sawirka Su\'aasha (Image URL / Upload - Optional)',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  hintText: 'http://...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _handleImageSelection,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFF1D5AFF)),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF1D5AFF)),
                  label: Text(
                    _isUploading ? 'Wuu gelaayaa (Uploading...)' : 'Dooro sawir oo geli',
                    style: const TextStyle(color: Color(0xFF1D5AFF), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_imageUrlController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrlController.text.trim(),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Ma suurtagalin in la akhriyo sawirka URL-ka ah.', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              if (_type == 'boolean') ...[
                const Text(
                  'Jawaabaha Doorashada (Options)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 8),
                const Card(
                  elevation: 0,
                  color: Color(0xFFEFF6FF),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Noocan waa Run ama Galad. Doorashooyinka waxay si otomaatig ah u noqon doonaan ["Run", "Galad"].',
                      style: TextStyle(color: Color(0xFF1D5AFF), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jawaabta saxda ah (Correct Answer)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _correctIndex = 0),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _correctIndex == 0
                                ? const Color(0xFFECFDF5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _correctIndex == 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Run',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _correctIndex == 0
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _correctIndex = 1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _correctIndex == 1
                                ? const Color(0xFFECFDF5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _correctIndex == 1
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Galad',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _correctIndex == 1
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Doorashooyinka (Options)',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                    ),
                    TextButton.icon(
                      onPressed: _addOptionField,
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1D5AFF)),
                      label: const Text('Kudar doorasho', style: TextStyle(color: Color(0xFF1D5AFF))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _optionControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _correctIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _correctIndex == index
                                    ? const Color(0xFF1D5AFF)
                                    : Colors.white,
                                border: Border.all(
                                  color: _correctIndex == index
                                      ? const Color(0xFF1D5AFF)
                                      : const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                              ),
                              child: _correctIndex == index
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _optionControllers[index],
                              decoration: InputDecoration(
                                hintText: 'Doorashada ${index + 1}',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Fadlan doorashadan ha ka tagin maran';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeOptionField(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  '* Calaamadee goobada bidixda si aad u dooratid jawaabta saxda ah.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEdit ? 'Cusbooneysii Su\'aasha' : 'Keydi Su\'aasha',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
