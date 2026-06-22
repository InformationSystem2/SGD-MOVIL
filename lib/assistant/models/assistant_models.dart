/// Represents a single message in the AI assistant conversation.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// Request body sent to the AI chat endpoint.
class ChatRequest {
  final String message;
  final String? context;

  ChatRequest({required this.message, this.context});

  Map<String, dynamic> toJson() => {
        'message': message,
        if (context != null) 'context': context,
      };
}
