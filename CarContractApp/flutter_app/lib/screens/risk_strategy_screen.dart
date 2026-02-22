import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../animations/animations.dart';

class RiskStrategyScreen extends StatefulWidget {
  final String? contractId;
  const RiskStrategyScreen({super.key, this.contractId});

  @override
  State<RiskStrategyScreen> createState() => _RiskStrategyScreenState();
}

class _RiskStrategyScreenState extends State<RiskStrategyScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _strategyData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.contractId == null) return;
    setState(() => _isLoading = true);
    try {
      final strategy = await ApiService.getNegotiationStrategy(
        widget.contractId!,
      );
      if (mounted) {
        setState(() {
          _strategyData = strategy;
        });
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: widget.contractId == null
                ? const Center(
                    child: Text(
                      "Please select a contract first.",
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentGreen,
                    ),
                  )
                : _strategyData == null
                ? const Center(
                    child: Text(
                      "Strategy could not be loaded.",
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : _buildDashboard(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppTheme.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text(
                'Risk Strategy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final tactics = _strategyData!['tactics'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiquidGlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined, color: AppTheme.accentOrange),
                  SizedBox(width: 8),
                  Text(
                    "Leverage & Strategy",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...tactics.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.insights,
                        color: AppTheme.accentGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.toString(),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tactics.isEmpty)
                const Text(
                  "No active strategies identified for this contract.",
                  style: TextStyle(color: AppTheme.textMuted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const LiquidGlassContainer(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Actionable Next Steps",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Use the 'Message Dealer' feature to discuss the identified risks directly with the provider. Focus on clauses with the highest severity.",
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
