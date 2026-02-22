import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../animations/animations.dart';
import '../services/api_service.dart';

class DealerChatScreen extends StatefulWidget {
  final String? contractId;
  const DealerChatScreen({super.key, this.contractId});

  @override
  State<DealerChatScreen> createState() => _DealerChatScreenState();
}

class _DealerChatScreenState extends State<DealerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _conversationId;
  bool _initializing = true;
  bool _loadingCopilot = false;
  List<String> _copilotSuggestions = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final chatProv = Provider.of<ChatProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() => _initializing = false);
      return;
    }

    await chatProv.fetchConversations(token);

    // Find conversation by contractId or generic
    final match = chatProv.conversations.firstWhere(
      (c) => c['contract_id']?.toString() == widget.contractId,
      orElse: () => null,
    );

    if (match != null) {
      _conversationId = match['id'];
      await chatProv.fetchMessages(token, _conversationId!);
    } else {
      // If we are a buyer, try to create one. For a dealer, it might just be empty list if no conv exists.
      if (authProv.role == 'buyer') {
        int dealerId = 2; // Fallback mock ID

        // Fetch contract to get dynamic dealer_id if available
        if (widget.contractId != null) {
          try {
            final contractData = await ApiService.getContract(
              widget.contractId!,
            );
            if (contractData['dealer'] != null &&
                contractData['dealer']['user_id'] != null) {
              dealerId = contractData['dealer']['user_id'];
            } else if (contractData['dealer_id'] != null) {
              // Fallback just in case
              dealerId = contractData['dealer_id'];
            }
          } catch (e) {
            print("Could not fetch contract for dealer ID: $e");
          }
        }

        try {
          final success = await chatProv.createConversation(
            token,
            dealerId,
            contractId: int.tryParse(widget.contractId ?? ''),
            subject: "Contract Inquiry",
          );
          if (success && chatProv.conversations.isNotEmpty) {
            _conversationId = chatProv.conversations.first['id'];
            await chatProv.fetchMessages(token, _conversationId!);
          }
        } catch (_) {}
      }
    }
    setState(() => _initializing = false);
    _scrollToBottom();
    _fetchCopilotSuggestions();
  }

  Future<void> _fetchCopilotSuggestions() async {
    if (widget.contractId == null) return;

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    // Only fetch for buyer
    if (authProv.role != 'buyer') return;

    if (mounted) setState(() => _loadingCopilot = true);

    try {
      final strategy = await ApiService.getNegotiationStrategy(
        widget.contractId!,
      );
      if (mounted) {
        setState(() {
          final priorityActions = List<String>.from(
            strategy['priority_actions'] ?? [],
          );
          final talkingPoints = List<String>.from(
            strategy['talking_points'] ?? [],
          );
          _copilotSuggestions = [...priorityActions, ...talkingPoints];
        });
      }
    } catch (e) {
      print("Failed to load copilot suggestions: $e");
    } finally {
      if (mounted) setState(() => _loadingCopilot = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    final chatProv = Provider.of<ChatProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      _messageController.clear();
      await chatProv.sendMessage(token, _conversationId!, text);
      _scrollToBottom();
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
                child: Consumer2<ChatProvider, AuthProvider>(
                  builder: (context, chatProv, authProv, child) {
                    if (_initializing || chatProv.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_conversationId == null) {
                      return const Center(
                        child: Text("Conversation could not be loaded."),
                      );
                    }
                    final messages = chatProv.currentMessages;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(
                          messages[index],
                          authProv.userId,
                          index,
                        );
                      },
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildCopilotSuggestions(), _buildInputArea()],
              ),
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

  Widget _buildMessageBubble(
    dynamic message,
    String? currentUserId,
    int index,
  ) {
    final isUser = message['sender_id'].toString() == currentUserId;
    DateTime timestampDt;
    try {
      timestampDt = DateTime.parse(message['created_at']);
    } catch (_) {
      timestampDt = DateTime.now();
    }
    final timestamp = DateFormat('h:mm a').format(timestampDt.toLocal());

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

  Widget _buildCopilotSuggestions() {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    if (authProv.role != 'buyer') return const SizedBox.shrink();

    if (_loadingCopilot) {
      return Container(
        height: 50,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accentOrange,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'AI Copilot analyzing...',
              style: TextStyle(color: AppTheme.accentOrange, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_copilotSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _copilotSuggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _copilotSuggestions[index];
          return ActionChip(
            label: Text(
              suggestion,
              style: const TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 13,
              ),
            ),
            backgroundColor: AppTheme.accentOrange.withOpacity(0.1),
            side: BorderSide(color: AppTheme.accentOrange.withOpacity(0.3)),
            onPressed: () {
              setState(() {
                _messageController.text = suggestion;
              });
            },
          );
        },
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
