import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_schema_safe_write_service.dart';

class AdminChapterFormScreen extends StatefulWidget {
  final Map<String, dynamic>? chapter;

  const AdminChapterFormScreen({super.key, this.chapter});

  @override
  State<AdminChapterFormScreen> createState() => _AdminChapterFormScreenState();
}

class _AdminChapterFormScreenState extends State<AdminChapterFormScreen> {
  final TextEditingController _titleController = TextEditingController();

  String? _subject;
  int? _classLevel;
  int? _courseOrder;

  bool get _isEdit => widget.chapter != null;

  @override
  void initState() {
    super.initState();
    _loadForEdit();
  }

  void _loadForEdit() {
    final chapter = widget.chapter;
    if (chapter == null) return;
    _titleController.text = (chapter['title'] ?? '').toString();
    _subject = (chapter['subject_name'] ?? _subject).toString();
    _classLevel = (chapter['class_level'] ?? _classLevel) is int
        ? (chapter['class_level'] as int)
        : int.tryParse((chapter['class_level'] ?? _classLevel).toString()) ??
              _classLevel;
    final rawOrder = chapter['course_order'];
    _courseOrder = rawOrder is int
        ? rawOrder
        : int.tryParse((rawOrder ?? 1).toString()) ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pasteTitleFromClipboard() async {
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
      _titleController.text = text;
      _titleController.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  void _saveChapter() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan gali magaca cutubka')),
      );
      return;
    }

    if (_subject == null || _subject!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fadlan dooro maadada')));
      return;
    }
    if (_classLevel == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fadlan dooro fasalka')));
      return;
    }

    final subject = _subject;
    final level = _classLevel;
    if (subject == null || level == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan dooro maadada iyo fasalka')),
      );
      return;
    }
    final subjectValue = subject;
    final levelValue = level;
    int orderToSave = _courseOrder ?? 1;
    if (!_isEdit) {
      try {
        final latest = await Supabase.instance.client
            .from('chapters')
            .select('course_order')
            .eq('subject_name', subjectValue)
            .eq('class_level', levelValue)
            .order('course_order', ascending: false)
            .limit(1)
            .maybeSingle();
        final lastOrder = latest?['course_order'];
        final lastValue = lastOrder is int
            ? lastOrder
            : int.tryParse((lastOrder ?? 0).toString()) ?? 0;
        orderToSave = lastValue + 1;
      } catch (_) {
        orderToSave = _courseOrder ?? 1;
      }
    }

    final payload = {
      'title': _titleController.text.trim(),
      'subject_name': _subject,
      'class_level': _classLevel,
      'course_order': orderToSave,
    };

    try {
      final result = _isEdit
          ? await SupabaseSchemaSafeWriteService.updateWithFallback(
              table: 'chapters',
              payload: payload,
              eqColumn: 'id',
              eqValue: widget.chapter!['id'],
            )
          : await SupabaseSchemaSafeWriteService.insertWithFallback(
              table: 'chapters',
              payload: payload,
            );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Cutubka waa la cusbooneysiiyay!'
                  : 'Cutubka waa la keydiyay!',
            ),
          ),
        );
        if (result.removedColumns.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "DB-ga wali ma hayo columns: ${result.removedColumns.join(', ')}. Cutubka waa la keydiyay.",
              ),
            ),
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final friendly = SupabaseSchemaSafeWriteService.friendlyError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cilad ayaa dhacday: $friendly')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Cutub' : 'Abuur Cutub Cusub',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Magaca Cutubka',
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
              hintText: 'Tusaale: Cutubka 1: Barashada Xarfaha',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Paste helper for long titles (copy/paste).
          TextButton.icon(
            onPressed: _pasteTitleFromClipboard,
            icon: const Icon(Icons.paste),
            label: const Text('Paste'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Maadada (Category)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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
            hint: const Text('Dooro maadada'),
            items: const [
              DropdownMenuItem(
                value: 'Af Soomaali',
                child: Text('Af Soomaali'),
              ),
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Xisaab', child: Text('Xisaab')),
              DropdownMenuItem(value: 'Saynis', child: Text('Saynis')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _subject = val);
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Fasalka (Class Level)',
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
            hint: const Text('Dooro fasalka'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Fasalka 1')),
              DropdownMenuItem(value: 2, child: Text('Fasalka 2')),
              DropdownMenuItem(value: 3, child: Text('Fasalka 3')),
              DropdownMenuItem(value: 4, child: Text('Fasalka 4')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _classLevel = val);
            },
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saveChapter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEdit ? 'Update Cutubka' : 'Keydi Cutubka',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
