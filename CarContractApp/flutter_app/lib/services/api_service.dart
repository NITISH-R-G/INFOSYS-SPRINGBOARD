import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';
import '../models/contract.dart';
import '../models/valuation_model.dart';
import '../models/fairness_model.dart';

/// API Service (Local SQLite Implementation)
class ApiService {
  static final DatabaseHelper _dbDispatcher = DatabaseHelper();
  static const Uuid _uuid = Uuid();
  static const String baseUrl = 'http://127.0.0.1:8000'; // FastAPI Backend

  /// Fetch Vehicle Valuation
  static Future<VehicleValuation> fetchVehicleValuation(String vin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/valuation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'vin': vin}),
      );

      if (response.statusCode == 200) {
        return VehicleValuation.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load valuation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }

  /// Calculate Fairness
  static Future<FairnessScore> calculateFairness({
    required double contractPrice,
    required double marketAverage,
    double? apr,
    double? fees,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fairness'),
        headers: {'Content-Type': 'application/json'},
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

  /// Upload a contract file from bytes (works on Web)
  /// Returns the created Contract map
  static Future<Map<String, dynamic>> uploadContractBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final db = await _dbDispatcher.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    // Create a mock contract record
    final contract = {
      'id': id,
      'user_id': 'demo_user', // Fixed for prototype
      'title': fileName,
      'file_path': 'local_storage/$fileName', // fast-forward for now
      'status': 'analyzing', // will trigger analysis
      'created_at': now,
      'updated_at': now,
      // 'fairness_score': null, // initially null
    };

    await db.insert('contracts', contract);

    // Simulate analysis delay in background (or just return draft)
    _mockAnalysisInBackground(id);

    return contract;
  }

  static Future<void> _mockAnalysisInBackground(String id) async {
    await Future.delayed(const Duration(seconds: 3));
    final db = await _dbDispatcher.database;

    // Create dummy analysis data
    final analysis = {
      'fairness_score': 85,
      'fairness_explanation': 'Good contract with minor risks.',
      'sla_data': {
        'apr': 5.9,
        'term_months': 36,
        'monthly_payment': 450.0,
        'down_payment': 2000.0,
        'mileage_limit': 12000,
        'market_value': 32000.0,
      },
      'red_flags': [
        {
          'title': 'High Disposition Fee',
          'risk_level': 'medium',
          'plain_explanation': 'Fee of \$500 due at lease end.',
        },
      ],
    };

    await db.update(
      'contracts',
      {
        'status': 'reviewed',
        'fairness_score': 85,
        'structured_json': jsonEncode(analysis), // Store for future
        // For simple lookup in frontend, we might merge fields or just rely on structured_json
        // But our Contract.fromJson currently checks 'fairness_score' and 'sla_data' in the top level map?
        // Let's actually UPDATE the row to include breakdown if we didn't normalize heavily.
        // Since my schema has 'structured_json', I should technically parse it in Contract.fromJson.
        // But Contract.fromJson expects a Map.
        // NOTE: existing Contract.fromJson expects flat text fields OR nested map.
        // Let's enable robust fetching by returning the merged map in getContract.
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Analyze a contract by ID
  static Future<Map<String, dynamic>> analyzeContract(String contractId) async {
    // In local mode, analysis happens on upload. Just return contract.
    return getContract(contractId);
  }

  /// Get contract details
  static Future<Map<String, dynamic>> getContract(String contractId) async {
    final db = await _dbDispatcher.database;
    final results = await db.query(
      'contracts',
      where: 'id = ?',
      whereArgs: [contractId],
    );

    if (results.isEmpty) throw Exception('Contract not found');

    var data = Map<String, dynamic>.from(results.first);

    // If we stored analysis in structured_json, merge it for the frontend model
    if (data['structured_json'] != null) {
      try {
        final analysis = jsonDecode(data['structured_json'] as String);
        data.addAll(
          analysis,
        ); // Merge analysis fields (sla_data, etc) into top level
      } catch (e) {
        print('Error parsing structured_json: $e');
      }
    }

    return data;
  }

  /// Get all contracts
  static Future<List<Map<String, dynamic>>> getContracts() async {
    final db = await _dbDispatcher.database;
    final results = await db.query('contracts', orderBy: 'created_at DESC');

    return results.map((row) {
      var data = Map<String, dynamic>.from(row);
      // Merge analysis for list view (e.g. fairness score is already column, but maybe others)
      if (data['structured_json'] != null) {
        try {
          final analysis = jsonDecode(data['structured_json'] as String);
          // Only need summary fields
          if (analysis['fairness_score'] != null) {
            data['fairness_score'] = analysis['fairness_score'];
          }
          if (analysis['contract_type'] != null) {
            data['contract_type'] = analysis['contract_type'];
          }
        } catch (_) {}
      }
      return data;
    }).toList();
  }

  /// VIN Lookup (Real Backend Integration)
  static Future<Map<String, dynamic>> lookupVin(String vin) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vehicles/vin/$vin'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load VIN data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  /// Negotiation chat (Mock AI)
  static Future<Map<String, dynamic>> sendNegotiationMessage({
    required String message,
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final lowerMsg = message.toLowerCase();
    String responseText = "";

    if (lowerMsg.contains("fee") ||
        lowerMsg.contains("disposition") ||
        lowerMsg.contains("hidden")) {
      responseText =
          "I noticed a standard \$500 disposition fee in this lease. You could politely ask if this is negotiable by saying: 'I see a \$500 disposition fee included here. Given my strong credit history, is there any flexibility to waive or reduce this fee?'";
    } else if (lowerMsg.contains("apr") ||
        lowerMsg.contains("rate") ||
        lowerMsg.contains("interest")) {
      responseText =
          "The APR is currently sitting at 5.9%. While fair, you can often negotiate this if you have excellent credit. Consider asking: 'Based on my recent credit score, I was hoping to secure a rate closer to 4.5%. Can we review the financing options to see if we can get closer to that target?'";
    } else if (lowerMsg.contains("price") ||
        lowerMsg.contains("cost") ||
        lowerMsg.contains("expensive")) {
      responseText =
          "It's always a good idea to negotiate the capitalized cost (the base price of the car). Try this phrasing: 'I've been looking at market values, and similar models are selling for a bit less. Can we agree on a purchase price of \$30,500 before we run the financing?'";
    } else if (lowerMsg.contains("mile") || lowerMsg.contains("limit")) {
      responseText =
          "The current contract limits you to 12,000 miles/year. If you drive more, it's cheaper to buy miles upfront. You could ask: 'I typically drive about 15,000 miles a year. How much would it add to my monthly payment to increase the mileage limit upfront, rather than paying the 25-cent penalty later?'";
    } else if (lowerMsg.contains("legal") ||
        lowerMsg.contains("law") ||
        lowerMsg.contains("sue")) {
      responseText =
          "As an AI assistant, I cannot provide formal legal advice. However, if you are concerned about arbitration clauses or default terms, I strongly recommend having a qualified attorney review those specific sections before you sign.";
    } else {
      responseText =
          "That's a great point to review. In general, when negotiating, keep your tone collaborative but firm. Focus on the total 'out the door' price rather than just the monthly payment. Would you like me to help you draft a message to the dealer about a specific term like the APR or fees?";
    }

    return {
      'response': responseText,
      // 'suggested_actions': ['Ask for fee waiver', 'Compare with market rate'],
    };
  }
}
