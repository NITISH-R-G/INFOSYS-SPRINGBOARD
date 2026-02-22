import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final EdgeInsets padding;

  const GlassCard({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.padding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassVehicleCard extends StatelessWidget {
  final Map<String, dynamic>? specs;
  const GlassVehicleCard({Key? key, required this.specs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (specs == null) {
      return const GlassCard(
        child: Center(
          child: Text(
            "No Vehicle Specs Available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${specs!['year'] ?? ''} ${specs!['make'] ?? ''} ${specs!['model'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSpecRow("VIN", specs!['vin'] ?? "Unknown"),
          _buildSpecRow("Trim", specs!['trim'] ?? "N/A"),
          _buildSpecRow("Body", specs!['body_type'] ?? "N/A"),
          _buildSpecRow("Engine", specs!['engine'] ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              val,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassPriceCard extends StatelessWidget {
  final Map<String, dynamic> pricingData;

  const GlassPriceCard({Key? key, required this.pricingData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double? fairPriceLow = pricingData['fair_price_low'];
    final double? fairPriceHigh = pricingData['fair_price_high'];
    final double? contractPrice = pricingData['total_financed'];

    final bool hasMarketData = fairPriceLow != null && fairPriceHigh != null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.monetization_on, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text(
                "Pricing Intelligence",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (contractPrice != null)
            _buildPriceRow(
              "Contract Price",
              "₹${contractPrice.toStringAsFixed(2)}",
              Colors.white,
              large: true,
            ),

          if (hasMarketData) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              "Est. Fair Range",
              "₹${fairPriceLow.toStringAsFixed(0)} - ₹${fairPriceHigh.toStringAsFixed(0)}",
              Colors.greenAccent,
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              "MSRP Baseline",
              "₹${pricingData['estimated_msrp']?.toStringAsFixed(0) ?? 'N/A'}",
              Colors.white70,
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              "Market Data Unavailable",
              style: TextStyle(
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String price,
    Color priceColor, {
    bool large = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: large ? 16 : 14,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            color: priceColor,
            fontSize: large ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
