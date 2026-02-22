import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalysisProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Map<String, dynamic>? _analysisResult;
  Map<String, dynamic>? get analysisResult => _analysisResult;

  /// Perform full-stack contract analysis
  Future<void> analyzeContract(String contractText) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.analyzeContractV1(contractText);
      _analysisResult = response;
    } catch (e) {
      _error = e.toString();
      _analysisResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearAnalysis() {
    _analysisResult = null;
    _error = null;
    notifyListeners();
  }
}
