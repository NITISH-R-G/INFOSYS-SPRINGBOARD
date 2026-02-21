import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../animations/animations.dart';

class DealerChatScreen extends StatefulWidget {
  final String? contractId;
  const DealerChatScreen({super.key, this.contractId});

  @override
  State<DealerChatScreen> createState() => _DealerChatScreenState();
}

class _DealerChatScreenState extends State<DealerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mocking the thread data
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'dealer',
      'id': 'dealer-123',
      'content':
          'Hello, thanks for reviewing the latest lease offer. Let me know if you have any questions regarding the terms or pricing.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'role': 'user',
      'id': 'user-456',
      'content':
          'I noticed a \$500 disposition fee. I assume this is standard, but considering my credit score, could we waive it?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
    },
    {
      'role': 'dealer',
      'id': 'dealer-123',
      'content':
          'The disposition fee is standard across all our regional leases, unfortunately. However, I can lower the capitalized cost by \$300 to help offset it. Does that work for you?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'id': 'user-456',
        'content': text,
        'timestamp': DateTime.now(),
      });
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate dealer typing and responding
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'dealer',
          'id': 'dealer-123',
          'content':
              'I understand. Let me review that request with my sales manager and I will get back to you shortly.',
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
    });
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
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Dealer Thread',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'City Auto Group',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
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

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isUser = message['role'] == 'user';
    final timestamp = DateFormat(
      'h:mm a',
    ).format(message['timestamp'] as DateTime);

    return AnimatedEntrance(
      delay: const Duration(milliseconds: 50),
      slideFrom: const Offset(0, 20),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender differentiation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                isUser ? 'You' : 'Dealer',
                style: TextStyle(
                  color: isUser ? AppTheme.accentGreen : AppTheme.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.accentBlue.withOpacity(0.2),
                    child: const Icon(
                      Icons.storefront,
                      size: 16,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.accentGreen : AppTheme.glassBg,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 44, right: 12),
              child: Text(
                timestamp,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
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
            border: const Border(top: BorderSide(color: AppTheme.glassBorder)),
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
                        hintText: 'Message dealer...',
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
                  glowColor: AppTheme.accentBlue,
                  borderRadius: 50,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlue,
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
