import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/contract.dart';
import '../models/valuation_model.dart';
import '../models/fairness_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api'; // FastAPI Backend

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<VehicleValuation> fetchVehicleValuation(String vin) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/vin/$vin'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Wrap the response in the expected Valuation format
        final data = jsonDecode(response.body);
        return VehicleValuation.fromJson({
          'vin': vin,
          'metrics': {
            'marketAverage': data['price_estimate'] ?? 0.0,
            'fairRangeLow': (data['price_estimate'] ?? 0.0) * 0.95,
            'fairRangeHigh': (data['price_estimate'] ?? 0.0) * 1.05,
          },
        });
      } else {
        throw Exception('Failed to load valuation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }

  static Future<FairnessScore> calculateFairness({
    required double contractPrice,
    required double marketAverage,
    double? apr,
    double? fees,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/fairness',
        ), // Unprefixed in backend currently
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'contract_price': contractPrice,
          'market_average': marketAverage,
          'apr': apr,
          'fees': fees ?? 0.0,
        }),
      );

      if (response.statusCode == 200) {
        return FairnessScore.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to calculate fairness: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload contract: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeContract(String contractId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/contracts/$contractId/analyze'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze contract');
      }
    } catch (e) {
      throw Exception('Error analyzing: $e');
    }
  }

  static Future<Map<String, dynamic>> getContract(String contractId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/$contractId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['structured_json'] != null) {
          try {
            data.addAll(jsonDecode(data['structured_json']));
          } catch (e) {}
        }
        return data;
      } else {
        throw Exception('Failed to get contract');
      }
    } catch (e) {
      throw Exception('Error getting contract: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getContracts() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> list = jsonDecode(response.body);
        return list.map((item) {
          var data = Map<String, dynamic>.from(item);
          if (data['structured_json'] != null) {
            try {
              final analysis = jsonDecode(data['structured_json']);
              if (analysis['fairness_score'] != null)
                data['fairness_score'] = analysis['fairness_score'];
              if (analysis['contract_type'] != null)
                data['contract_type'] = analysis['contract_type'];
            } catch (_) {}
          }
          return data;
        }).toList();
      } else {
        throw Exception('Failed to get contracts');
      }
    } catch (e) {
      throw Exception('Error getting contracts: $e');
    }
  }

  static Future<Map<String, dynamic>> lookupVin(String vin) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/vin/$vin'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load VIN data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  static Future<Map<String, dynamic>> sendNegotiationMessage({
    required String message,
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/negotiations/chat'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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
}
