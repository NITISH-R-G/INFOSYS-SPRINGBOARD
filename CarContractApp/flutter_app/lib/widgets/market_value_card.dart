import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../animations/animations.dart';

class MarketValueCard extends StatelessWidget {
  final double contractPrice;
  final double estimatedValue;
  final double? highValue;
  final double? lowValue;
  final String confidence;

  const MarketValueCard({
    super.key,
    required this.contractPrice,
    required this.estimatedValue,
    this.highValue,
    this.lowValue,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = contractPrice / estimatedValue;
    final bool isOverpriced = ratio > 1.10;
    final bool isGoodDeal = ratio < 0.95;
    
    // Determine status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isOverpriced) {
      statusColor = AppTheme.accentRed;
      statusText = 'Overpriced';
      statusIcon = Icons.trending_up;
    } else if (isGoodDeal) {
      statusColor = AppTheme.accentGreen;
      statusText = 'Great Value';
      statusIcon = Icons.trending_down;
    } else {
      statusColor = AppTheme.accentBlue;
      statusText = 'Fair Market Price';
      statusIcon = Icons.check_circle_outline;
    }

    // Format currency
    final String priceStr = '₹${contractPrice.toStringAsFixed(0)}';
    final String valueStr = '₹${estimatedValue.toStringAsFixed(0)}';
    final String difference = '₹${(contractPrice - estimatedValue).abs().toStringAsFixed(0)}';
    final String diffPrefix = isOverpriced ? '+' : (isGoodDeal ? '-' : '');

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Price Analysis',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.glassBorder,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${confidence.toUpperCase()} CONFIDENCE',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Price vs Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contract Price',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceStr,
                    style: TextStyle(
                      color: isOverpriced ? AppTheme.accentRed : AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: AppTheme.glassBorder,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Est. Market Value',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valueStr,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Visual Gauge Bar
          Stack(
            children: [
              // Background Track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Marker for Estimated Value (Center)
              Positioned(
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 2,
                    height: 8,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              // Actual Price Indicator
              TweenAnimationBuilder<double>(
                duration: AnimationConfig.normal,
                curve: AnimationConfig.primaryCurve,
                tween: Tween(begin: 0.5, end: 0.5 + ((ratio - 1.0) * 2).clamp(-0.5, 0.5)),
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: 1.0,
                    child: Align(
                      alignment: Alignment(value * 2 - 1, 0), // Convert 0..1 to -1..1
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Good Deal', style: TextStyle(color: AppTheme.accentGreen, fontSize: 11)),
              Text('Fair Price', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              Text('Overpriced', style: TextStyle(color: AppTheme.accentRed, fontSize: 11)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Insight Message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isOverpriced
                        ? 'This contract is $diffPrefix$difference above market value. Consider negotiating.'
                        : (isGoodDeal 
                            ? 'Excellent! You are saving estimated $diffPrefix$difference below market value.'
                            : 'This price aligns with current market conditions.'),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (highValue != null && lowValue != null)
             Padding(
               padding: const EdgeInsets.only(top: 12),
               child: Text(
                 'Market Range: ₹${lowValue!.toStringAsFixed(0)} - ₹${highValue!.toStringAsFixed(0)}',
                 style: const TextStyle(
                   color: AppTheme.textMuted,
                   fontSize: 12,
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
        ],
      ),
    );
  }
}
