import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/contract.dart';

class AnalysisSectionCard extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final List<ReviewRisk> risks;
  final bool initiallyExpanded;

  const AnalysisSectionCard({
    super.key,
    required this.title,
    required this.details,
    this.risks = const [],
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasRisks = risks.isNotEmpty;
    final riskColor = AppTheme.accentRed;
    final safeColor = AppTheme.accentGreen; // Assuming this exists or use generic green

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasRisks
              ? [
                  BoxShadow(
                    color: riskColor.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.6),
                border: Border.all(
                  color: hasRisks ? riskColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                  width: hasRisks ? 1.5 : 1,
                ),
                gradient: hasRisks
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          riskColor.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4],
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: initiallyExpanded,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  leading: _buildLeadingIcon(hasRisks, riskColor),
                  title: Text(
                    title,
                    style: TextStyle(
                      color: hasRisks ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: hasRisks
                      ? Text(
                          '${risks.length} Risk${risks.length > 1 ? 's' : ''} Detected',
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                  children: [
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 12),
                    ...details.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
                    if (hasRisks) ...[
                      const SizedBox(height: 16),
                      _buildRiskSection(riskColor),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(bool hasRisks, Color riskColor) {
    if (hasRisks) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: riskColor.withOpacity(0.3),
                    blurRadius: 8 * scale,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Icon(Icons.warning_amber_rounded, color: riskColor, size: 20),
            ),
          );
        },
        onEnd: () {}, // Creating a static pulse for now to avoid complexity without state
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.article_outlined, color: AppTheme.accentBlue, size: 20),
    );
  }

  Widget _buildRiskSection(Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gpp_maybe_outlined, size: 18, color: riskColor),
              const SizedBox(width: 8),
              Text(
                'RISK ANALYSIS',
                style: TextStyle(
                  color: riskColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...risks.map((risk) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: riskColor.withOpacity(0.5), width: 2)),
                      ),
                      child: Text(
                        '"${risk.clause}"',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      risk.reason,
                      style: TextStyle(
                        color: riskColor.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // Clean up label (camelCase to Title Case if needed, but we pass readable labels)
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
