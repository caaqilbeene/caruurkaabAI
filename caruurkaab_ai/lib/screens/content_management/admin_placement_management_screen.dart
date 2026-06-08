import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_placement_form_screen.dart';

class AdminPlacementManagementScreen extends StatefulWidget {
  const AdminPlacementManagementScreen({super.key});

  @override
  State<AdminPlacementManagementScreen> createState() =>
      _AdminPlacementManagementScreenState();
}

class _AdminPlacementManagementScreenState
    extends State<AdminPlacementManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await Supabase.instance.client
          .from('placement_questions')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _questions = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _questions = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cillad ayaa ku dhacday soo dejinta su\'aalaha: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'seynis':
        return const Color(0xFF10B981); // Green
      case 'xisaab':
        return const Color(0xFFF59E0B); // Orange
      case 'af-soomaali':
      case 'afsoomaali':
        return const Color(0xFF6366F1); // Indigo
      case 'english':
        return const Color(0xFF1D5AFF); // Blue
      default:
        return const Color(0xFF64748B); // Slate/Grey
    }
  }

  List<Map<String, dynamic>> get _filteredQuestions {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _questions;
    return _questions.where((item) {
      final q = (item['question'] ?? '').toString().toLowerCase();
      final sub = (item['subject'] ?? '').toString().toLowerCase();
      final type = (item['type'] ?? '').toString().toLowerCase();
      return q.contains(query) || sub.contains(query) || type.contains(query);
    }).toList();
  }

  Future<void> _deleteQuestion(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Tirtir Su\'aasha',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: const Text(
            'Ma hubtaa inaad si joogto ah u tirtirayso su\'aashan placement-ka ah?',
            style: TextStyle(color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Burki (Cancel)', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Tirtir (Delete)'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('placement_questions')
          .delete()
          .eq('id', item['id']);

      if (!mounted) return;
      setState(() {
        _questions.removeWhere((q) => q['id'] == item['id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Su\'aashii si guul leh ayaa loo tirtiray.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Waa uu guuldarraystay tirtirku: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredQuestions;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Placement Questions',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1D5AFF)),
            onPressed: _loadQuestions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Raadi su\'aalaha...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D5AFF)))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              const Text(
                                "Wax su'aalo ah laguma darin.",
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final questionText = (item['question'] ?? '').toString();
                            final subject = (item['subject'] ?? 'Kale').toString();
                            final type = (item['type'] ?? 'mcq').toString().toUpperCase();
                            final options = List<dynamic>.from(item['options'] ?? []);
                            final imageUrl = item['image_url'] as String?;
                            final promptEmoji = item['prompt_emoji'] as String?;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getSubjectColor(subject).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          subject,
                                          style: TextStyle(
                                            color: _getSubjectColor(subject),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          type,
                                          style: const TextStyle(
                                            color: Color(0xFF1D5AFF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          final updated = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AdminPlacementFormScreen(
                                                question: Map<String, dynamic>.from(item),
                                              ),
                                            ),
                                          );
                                          if (updated == true) {
                                            _loadQuestions();
                                          }
                                        },
                                        icon: const Icon(Icons.edit, color: Color(0xFF4B5563), size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _deleteQuestion(item),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 100,
                                          color: Colors.grey[100],
                                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (promptEmoji != null && promptEmoji.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Emoji: $promptEmoji',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    questionText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...List.generate(options.length, (optIdx) {
                                    final isCorrect = optIdx == item['correct_index'];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isCorrect ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isCorrect ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                            size: 16,
                                            color: isCorrect ? const Color(0xFF10B981) : Colors.grey[400],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              options[optIdx].toString(),
                                              style: TextStyle(
                                                color: isCorrect ? const Color(0xFF065F46) : const Color(0xFF475569),
                                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D5AFF),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPlacementFormScreen()),
          );
          if (created == true) {
            _loadQuestions();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
