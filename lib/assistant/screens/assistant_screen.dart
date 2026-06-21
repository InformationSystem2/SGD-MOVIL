// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/tenant_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/navigation_drawer.dart';
import '../../security/services/auth_service.dart';
import '../models/assistant_models.dart';
import '../services/assistant_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _typingAnimController;

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final service = Provider.of<AssistantService>(context, listen: false);
    service.sendMessage(text);
    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantService = Provider.of<TenantService>(context);

    // Plan gate enforced here too (not only in the drawer): protects against
    // direct navigation to '/assistant' from a plan that doesn't include it.
    if (!tenantService.canUseAssistant) {
      return _buildLockedScreen(context);
    }

    final assistantService = Provider.of<AssistantService>(context);
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asistente IA',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text('SGD Clínico',
                    style: TextStyle(fontSize: 11, color: AppTheme.primary)),
              ],
            ),
          ],
        ),
        actions: [
          if (assistantService.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpiar conversación',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Limpiar conversación?'),
                    content: const Text(
                        'Se eliminará todo el historial de esta sesión.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          assistantService.clearConversation();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          // User badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primary.withOpacity(0.1)
                  : AppTheme.primary50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  authService.currentUser ?? 'User',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(activeRoute: '/assistant'),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: assistantService.messages.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: assistantService.messages.length +
                        (assistantService.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Typing indicator at the end
                      if (index == assistantService.messages.length &&
                          assistantService.isLoading) {
                        return _buildTypingIndicator(isDark);
                      }
                      return _buildMessageBubble(
                          assistantService.messages[index], isDark);
                    },
                  ),
          ),

          // Input area
          _buildInputArea(isDark, assistantService.isLoading),
        ],
      ),
    );
  }

  // ── Locked state (plan does not include the AI assistant) ─────────────────

  Widget _buildLockedScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Asistente IA')),
      drawer: const NavigationDrawerWidget(activeRoute: '/assistant'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 48, color: AppTheme.warning),
              ),
              const SizedBox(height: 24),
              Text(
                'Función no disponible en tu plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El Asistente IA solo está disponible en el plan ENTERPRISE.\n'
                'Contacte a su administrador para actualizar el plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.textMutedDark
                      : AppTheme.textMutedLight,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.1),
                    AppTheme.primaryLight.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 56,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Asistente Clínico IA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pregunta sobre historias clínicas, documentos\no cualquier consulta del sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.textMutedDark
                    : AppTheme.textMutedLight,
              ),
            ),
            const SizedBox(height: 32),
            // Quick suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(
                    '📋 ¿Cuántos pacientes tenemos?', isDark),
                _buildSuggestionChip(
                    '📄 Resumen de documentos recientes', isDark),
                _buildSuggestionChip(
                    '🏥 Estado del sistema', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return ActionChip(
      label: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.primary,
        ),
      ),
      backgroundColor: isDark
          ? AppTheme.bgCardDark
          : AppTheme.primary.withOpacity(0.06),
      side: BorderSide(
        color: isDark
            ? AppTheme.borderDark
            : AppTheme.primary.withOpacity(0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _messageController.text = text.replaceAll(RegExp(r'[^\w\s¿?áéíóúñ]'), '').trim();
        _sendMessage();
      },
    );
  }

  // ── Message bubble ────────────────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assistant avatar
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primary
                    : (isDark ? AppTheme.bgCardDark : AppTheme.bgMutedLight),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight:
                      isUser ? Radius.zero : const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppTheme.borderDark
                            : AppTheme.borderLight,
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser
                          ? Colors.white
                          : (isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withOpacity(0.6)
                          : (isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryDark,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : AppTheme.bgMutedLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimController,
      builder: (_, __) {
        final offset =
            ((_typingAnimController.value * 3 - index) % 3).clamp(0.0, 1.0);
        final scale = 0.4 + 0.6 * (1 - (offset - 0.5).abs() * 2).clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // ── Input area ────────────────────────────────────────────────────────────

  Widget _buildInputArea(bool isDark, bool isLoading) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgSurfaceDark : AppTheme.bgSurfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isLoading,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: isLoading
                    ? 'Esperando respuesta...'
                    : 'Escribe tu pregunta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? AppTheme.bgCardDark : AppTheme.bgMutedLight,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: BoxDecoration(
              gradient: isLoading
                  ? null
                  : const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                    ),
              color: isLoading ? Colors.grey.shade400 : null,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
