import 'package:flutter/material.dart';
import '../services/messaging_service.dart';

class ChatProvider with ChangeNotifier {
  final MessagingService _messagingService = MessagingService();

  List<dynamic> _conversations = [];
  List<dynamic> _currentMessages = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get conversations => _conversations;
  List<dynamic> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchConversations(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _messagingService.getConversations(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String token, int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentMessages = await _messagingService.getMessages(
        token,
        conversationId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(
    String token,
    int conversationId,
    String content,
  ) async {
    try {
      final newMessage = await _messagingService.sendMessage(
        token,
        conversationId,
        content,
      );
      _currentMessages.add(newMessage);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createConversation(
    String token,
    int dealerId, {
    int? contractId,
    String? subject,
  }) async {
    try {
      final newConv = await _messagingService.createConversation(
        token,
        dealerId,
        contractId: contractId,
        subject: subject,
      );
      _conversations.insert(0, newConv);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
