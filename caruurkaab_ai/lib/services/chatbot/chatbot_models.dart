class ChatKnowledgeChunk {
  final String source;
  final String title;
  final String subject;
  final String classLevel;
  final String body;

  const ChatKnowledgeChunk({
    required this.source,
    required this.title,
    required this.subject,
    required this.classLevel,
    required this.body,
  });
}

class ChatQaItem {
  final String question;
  final String answer;
  final String source;
  final String title;
  final String subject;
  final String classLevel;

  const ChatQaItem({
    required this.question,
    required this.answer,
    required this.source,
    required this.title,
    required this.subject,
    required this.classLevel,
  });
}

class ChatKnowledgeBundle {
  final List<ChatKnowledgeChunk> chunks;
  final List<ChatQaItem> qaItems;

  const ChatKnowledgeBundle({required this.chunks, required this.qaItems});
}
