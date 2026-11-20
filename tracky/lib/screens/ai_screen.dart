import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  final List<String> _suggestions = [
    'Analyze My Workout Progress',
    'What Should I Train Today?',
    'Suggest a Workout Plan',
    'How Can I Improve My Strength?',
    'Give Me Recovery Tips',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage(text: text.trim(), isUser: true);
    final assistantMessage = ChatMessage(text: '', isUser: false);

    setState(() {
      _messages.add(userMessage);
      _messages.add(assistantMessage);
      _isLoading = true;
      _error = null;
      if (text == _messageController.text) {
        _messageController.clear();
      }
    });

    _scrollToBottom();

    try {
      // Send message to AI service with current history (excluding the two we just added)
      final history = _messages.sublist(0, _messages.length - 2);
      final stream = _aiService.getChatStream(userMessage.text, history);

      bool hasStarted = false;

      await for (final chunk in stream) {
        if (!mounted) return;

        setState(() {
          if (!hasStarted) {
            hasStarted = true;
            _isLoading =
                false; // Hide typing indicator once text starts arriving
          }
          assistantMessage.text += chunk;
        });
        _scrollToBottom();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        // If it failed before any text arrived, remove the empty assistant bubble
        if (assistantMessage.text.isEmpty) {
          _messages.removeLast();
        }
      });
      _scrollToBottom();
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Conversation?'),
            content: const Text(
              'This will delete all messages in this session.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _messages.clear();
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrangeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.accentOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Tracky AI',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Your personal fitness assistant',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.textSecondary,
              ),
              onPressed: _clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildWelcomeState() : _buildChatList(),
          ),
          if (_error != null) _buildErrorBanner(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hey! 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "I'm your Tracky AI fitness assistant. I can help you understand your workout progress, recommend exercises and plan your next workout. What would you like to know?",
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'SUGGESTIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          ..._suggestions.map((s) => _buildSuggestionCard(s)),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: InkWell(
        onTap: () => _sendMessage(text),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: AppTheme.accentOrange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        // Only show typing indicator for the last message if it's AI and still empty/loading
        if (index == _messages.length - 1 &&
            !message.isUser &&
            message.text.isEmpty &&
            _isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Hide empty bubbles unless it's the one we're currently typing into (which is handled by index check in ListView)
    if (message.text.isEmpty && !message.isUser) return const SizedBox.shrink();

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color:
              message.isUser
                  ? AppTheme.accentOrangeLight
                  : AppTheme.backgroundWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 20),
          ),
          border: Border.all(
            color:
                message.isUser ? AppTheme.accentOrangeBorder : AppTheme.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: AppTheme.accentOrange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
            if (message.isUser)
              Text(
                message.text,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              )
            else
              MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                  listBullet: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  h1: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                  h2: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                  h3: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                  code: TextStyle(
                    backgroundColor: AppTheme.surfaceMuted,
                    color: AppTheme.accentOrange,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquote: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppTheme.accentOrange, width: 4),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.textMuted,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.errorRedLight,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_messages.isNotEmpty && _messages.any((m) => m.isUser)) {
                final lastUserMsg = _messages.lastWhere((m) => m.isUser);
                _sendMessage(lastUserMsg.text);
              }
            },
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              enabled: !_isLoading,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask anything about your fitness...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                fillColor: AppTheme.background,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppTheme.accentOrange,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap:
                _isLoading ? null : () => _sendMessage(_messageController.text),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _isLoading ? AppTheme.textMuted : AppTheme.accentOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
