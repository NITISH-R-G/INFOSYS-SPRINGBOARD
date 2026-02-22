import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/contract.dart';
import '../services/api_service.dart';

class ComparisonScreen extends StatefulWidget {
  final List<String> contractIds;

  const ComparisonScreen({super.key, required this.contractIds});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  List<Contract> _contracts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    try {
      final List<Contract> loaded = [];
      for (final id in widget.contractIds) {
        final data = await ApiService.getContract(id);
        loaded.add(Contract.fromJson(data));
      }
      if (mounted) {
        setState(() {
          _contracts = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Contracts'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _contracts.isEmpty
          ? const Center(child: Text('No contracts selected'))
          : Column(
              children: [
                _buildInsightsCard(),
                Expanded(child: _buildComparisonTable()),
              ],
            ),
    );
  }

  Widget _buildInsightsCard() {
    if (_contracts.length < 2) return const SizedBox.shrink();

    // Generate basic insights based on fairness score and APR
    Contract? bestDeal = _contracts.reduce((a, b) {
      final scoreA = a.analysis?.fairnessScore ?? 0;
      final scoreB = b.analysis?.fairnessScore ?? 0;
      return scoreA > scoreB ? a : b;
    });

    final aprValues = _contracts
        .map((c) => c.analysis?.slaData?.apr)
        .whereType<double>()
        .toList();

    double? lowestApr;
    if (aprValues.isNotEmpty) {
      lowestApr = aprValues.reduce((a, b) => a < b ? a : b);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: AppTheme.accentGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comparison Insights',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on our AI analysis, "${bestDeal.title}" offers the most favorable terms overall with a fairness score of ${bestDeal.analysis?.fairnessScore ?? 0}. '
                  '${lowestApr != null ? 'It also features a competitive market APR of ${lowestApr.toStringAsFixed(1)}%.' : ''}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    // Collect all terms we want to compare
    final terms = [
      'Monthly Payment',
      'Down Payment',
      'APR',
      'Term (Months)',
      'Mileage Limit',
      'Buyout Price',
      'Fairness Score',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            columnWidths: {
              0: const FixedColumnWidth(140), // Label column
              for (var i = 1; i <= _contracts.length; i++)
                i: const FixedColumnWidth(160), // Contract columns
            },
            border: TableBorder.all(
              color: AppTheme.glassBorder,
              width: 1,
              borderRadius: BorderRadius.circular(12),
              style: BorderStyle.solid,
            ),
            children: [
              // Header Row (Titles)
              TableRow(
                decoration: BoxDecoration(color: AppTheme.glassBg),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Feature',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  ..._contracts.map(
                    (c) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        c.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              // Data Rows
              for (final term in terms)
                TableRow(
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.3),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        term,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ..._contracts.map(
                      (c) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildValueCell(c, term),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueCell(Contract contract, String term) {
    if (contract.analysis?.slaData == null && term != 'Fairness Score') {
      return const Text('-', textAlign: TextAlign.center);
    }

    final sla = contract.analysis?.slaData;
    String value = '-';
    Color? color;

    switch (term) {
      case 'Monthly Payment':
        value = '₹${sla?.monthlyPayment?.toStringAsFixed(0) ?? 'N/A'}';
        break;
      case 'Down Payment':
        value = '₹${sla?.downPayment?.toStringAsFixed(0) ?? 'N/A'}';
        break;
      case 'APR':
        value = '${sla?.apr?.toStringAsFixed(2) ?? 'N/A'}%';
        break;
      case 'Term (Months)':
        value = '${sla?.termMonths ?? 'N/A'}';
        break;
      case 'Mileage Limit':
        value = '${sla?.mileageLimit ?? 'N/A'}';
        break;
      case 'Buyout Price':
        value = '₹${sla?.buyoutPrice?.toStringAsFixed(0) ?? 'N/A'}';
        break;
      case 'Fairness Score':
        final score = contract.analysis?.fairnessScore ?? 0;
        value = score.toString();
        color = score >= 80
            ? AppTheme.accentGreen
            : score >= 60
            ? AppTheme.accentOrange
            : AppTheme.accentRed;
        break;
    }

    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color ?? AppTheme.textPrimary,
        fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
