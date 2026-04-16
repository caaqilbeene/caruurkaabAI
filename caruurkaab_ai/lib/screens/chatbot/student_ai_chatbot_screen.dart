import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAiChatbotScreen extends StatefulWidget {
  const StudentAiChatbotScreen({super.key});

  @override
  State<StudentAiChatbotScreen> createState() => _StudentAiChatbotScreenState();
}

class _StudentAiChatbotScreenState extends State<StudentAiChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  final List<_KnowledgeChunk> _knowledge = [];

  bool _isReplying = false;
  String _typingDraft = '';

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        text:
            "Salaan! Waxaan ahay Chatbot-kaaga waxbarasho.\n\n"
            "I waydii su'aal kasta oo la xiriirta casharradaada, waan kaa caawinayaa.",
        isUser: false,
      ),
    );
    _loadKnowledgeBase();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadKnowledgeBase() async {
    final db = Supabase.instance.client;
    final collected = <_KnowledgeChunk>[];

    Future<void> safeRun(Future<void> Function() task) async {
      try {
        await task();
      } catch (_) {
        // Table ama permissions error ha joojin chatbot-ka.
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
            if (question.isNotEmpty) parts.add(question);
          }
        }

        final body = parts.join('\n');
        if (body.trim().isEmpty) continue;

        collected.add(
          _KnowledgeChunk(
            source: 'lesson',
            title: title,
            subject: subject,
            classLevel: classLevel,
            body: body,
          ),
        );
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

        final parts = <String>[];
        if (questions is List) {
          for (final raw in questions) {
            if (raw is! Map) continue;
            final q = Map<String, dynamic>.from(raw);
            final qText = (q['question'] ?? q['text'] ?? '').toString().trim();
            final options = q['options'];
            final answer = q['answer'] ?? q['correctAnswer'] ?? q['correct'];
            if (qText.isNotEmpty) parts.add("Q: $qText");
            if (options is List && options.isNotEmpty) {
              parts.add(
                "Options: ${options.map((e) => e.toString()).join(', ')}",
              );
            }
            if (answer != null && answer.toString().trim().isNotEmpty) {
              parts.add("Answer: ${answer.toString().trim()}");
            }
          }
        }

        if (parts.isEmpty) continue;
        collected.add(
          _KnowledgeChunk(
            source: 'quiz',
            title: title,
            subject: subject,
            classLevel: classLevel,
            body: parts.join('\n'),
          ),
        );
      }
    });

    await safeRun(() async {
      final rows = await db.from('questions').select();
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final text =
            (map['question'] ??
                    map['text'] ??
                    map['title'] ??
                    map['prompt'] ??
                    '')
                .toString()
                .trim();
        if (text.isEmpty) continue;
        collected.add(
          _KnowledgeChunk(
            source: 'question',
            title: 'Question Bank',
            subject: (map['subject_name'] ?? map['subject'] ?? '').toString(),
            classLevel: (map['class_level'] ?? '').toString(),
            body: text,
          ),
        );
      }
    });

    await safeRun(() async {
      final rows = await db.from('answers').select();
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final text =
            (map['answer'] ??
                    map['text'] ??
                    map['answer_text'] ??
                    map['content'] ??
                    '')
                .toString()
                .trim();
        if (text.isEmpty) continue;
        collected.add(
          _KnowledgeChunk(
            source: 'answer',
            title: 'Answer Bank',
            subject: (map['subject_name'] ?? map['subject'] ?? '').toString(),
            classLevel: (map['class_level'] ?? '').toString(),
            body: text,
          ),
        );
      }
    });

    // Placement su'aalaha (app-ka dhexdiisa) sidoo kale ku dar chatbot knowledge.
    collected.addAll(_buildPlacementKnowledgeChunks());

    if (!mounted) return;
    setState(() {
      _knowledge
        ..clear()
        ..addAll(collected);
    });
  }

  Future<void> _sendMessage() async {
    final input = _messageController.text.trim();
    if (input.isEmpty || _isReplying) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(_ChatMessage(text: input, isUser: true));
      _isReplying = true;
      _typingDraft = '';
    });
    _scrollToBottom();

    final reply = await _buildReply(input);
    await Future.delayed(const Duration(milliseconds: 900));
    await _animateTypingReply(reply);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isReplying = false;
      _typingDraft = '';
    });
    _scrollToBottom();
  }

  Future<void> _animateTypingReply(String reply) async {
    if (reply.trim().isEmpty) return;
    var i = 0;
    const step = 3;
    while (i < reply.length && mounted) {
      i = (i + step).clamp(0, reply.length);
      setState(() {
        _typingDraft = reply.substring(0, i);
      });
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 14));
    }
  }

  Future<String> _buildReply(String input) async {
    final q = input.toLowerCase().trim();
    if (q.isEmpty) return "Fadlan su'aal i soo qor.";

    if (_knowledge.isEmpty) {
      return "Weli xog casharro kama helin Supabase. Hubi in lessons/quizzes/questions/answers ay xog ku jiraan.";
    }

    if (q == 'salaan' || q == 'asc' || q.contains('hello')) {
      return "Wcs! I waydii su'aal la xiriirta casharrada, quiz-yada, ama jawaabaha ku jira database-ka.";
    }

    final matches = _findBestMatches(q, limit: 1);
    if (matches.isEmpty) {
      return "Su'aashan xog toos ah ugama helin casharrada hadda. Isku day ereyo kale sida magaca maadada, cutubka, ama su'aasha saxda ah.";
    }

    final chunk = matches.first.chunk;
    final details = _extractRelevantDetails(chunk: chunk, query: q);
    return details;
  }

  List<_ScoredChunk> _findBestMatches(String query, {int limit = 1}) {
    final normalizedQuery = _normalize(query);
    final tokens = normalizedQuery
        .split(' ')
        .where((e) => e.trim().length >= 2)
        .toSet();

    final scored = <_ScoredChunk>[];

    for (final chunk in _knowledge) {
      final searchable = chunk.searchable;
      var score = 0;

      if (searchable.contains(normalizedQuery)) {
        score += 20;
      }

      for (final token in tokens) {
        if (searchable.contains(token)) score += 4;
        if (chunk.titleNormalized.contains(token)) score += 5;
        if (chunk.subjectNormalized.contains(token)) score += 2;
      }

      // Fudud: su'aalaha gaagaaban ha helaan bonus haddii title la mid noqdo.
      if (tokens.length <= 3 &&
          chunk.titleNormalized.contains(normalizedQuery)) {
        score += 25;
      }

      // Haddii title-ku sax ugu jiro query-ga, si xooggan u mudnee.
      if (normalizedQuery.length > 5 &&
          (normalizedQuery.contains(chunk.titleNormalized) ||
              chunk.titleNormalized.contains(normalizedQuery))) {
        score += 40;
      }

      if (score > 0) {
        scored.add(_ScoredChunk(chunk: chunk, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(max(1, limit)).toList();
  }

  String _extractRelevantDetails({
    required _KnowledgeChunk chunk,
    required String query,
  }) {
    final source = switch (chunk.source) {
      'lesson' => 'Cashar',
      'quiz' => 'Quiz',
      'question' => 'Question',
      'answer' => 'Answer',
      'placement' => 'Placement',
      _ => chunk.source,
    };

    // Quiz: isku day in aan keenno hal Q/A oo query-ga ugu dhow.
    if (chunk.source == 'quiz') {
      final qa = _extractBestQuizQa(chunk.body, query);
      if (qa != null) {
        return "${chunk.title}\n\n${qa.$1}\n${qa.$2}";
      }
    }

    final focused = _extractMatchingSnippet(chunk.body, query, maxChars: 420);
    final infoParts = <String>[];
    if (chunk.subject.trim().isNotEmpty) infoParts.add(chunk.subject.trim());
    if (chunk.classLevel.trim().isNotEmpty) {
      infoParts.add("Fasalka ${chunk.classLevel.trim()}");
    }
    infoParts.add(source);

    return "${chunk.title}\n\n$focused\n\n[${infoParts.join(' • ')}]";
  }

  (String, String)? _extractBestQuizQa(String body, String query) {
    final lines = body.split('\n');
    final qNorm = _normalize(query);
    final tokens = qNorm.split(' ').where((e) => e.length >= 2).toList();

    var bestQuestion = '';
    var bestAnswer = '';
    var bestScore = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('Q:')) continue;
      final qLine = line.replaceFirst('Q:', '').trim();
      var score = 0;
      final qLineNorm = _normalize(qLine);

      if (qLineNorm.contains(qNorm)) score += 20;
      for (final token in tokens) {
        if (qLineNorm.contains(token)) score += 3;
      }

      String answerLine = '';
      for (var j = i + 1; j < min(i + 5, lines.length); j++) {
        final next = lines[j].trim();
        if (next.startsWith('Answer:')) {
          answerLine = next;
          break;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestQuestion = "Su'aasha: $qLine";
        bestAnswer = answerLine.isEmpty
            ? ''
            : "Jawaabta: ${answerLine.replaceFirst('Answer:', '').trim()}";
      }
    }

    if (bestScore <= 0 || bestQuestion.isEmpty) return null;
    if (bestAnswer.isEmpty) {
      return (bestQuestion, "Jawaabta saxda ah quiz-kan ma muuqan.");
    }
    return (bestQuestion, bestAnswer);
  }

  String _extractMatchingSnippet(
    String body,
    String query, {
    int maxChars = 420,
  }) {
    final lines = body
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return _shorten(body, maxChars);

    final queryNorm = _normalize(query);
    final tokens = queryNorm.split(' ').where((e) => e.length >= 2).toList();

    var bestLine = lines.first;
    var bestScore = -1;
    for (final line in lines) {
      var score = 0;
      final n = _normalize(line);
      if (n.contains(queryNorm)) score += 12;
      for (final token in tokens) {
        if (n.contains(token)) score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        bestLine = line;
      }
    }

    return _shorten(bestLine, maxChars);
  }

  List<_KnowledgeChunk> _buildPlacementKnowledgeChunks() {
    final placement = <Map<String, String>>[
      {
        'q': 'Soomaaliya waxay xorriyadda qaadatay?',
        'a': '1960',
        'd': 'Soomaaliya waxay xornimada qaadatay 1-da Luulyo 1960.',
      },
      {
        'q': 'Madaxweynihii ugu horreeyay ee Soomaaliya waa?',
        'a': 'Aden Abdullah Osman Daar',
        'd':
            'Aaden Cabdulle Cismaan (Aden Adde) wuxuu ahaa madaxweynihii ugu horreeyay.',
      },
      {
        'q': 'Dagaalkii 1aad ee Adduunka wuxuu billowday sanadkee?',
        'a': '1914',
        'd': 'Dagaalkii Koowaad ee Adduunka wuxuu bilowday 1914.',
      },
      {
        'q': 'Wabiga ugu dheer Soomaaliya waa kee?',
        'a': 'Shabeelle',
        'd': 'Webiga Shabeelle waa webiga ugu dheer ee mara Soomaaliya.',
      },
      {
        'q': 'Yaa gumeysan jiray koonfurta Soomaaliya?',
        'a': 'Italy',
        'd': 'Koonfurta Soomaaliya waxaa gumeysan jiray Talyaaniga.',
      },
      {
        'q': 'Dagaalkii Ogaden War wuxuu dhacay sanadkee?',
        'a': '1977',
        'd': 'Dagaalkii Ogaadeen wuxuu si weyn u dhacay 1977.',
      },
      {
        'q': 'Qorraxdu subaxdii halkee ayay ka soo baxdaa?',
        'a': 'Bariga',
        'd': 'Qorraxdu waxay ka soo baxdaa bari, waxayna u dhacdaa galbeed.',
      },
      {
        'q': 'Caasimadda Soomaaliya waa?',
        'a': 'Muqdisho',
        'd': 'Muqdisho waa caasimadda Jamhuuriyadda Federaalka Soomaaliya.',
      },
      {
        'q': 'Lacagta Soomaaliya waa?',
        'a': 'Shilin Soomaali',
        'd': 'Lacagta rasmiga ah waa Shilin Soomaali.',
      },
      {
        'q': 'Soomaaliya waxay ku taallaa?',
        'a': 'Geeska Afrika',
        'd': 'Soomaaliya waxay ku taallaa Geeska Afrika.',
      },
      {
        'q': 'Afka rasmiga ah ee ugu weyn Soomaaliya waa?',
        'a': 'Af-Soomaali',
        'd': 'Af-Soomaali waa afka rasmiga ah ee ugu weyn dalka.',
      },
      {
        'q': 'Sannadka calanka Soomaaliya la sameeyay waa?',
        'a': '1954',
        'd': 'Calanka Soomaaliya waxaa la sameeyay 1954.',
      },
      {
        'q': '4 + 4 = ?',
        'a': '8',
        'd': 'Marka 4 iyo 4 la isku daro waxay noqdaan 8.',
      },
      {'q': '7 + 3 = ?', 'a': '10', 'd': '7 iyo 3 markaad isku darto waa 10.'},
      {
        'q': '9 - 4 = ?',
        'a': '5',
        'd': '9 markaad ka jarto 4 waxaa soo haraya 5.',
      },
    ];

    return placement
        .map(
          (e) => _KnowledgeChunk(
            source: 'placement',
            title: 'Placement Question',
            subject: 'Placement',
            classLevel: '',
            body: "Su'aal: ${e['q']}\nJawaab: ${e['a']}\nSharaxaad: ${e['d']}",
          ),
        )
        .toList();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _shorten(String text, int length) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= length) return clean;
    return "${clean.substring(0, length)}...";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _messages.length + (_isReplying ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isReplying && index == _messages.length) {
                if (_typingDraft.isNotEmpty) {
                  return _ChatBubble(
                    message: _ChatMessage(text: _typingDraft, isUser: false),
                  );
                }
                return const _TypingBubble();
              }
              final message = _messages[index];
              return _ChatBubble(message: message);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: "Su'aal i waydii...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF1D5AFF)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: const Color(0xFF1D5AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1D5AFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUser ? const Color(0xFF1D5AFF) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              "AI wuu aqrinayaa... wuu kuu qorayaa jawaabta.",
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _KnowledgeChunk {
  final String source;
  final String title;
  final String subject;
  final String classLevel;
  final String body;

  const _KnowledgeChunk({
    required this.source,
    required this.title,
    required this.subject,
    required this.classLevel,
    required this.body,
  });

  String get searchable {
    return _normalize("$title $subject $classLevel $body");
  }

  String get titleNormalized => _normalize(title);
  String get subjectNormalized => _normalize(subject);

  String _normalize(String v) {
    return v
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ScoredChunk {
  final _KnowledgeChunk chunk;
  final int score;

  const _ScoredChunk({required this.chunk, required this.score});
}
