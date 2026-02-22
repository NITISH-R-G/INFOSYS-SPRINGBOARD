import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/glassmorphism_cards.dart';
import '../widgets/liquid_progress_indicator.dart';

class MacosDashboardScreen extends StatefulWidget {
  const MacosDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MacosDashboardScreen> createState() => _MacosDashboardScreenState();
}

class _MacosDashboardScreenState extends State<MacosDashboardScreen> {
  final TextEditingController _contractTextController = TextEditingController();

  @override
  void dispose() {
    _contractTextController.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _contractTextController.text.trim();
    if (text.isNotEmpty) {
      context.read<AnalysisProvider>().analyzeContract(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // macOS aesthetic: deep gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E2C), // Deep dark blue
              Color(0xFF2D2B4A), // Purplish dark
              Color(0xFF1B1B22), // Almost black
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Consumer<AnalysisProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (provider.error != null) {
                      return Center(
                        child: Text(
                          "Error: ${provider.error}",
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    if (provider.analysisResult == null) {
                      return _buildInputSection();
                    }

                    return _buildResultsDashboard(provider.analysisResult!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Text(
                "Contract Analysis",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.white,
                  fontFamily:
                      '.SF Pro Display', // Using Apple's default font family fallback
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              context.read<AnalysisProvider>().clearAnalysis();
              _contractTextController.clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassCard(
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Paste Contract Text",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _contractTextController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Paste OCR extracted text here...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Analyze Contract",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsDashboard(Map<String, dynamic> result) {
    final double score = (result['contract_fairness_score'] ?? 0).toDouble();
    final String tier = result['fairness_tier'] ?? "Unknown";

    Color scoreColor = Colors.blueAccent;
    if (score >= 80)
      scoreColor = Colors.greenAccent;
    else if (score >= 60)
      scoreColor = Colors.orangeAccent;
    else if (score > 0)
      scoreColor = Colors.redAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          // Top Section: Score & High-level details
          SizedBox(
            height: 220,
            child: Row(
              children: [
                // Fairness Score Liquid Indicator
                Expanded(
                  flex: 4,
                  child: GlassCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Fairness Score",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: LiquidCircularProgressIndicator(
                            value: score / 100.0,
                            label: tier,
                            baseColor: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Contract Facts
                Expanded(
                  flex: 5,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFactRow(
                          "Type",
                          result['contract_type'] ?? "Unknown",
                        ),
                        _buildFactRow(
                          "APR",
                          result['apr'] != null ? "${result['apr']}%" : "N/A",
                        ),
                        _buildFactRow(
                          "Term",
                          result['term_months'] != null
                              ? "${result['term_months']} mo"
                              : "N/A",
                        ),
                        _buildFactRow(
                          "Payment",
                          result['monthly_payment'] != null
                              ? "₹${result['monthly_payment']}"
                              : "N/A",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle Specs Card
          GlassVehicleCard(specs: result['vehicle_specs']),
          const SizedBox(height: 16),

          // Pricing Intelligence Card
          GlassPriceCard(pricingData: result),
          const SizedBox(height: 16),

          // Analysis Notes Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.analytics, color: Colors.purpleAccent),
                    SizedBox(width: 8),
                    Text(
                      "AI Analysis Notes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  result['analysis_notes'] ?? "No notes provided.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFactRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
