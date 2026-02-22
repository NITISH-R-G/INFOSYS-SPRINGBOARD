import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contract.dart';
import '../theme/app_theme.dart';
import '../animations/liquid_glass_container.dart';

class SlaSummaryCard extends StatelessWidget {
  final SlaData? slaData;

  const SlaSummaryCard({super.key, required this.slaData});

  String _formatCurrency(double? value, String currencyCode) {
    if (value == null) return 'N/A';
    final format = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return format.format(value);
  }

  String _formatApr(double? apr) {
    if (apr == null) return 'N/A';
    return '${apr.toStringAsFixed(1)}%';
  }

  String _formatMonths(int? months) {
    if (months == null) return 'N/A';
    return '$months mo';
  }

  @override
  Widget build(BuildContext context) {
    // If absolutely no SLA data is present, show a graceful fallback
    if (slaData == null) {
      return LiquidGlassContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: const [
              Icon(
                Icons.analytics_outlined,
                color: AppTheme.textMuted,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Financial details not found in document',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final currency = slaData!.currencyCode;

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: AppTheme.accentBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Financial Terms',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              // Switch to a column layout if screen is too narrow
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _buildSummaryItem(
                      'Monthly Payment',
                      _formatCurrency(slaData!.monthlyPayment, currency),
                      Icons.payments_outlined,
                      AppTheme.accentGreen,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem(
                      'APR',
                      _formatApr(slaData!.apr),
                      Icons.percent,
                      AppTheme.accentBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem(
                      'Term Length',
                      _formatMonths(slaData!.termMonths),
                      Icons.calendar_month_outlined,
                      AppTheme.accentOrange,
                    ),
                  ],
                );
              }

              // Otherwise show side-by-side row
              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Monthly Payment',
                      _formatCurrency(slaData!.monthlyPayment, currency),
                      Icons.payments_outlined,
                      AppTheme.accentGreen,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppTheme.glassBorder,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'APR',
                      _formatApr(slaData!.apr),
                      Icons.percent,
                      AppTheme.accentBlue,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppTheme.glassBorder,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Term Length',
                      _formatMonths(slaData!.termMonths),
                      Icons.calendar_month_outlined,
                      AppTheme.accentOrange,
                    ),
                  ),
                ],
              );
            },
          ),

          // Additional SLA Details row if present
          if (slaData!.downPayment != null ||
              slaData!.mileageLimit != null) ...[
            const SizedBox(height: 24),
            const Divider(color: AppTheme.glassBorder),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                if (slaData!.downPayment != null)
                  _buildSecondaryItem(
                    'Down Payment',
                    _formatCurrency(slaData!.downPayment, currency),
                  ),
                if (slaData!.mileageLimit != null)
                  _buildSecondaryItem(
                    'Mileage Limit',
                    '${NumberFormat.decimalPattern().format(slaData!.mileageLimit)} /yr',
                  ),
                if (slaData!.residualValue != null)
                  _buildSecondaryItem(
                    'Residual Value',
                    _formatCurrency(slaData!.residualValue, currency),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
