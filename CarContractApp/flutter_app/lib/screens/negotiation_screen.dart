import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../animations/animations.dart';

class NegotiationScreen extends StatefulWidget {
  final String? contractId;
  const NegotiationScreen({super.key, this.contractId});

  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Welcome message
    _messages.add({
      'role': 'assistant',
      'content':
          'Hello! I\'m your AI negotiation assistant. I can help you:\n\n• Understand your contract terms\n• Prepare negotiation points\n• Draft messages to dealers\n\nHow can I help you today?',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await ApiService.sendNegotiationMessage(
        message: text,
        history: _messages,
        context: widget.contractId != null
            ? {'contractId': widget.contractId}
            : null,
      );

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response['response'] ?? 'I couldn\'t process that.',
        });
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error. Please try again.',
        });
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index], index);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),

          // Scroll-reactive Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScrollReactiveGlassHeader(
              scrollController: _scrollController,
              height: 90,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: AppTheme.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'AI Negotiation',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Invisible icon for balance
                      const Opacity(
                        opacity: 0,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          onPressed: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message, int index) {
    final isUser = message['role'] == 'user';

    // Animate new messages
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 50),
      slideFrom: const Offset(0, 20),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: isUser ? AppTheme.accentGreen : AppTheme.glassBg,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: isUser ? const Radius.circular(4) : null,
              bottomLeft: !isUser ? const Radius.circular(4) : null,
            ),
            border: isUser ? null : Border.all(color: AppTheme.glassBorder),
            boxShadow: isUser
                ? [
                    BoxShadow(
                      color: AppTheme.accentGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.glassBg,
          borderRadius: BorderRadius.circular(
            20,
          ).copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [_buildDot(0), _buildDot(1), _buildDot(2)],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final val =
            1.0 + (0.5 * ((_typingController.value + (index * 0.33)) % 1.0));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          transform: Matrix4.translationValues(0, -3 * (val - 1.0), 0),
          decoration: BoxDecoration(
            color: AppTheme.textMuted.withOpacity(0.5 * val),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background.withOpacity(0.8),
            border: Border(top: BorderSide(color: AppTheme.glassBorder)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your contract...',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GlowRippleButton(
                  onTap: _sendMessage,
                  glowColor: AppTheme.accentGreen,
                  borderRadius: 50,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
