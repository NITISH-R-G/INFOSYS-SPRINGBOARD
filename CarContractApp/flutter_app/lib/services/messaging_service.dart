import 'dart:convert';
import 'package:http/http.dart' as http;

class MessagingService {
  final String _baseUrl = 'http://127.0.0.1:8000/api/messaging';

  Future<List<dynamic>> getConversations(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load conversations');
    }
  }

  Future<Map<String, dynamic>> createConversation(
    String token,
    int dealerId, {
    int? contractId,
    String? subject,
  }) async {
    final body = <String, dynamic>{'dealer_id': dealerId};
    if (contractId != null) body['contract_id'] = contractId;
    if (subject != null) body['subject'] = subject;

    final response = await http.post(
      Uri.parse('$_baseUrl/conversations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create conversation');
    }
  }

  Future<List<dynamic>> getMessages(String token, int conversationId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    String token,
    int conversationId,
    String content,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/conversations/$conversationId/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'content': content}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send message');
    }
  }
}
