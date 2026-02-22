import 'package:flutter/material.dart';

class FairPriceCard extends StatelessWidget {
  final double contractPrice;
  final double marketAverage;
  final double fairRangeLow;
  final double fairRangeHigh;

  const FairPriceCard({
    Key? key,
    required this.contractPrice,
    required this.marketAverage,
    required this.fairRangeLow,
    required this.fairRangeHigh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine position. For a simple visual, we normalize the range
    // where low is 0.2, avg is 0.5, high is 0.8
    final double priceDelta = contractPrice - marketAverage;
    final bool isOverpriced = priceDelta > 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Market Valuation',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceStat(
                  'Contract Price',
                  contractPrice,
                  isOverpriced ? Colors.red.shade700 : Colors.green.shade700,
                ),
                _buildPriceStat(
                  'Market Avg',
                  marketAverage,
                  Colors.grey.shade800,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // The Delta
            Text(
              isOverpriced
                  ? "+₹${priceDelta.toStringAsFixed(0)} above market average"
                  : "-₹${priceDelta.abs().toStringAsFixed(0)} below market average",
              style: TextStyle(
                color: isOverpriced
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Visual Timeline/Bar (Simple representation)
            Text(
              'Fair Range: ₹${fairRangeLow.toStringAsFixed(0)} - ₹${fairRangeHigh.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade300,
                    Colors.yellow.shade400,
                    Colors.red.shade300,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Contract Price Indicator
                  // We map the contract price to a position 0.0 to 1.0 where 0.5 is market average.
                  // Range logic for display: let's say average +/- 15%.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double rangeSpread = marketAverage * 0.15;
                      final double minDisplay = marketAverage - rangeSpread;
                      final double maxDisplay = marketAverage + rangeSpread;

                      double positionRatio =
                          (contractPrice - minDisplay) /
                          (maxDisplay - minDisplay);
                      positionRatio = positionRatio.clamp(0.0, 1.0);

                      return Positioned(
                        left:
                            positionRatio * constraints.maxWidth -
                            5, // -5 to center icon
                        top: -2,
                        child: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.black,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Excellent', style: TextStyle(fontSize: 10)),
                const Text('Average', style: TextStyle(fontSize: 10)),
                const Text('Poor', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStat(String label, double price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          '₹${price.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
