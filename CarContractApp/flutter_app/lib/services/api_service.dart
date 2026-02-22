import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/valuation_model.dart';
import '../models/fairness_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Centralized API base URL — configurable per environment
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String apiUrl = '$baseUrl/api';

  /// Get stored JWT token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Centralized HTTP headers with automatic JWT attachment
  static Future<Map<String, String>> _authHeaders({
    String contentType = 'application/json',
  }) async {
    final token = await _getToken();
    return {
      'Content-Type': contentType,
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Centralized response handler — handles 401 globally
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Token expired or invalid — should trigger logout
      throw AuthExpiredException('Session expired. Please log in again.');
    }
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body);
      throw ApiException(
        body['detail'] ?? 'Request failed',
        statusCode: response.statusCode,
        errorCode: body['error_code'],
      );
    }
    return jsonDecode(response.body);
  }

  // ==================== Contract Endpoints ====================

  static Future<Map<String, dynamic>> uploadContractBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/contracts/upload'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error uploading: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeContract(String contractId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/contracts/$contractId/analyze'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error analyzing: $e');
    }
  }

  static Future<Map<String, dynamic>> getContract(String contractId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/$contractId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error getting contract: $e');
    }
  }

  // ==================== Full Stack V1 API ====================

  static Future<Map<String, dynamic>> analyzeContractV1(
    String contractText,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$apiUrl/v1/contract-analysis'),
        headers: headers,
        body: jsonEncode({"contract_text": contractText}),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error analyzing V1 contract: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getContracts() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/'),
        headers: headers,
      );
      final data = _handleResponse(response);
      return (data as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error getting contracts: $e');
    }
  }

  // ==================== Task Status (Polling fallback) ====================

  /// Poll task status via HTTP (fallback when WebSocket is unavailable)
  static Future<Map<String, dynamic>> getTaskStatus(String jobId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/task/$jobId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error checking task status: $e');
    }
  }

  // ==================== Vehicle Endpoints ====================

  static Future<VehicleValuation> fetchVehicleValuation(String vin) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/vin/$vin'),
        headers: headers,
      );
      final data = _handleResponse(response);
      return VehicleValuation.fromJson({
        'vin': vin,
        'metrics': {
          'marketAverage': data['price_estimate'] ?? 0.0,
          'fairRangeLow': (data['price_estimate'] ?? 0.0) * 0.95,
          'fairRangeHigh': (data['price_estimate'] ?? 0.0) * 1.05,
        },
      });
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Network or parsing error: $e');
    }
  }

  static Future<FairnessScore> calculateFairness({
    required double contractPrice,
    required double marketAverage,
    double? apr,
    double? fees,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/fairness'),
        headers: headers,
        body: jsonEncode({
          'contract_price': contractPrice,
          'market_average': marketAverage,
          'apr': apr,
          'fees': fees ?? 0.0,
        }),
      );
      return FairnessScore.fromJson(_handleResponse(response));
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Network or parsing error: $e');
    }
  }

  static Future<Map<String, dynamic>> lookupVin(String vin) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/vin/$vin'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error connecting to backend: $e');
    }
  }

  // ==================== Negotiation Endpoints ====================

  static Future<Map<String, dynamic>> sendNegotiationMessage({
    required String message,
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/negotiations/chat'),
        headers: headers,
        body: jsonEncode({
          'user_message': message,
          'context_data': context ?? {},
          'history': history ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'response': data['response']};
      } else {
        return {
          'response':
              'I encountered an error connecting to my intelligence module.',
        };
      }
    } catch (e) {
      return {'response': 'Network error reaching AI assistant.'};
    }
  }

  static Future<Map<String, dynamic>> generateCounterOfferEmail(
    String contractId,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/negotiate/generate-email'),
        headers: headers,
        body: jsonEncode({
          'contract_id': int.tryParse(contractId) ?? 0,
          'user_preferences': 'professional',
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error generating email: $e');
    }
  }

  static Future<Map<String, dynamic>> getNegotiationStrategy(
    String contractId,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/negotiate/strategy/$contractId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error getting negotiation strategy: $e');
    }
  }

  static Future<List<dynamic>> getNegotiationTips() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/negotiate/tips'),
        headers: headers,
      );
      final data = _handleResponse(response);
      return data['tips'] ?? [];
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error getting tips: $e');
    }
  }

  // ==================== Contract Comparison & Management ====================

  static Future<Map<String, dynamic>> compareContracts(
    List<String> contractIds,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/contracts/compare'),
        headers: headers,
        body: jsonEncode({
          'contract_ids': contractIds
              .map((id) => int.tryParse(id) ?? 0)
              .toList(),
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error comparing contracts: $e');
    }
  }

  static Future<void> deleteContract(String contractId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/contracts/$contractId'),
        headers: headers,
      );
      _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error deleting contract: $e');
    }
  }

  static Future<Map<String, dynamic>> updateContractStatus(
    String contractId,
    String status,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/contracts/$contractId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error updating status: $e');
    }
  }

  // ==================== Audit & Dealer Intake ====================

  static Future<List<dynamic>> getAuditLogs() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/audit/'),
        headers: headers,
      );
      final data = _handleResponse(response);
      return data as List;
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error getting audit logs: $e');
    }
  }

  static Future<void> forwardToDealer(
    String contractId,
    String dealerEmail,
    String message,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/intake/dealer-forward'),
        headers: headers,
        body: jsonEncode({
          'contract_id': int.tryParse(contractId) ?? 0,
          'dealer_email': dealerEmail,
          'message_body': message,
        }),
      );
      _handleResponse(response);
    } catch (e) {
      if (e is ApiException || e is AuthExpiredException) rethrow;
      throw ApiException('Error forwarding to dealer: $e');
    }
  }
}

// ==================== Custom Exceptions ====================

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => message;
}

class AuthExpiredException implements Exception {
  final String message;
  AuthExpiredException(this.message);

  @override
  String toString() => message;
}
