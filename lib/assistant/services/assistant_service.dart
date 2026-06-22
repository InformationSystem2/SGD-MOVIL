import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../models/assistant_models.dart';

/// Service that manages the AI assistant chat conversation.
/// Communicates with the backend AI endpoint and maintains
/// the in-memory conversation history for the current session.
class AssistantService extends ChangeNotifier {
  final ApiClient _apiClient;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  AssistantService(this._apiClient);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Sends a user message to the AI assistant and appends the response.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message immediately
    final userMsg = ChatMessage(role: 'user', content: text.trim());
    _messages.add(userMsg);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ChatRequest(message: text.trim());
      final response = await _apiClient.post('/ai/chat', body: request.toJson());
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final assistantText = data['response'] as String? ??
          data['message'] as String? ??
          data['answer'] as String? ??
          'Sin respuesta del asistente.';

      _messages.add(ChatMessage(role: 'assistant', content: assistantText));
    } catch (e) {
      // Provide a helpful fallback when the AI service is unavailable
      _errorMessage = e.toString();
      _messages.add(ChatMessage(
        role: 'assistant',
        content:
            '⚠️ No se pudo conectar con el servicio de IA. '
            'Verifique que el servicio de IA esté activo en el servidor.\n\n'
            'Error: $e',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the conversation history for a fresh session.
  void clearConversation() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
