import 'package:caruurkaab_ai/services/chatbot/chat_controller.dart';
import 'package:caruurkaab_ai/services/chatbot/supabase_chat_knowledge_service.dart';
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

  late final ChatController _chatController;

  bool _isReplying = false;
  String _typingDraft = '';

  @override
  void initState() {
    super.initState();
    _chatController = ChatController(
      supabaseService: const SupabaseChatKnowledgeService(),
    );
    _chatController.warmup();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final input = _messageController.text.trim();
    if (input.isEmpty || _isReplying) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(_ChatMessage(text: input, isUser: true));
      _isReplying = true;
      _typingDraft = 'Thinking...';
    });
    _scrollToBottom();

    final reply = await _chatController.getChatResponse(input);
    await _saveUserQuestionToInbox(question: input, response: reply);
    await _animateTypingReply(reply);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isReplying = false;
      _typingDraft = '';
    });
    _scrollToBottom();
  }

  Future<void> _saveUserQuestionToInbox({
    required String question,
    required String response,
  }) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty) return;

    try {
      final db = Supabase.instance.client;
      final user = db.auth.currentUser;
      final userId = (user?.id ?? user?.email ?? 'unknown_user').trim();
      if (userId.isEmpty) return;

      final payload = <String, dynamic>{
        'user_id': userId,
        'user_email': user?.email ?? '',
        'user_name': user?.userMetadata?['full_name']?.toString() ?? '',
        'question': cleanQuestion,
        'response': response.trim(),
        'source': 'chatbot',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      await db.from('student_question_inbox').insert(payload);
    } catch (_) {
      // Optional table: if missing, keep chatbot running.
    }
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
              'AI wuu aqrinayaa... wuu kuu qorayaa jawaabta.',
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
