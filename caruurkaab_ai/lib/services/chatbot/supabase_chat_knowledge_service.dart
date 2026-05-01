import 'package:supabase_flutter/supabase_flutter.dart';

import 'chatbot_models.dart';

class SupabaseChatKnowledgeService {
  const SupabaseChatKnowledgeService();

  static ChatKnowledgeBundle? _cachedBundle;
  static DateTime? _lastSyncAt;
  static const Duration _cacheTtl = Duration(minutes: 3);

  Future<ChatKnowledgeBundle> getKnowledge({bool forceRefresh = false}) async {
    final isFresh =
        _cachedBundle != null &&
        _lastSyncAt != null &&
        DateTime.now().difference(_lastSyncAt!) <= _cacheTtl;
    if (!forceRefresh && isFresh) return _cachedBundle!;

    final loaded = await loadKnowledge();
    _cachedBundle = loaded;
    _lastSyncAt = DateTime.now();
    return loaded;
  }

  Future<String?> querySupabaseAnswer(String message) async {
    final q = _normalize(message);
    if (q.isEmpty) return null;

    final bundle = await getKnowledge();
    final qa = bundle.qaItems;
    if (qa.isEmpty) return null;

    final qTokens = _tokenizeForMatch(message);
    ChatQaItem? best;
    var bestScore = 0;

    for (final item in qa) {
      final qn = _normalize(item.question);
      if (qn.isEmpty) continue;
      if (_isAmbiguousChoiceLabel(item.answer)) continue;

      var score = 0;
      if (qn == q) score += 120;
      if (qn.contains(q)) score += 40;
      if (q.contains(qn)) score += 30;

      final itemTokens = _tokenizeForMatch(item.question);
      for (final t in qTokens) {
        if (itemTokens.contains(t)) score += 8;
      }

      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    if (best != null && bestScore >= 14) {
      return best.answer.trim();
    }
    return null;
  }

  Future<String> buildSupabaseContext(String message, {int limit = 5}) async {
    final bundle = await getKnowledge();
    final scored = <_ScoredChunk>[];
    final q = _normalize(message);
    final tokens = _tokenizeForMatch(message);

    for (final chunk in bundle.chunks) {
      final searchable = _normalize(
        '${chunk.title} ${chunk.subject} ${chunk.classLevel} ${chunk.body}',
      );

      var score = 0;
      if (searchable.contains(q)) score += 20;
      for (final t in tokens) {
        if (searchable.contains(t)) score += 5;
      }
      if (score > 0) {
        scored.add(_ScoredChunk(chunk: chunk, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(limit).toList();
    if (top.isEmpty) return '';

    final b = StringBuffer();
    for (var i = 0; i < top.length; i++) {
      final c = top[i].chunk;
      b.writeln(
        'XOG ${i + 1}: ${c.title} | ${c.subject} | Fasal ${c.classLevel}',
      );
      b.writeln(c.body);
      b.writeln('---');
    }
    return b.toString().trim();
  }

  Future<ChatKnowledgeBundle> loadKnowledge() async {
    final db = Supabase.instance.client;
    final chunks = <ChatKnowledgeChunk>[];
    final qaItems = <ChatQaItem>[];

    qaItems.addAll(_buildPlacementQaSeed());

    Future<void> safeRun(Future<void> Function() task) async {
      try {
        await task();
      } catch (_) {
        // Ignore optional tables/policies errors so chatbot keeps working.
      }
    }

    await safeRun(() async {
      final rows = await db
          .from('lessons')
          .select('id,title,desc,subject_name,class_level,chapter_id,items');

      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);

        final title = (map['title'] ?? 'Cashar').toString().trim();
        final desc = (map['desc'] ?? '').toString().trim();
        final subject = (map['subject_name'] ?? '').toString().trim();
        final classLevel = (map['class_level'] ?? '').toString().trim();

        final parts = <String>[];
        if (desc.isNotEmpty) parts.add(desc);

        final items = map['items'];
        if (items is List) {
          for (final raw in items) {
            if (raw is! Map) continue;
            final item = Map<String, dynamic>.from(raw);
            final text = (item['text'] ?? '').toString().trim();
            final caption = (item['caption'] ?? '').toString().trim();
            final question = (item['question'] ?? '').toString().trim();
            if (text.isNotEmpty) parts.add(text);
            if (caption.isNotEmpty) parts.add(caption);
            if (question.isNotEmpty) parts.add("Su'aal: $question");
          }
        }

        final body = parts.join('\n');
        if (body.trim().isNotEmpty) {
          chunks.add(
            ChatKnowledgeChunk(
              source: 'lesson',
              title: title,
              subject: subject,
              classLevel: classLevel,
              body: body,
            ),
          );
        }

        if (items is List) {
          for (final raw in items) {
            if (raw is! Map) continue;
            final item = Map<String, dynamic>.from(raw);
            final question = (item['question'] ?? '').toString().trim();
            final answer = _sanitizeAnswerText(
              (item['answer'] ?? item['correct_answer'] ?? '').toString(),
            );
            if (question.isEmpty || answer == null) continue;
            qaItems.add(
              ChatQaItem(
                question: question,
                answer: answer,
                source: 'lesson',
                title: title,
                subject: subject,
                classLevel: classLevel,
              ),
            );
          }
        }
      }
    });

    await safeRun(() async {
      final rows = await db
          .from('quizzes')
          .select(
            'id,title,subject_name,class_level,chapter_id,lesson_id,questions',
          );

      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final title = (map['title'] ?? 'Quiz').toString().trim();
        final subject = (map['subject_name'] ?? '').toString().trim();
        final classLevel = (map['class_level'] ?? '').toString().trim();
        final questions = map['questions'];

        if (questions is! List) continue;

        for (final raw in questions) {
          if (raw is! Map) continue;
          final q = Map<String, dynamic>.from(raw);
          final qText = (q['question'] ?? q['text'] ?? '').toString().trim();
          if (qText.isEmpty) continue;

          final options = q['options'];
          final answer = _extractQuizAnswer(q);

          final parts = <String>["Su'aal: $qText"];
          if (options is List && options.isNotEmpty) {
            parts.add(
              "Options: ${options.map((e) => e.toString()).join(', ')}",
            );
          }
          if (answer != null && answer.trim().isNotEmpty) {
            parts.add("Jawaab: ${answer.trim()}");
            qaItems.add(
              ChatQaItem(
                question: qText,
                answer: answer.trim(),
                source: 'quiz',
                title: title,
                subject: subject,
                classLevel: classLevel,
              ),
            );
          }

          chunks.add(
            ChatKnowledgeChunk(
              source: 'quiz',
              title: title,
              subject: subject,
              classLevel: classLevel,
              body: parts.join('\n'),
            ),
          );
        }
      }
    });

    await safeRun(() async {
      final rows = await db.from('questions').select();
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final question =
            (map['question'] ??
                    map['text'] ??
                    map['title'] ??
                    map['prompt'] ??
                    '')
                .toString()
                .trim();
        if (question.isEmpty) continue;

        final answer = _sanitizeAnswerText(
          (map['answer'] ??
                  map['correct_answer'] ??
                  map['correctAnswer'] ??
                  map['solution'] ??
                  '')
              .toString(),
        );

        final parts = <String>["Su'aal: $question"];
        if (answer != null && answer.isNotEmpty) {
          parts.add("Jawaab: $answer");
          qaItems.add(
            ChatQaItem(
              question: question,
              answer: answer,
              source: 'question',
              title: 'Question Bank',
              subject: (map['subject_name'] ?? map['subject'] ?? '').toString(),
              classLevel: (map['class_level'] ?? '').toString(),
            ),
          );
        }

        chunks.add(
          ChatKnowledgeChunk(
            source: 'question',
            title: 'Question Bank',
            subject: (map['subject_name'] ?? map['subject'] ?? '').toString(),
            classLevel: (map['class_level'] ?? '').toString(),
            body: parts.join('\n'),
          ),
        );
      }
    });

    return ChatKnowledgeBundle(chunks: chunks, qaItems: qaItems);
  }

  String? _extractQuizAnswer(Map<String, dynamic> q) {
    final optionsRaw = q['options'];
    final options = optionsRaw is List
        ? optionsRaw.map((e) => e.toString().trim()).toList()
        : <String>[];

    final direct = (q['answer'] ?? q['correctAnswer'] ?? q['correct'] ?? '')
        .toString()
        .trim();
    if (direct.isNotEmpty) {
      final labelIndex = _choiceLabelToIndex(direct);
      if (labelIndex != null &&
          labelIndex >= 0 &&
          labelIndex < options.length &&
          options[labelIndex].isNotEmpty) {
        return options[labelIndex];
      }

      final stripped = direct
          .replaceFirst(RegExp(r'^[A-Da-d]\s*[\)\.\-:\s]+'), '')
          .trim();
      if (stripped.isNotEmpty &&
          stripped.toLowerCase() != direct.toLowerCase()) {
        return stripped;
      }

      if (_isAmbiguousChoiceLabel(direct)) return null;
      return direct;
    }

    if (options.isEmpty) return null;

    final idxRaw = q['correctIndex'];
    final idx = idxRaw is int ? idxRaw : int.tryParse('$idxRaw');
    if (idx == null || idx < 0 || idx >= options.length) return null;
    final answer = options[idx].trim();
    return answer.isEmpty ? null : answer;
  }

  int? _choiceLabelToIndex(String raw) {
    final v = raw.trim().toUpperCase();
    if (v.isEmpty) return null;
    final first = v[0];
    if (first.codeUnitAt(0) >= 65 && first.codeUnitAt(0) <= 68) {
      return first.codeUnitAt(0) - 65;
    }
    final n = int.tryParse(first);
    if (n == null) return null;
    if (n >= 1 && n <= 9) return n - 1;
    return null;
  }

  bool _isAmbiguousChoiceLabel(String value) {
    final v = value.trim();
    if (v.isEmpty) return true;
    if (RegExp(r'^[A-Da-d]$').hasMatch(v)) return true;
    if (RegExp(r'^[A-Da-d]\s*[\)\.\-:]$').hasMatch(v)) return true;
    if (RegExp(r'^[1-9]$').hasMatch(v)) return true;
    return false;
  }

  String? _sanitizeAnswerText(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final stripped = clean
        .replaceFirst(RegExp(r'^[A-Da-d]\s*[\)\.\-:\s]+'), '')
        .trim();
    final candidate = stripped.isNotEmpty ? stripped : clean;
    if (_isAmbiguousChoiceLabel(candidate)) return null;
    return candidate;
  }

  List<ChatQaItem> _buildPlacementQaSeed() {
    const seed = <Map<String, String>>[
      {'q': 'Soomaaliya waxay xorriyadda qaadatay?', 'a': '1960'},
      {'q': 'Soomaaliya waxay xorowday 1960.', 'a': 'Run'},
      {
        'q': 'Madaxweynihii ugu horreeyay ee Soomaaliya waa?',
        'a': 'Aadan Cabdulle Cismaan (Aden Abdullah Osman Daar)',
      },
      {
        'q': 'Madaxweynehii ugu horeeyay ee soomaaliya yuu ahaa?',
        'a': 'Aadan Cabdulle Cismaan (Aden Abdullah Osman Daar)',
      },
      {'q': 'Caasimadda Soomaaliya waa?', 'a': 'Muqdisho'},
      {'q': 'Wabiga ugu dheer Soomaaliya waa kee?', 'a': 'Shabeelle'},
      {'q': 'Lacagta Soomaaliya waa?', 'a': 'Shilin Soomaali'},
      {'q': '4 + 4 = ?', 'a': '8'},
      {'q': '7 + 3 = ?', 'a': '10'},
      {'q': '10 - 4 = ?', 'a': '6'},
      {'q': '15 + 5 = ?', 'a': '20'},
      {'q': 'Qalabka wax lagu qoro waa?', 'a': 'Qalin'},
      {'q': 'Bisha Ramadaan ka dib waxaa yimaada?', 'a': 'Ciidul Fidr'},
      {
        'q': 'Magaalada Kismaayo waxay ku taallaa gobolka?',
        'a': 'Jubbada Hoose',
      },
    ];

    return seed
        .map(
          (item) => ChatQaItem(
            question: item['q']!,
            answer: item['a']!,
            source: 'placement',
            title: 'Placement',
            subject: 'Placement',
            classLevel: 'Placement',
          ),
        )
        .toList(growable: false);
  }

  Set<String> _tokenizeForMatch(String value) {
    final raw = _normalize(value).split(' ');
    return raw.where((e) => e.length >= 2).toSet();
  }

  String _normalize(String v) {
    return v
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ScoredChunk {
  final ChatKnowledgeChunk chunk;
  final int score;

  const _ScoredChunk({required this.chunk, required this.score});
}
