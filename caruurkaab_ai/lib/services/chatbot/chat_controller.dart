import 'supabase_chat_knowledge_service.dart';

class ChatController {
  final SupabaseChatKnowledgeService supabaseService;

  const ChatController({required this.supabaseService});

  Future<void> warmup() async {
    try {
      await supabaseService.getKnowledge();
    } catch (_) {
      // Warmup failure should not break chat UI.
    }
  }

  Future<String> getChatResponse(String message) async {
    final input = message.trim();
    if (input.isEmpty) return "Fadlan su'aal i soo qor.";
    const noAnswerFallback =
        "Jawaab lama helin, fadlan casharka dib u eeg ama macalinka la xiriir.";

    try {
      // 1) SUPABASE FIRST
      final supabaseAnswer = await supabaseService.querySupabaseAnswer(input);
      if (supabaseAnswer != null && supabaseAnswer.isNotEmpty) {
        return supabaseAnswer;
      }
      return noAnswerFallback;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('failed host lookup') ||
          msg.contains('network')) {
        return "Internet ma jiro ama wuu daciif yahay. $noAnswerFallback";
      }
      return "Cillad ayaa dhacday. $noAnswerFallback";
    }
  }
}
