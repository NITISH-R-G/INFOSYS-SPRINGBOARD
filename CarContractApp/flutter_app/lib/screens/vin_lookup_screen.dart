import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../models/contract.dart';

class VinLookupScreen extends StatefulWidget {
  const VinLookupScreen({super.key});

  @override
  State<VinLookupScreen> createState() => _VinLookupScreenState();
}

class _VinLookupScreenState extends State<VinLookupScreen> {
  final TextEditingController _vinController = TextEditingController();
  VehicleInfo? _vehicleInfo;
  bool _isLoading = false;
  String? _error;

  Future<void> _lookupVin() async {
    final vin = _vinController.text.trim();
    if (vin.length != 17) {
      setState(() {
        _error = 'VIN must be exactly 17 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _vehicleInfo = null;
    });

    try {
      final data = await ApiService.lookupVin(vin);
      setState(() {
        _vehicleInfo = VehicleInfo.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIN Lookup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // VIN Input
              TextField(
                controller: _vinController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 17,
                decoration: InputDecoration(
                  hintText: 'Enter 17-character VIN',
                  prefixIcon: const Icon(
                    Icons.directions_car_outlined,
                    color: AppTheme.textMuted,
                  ),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: AppTheme.accentGreen,
                          ),
                          onPressed: _lookupVin,
                        ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  if (val.trim().length == 17 && !_isLoading) {
                    _lookupVin();
                  }
                },
                onSubmitted: (_) {
                  if (!_isLoading) _lookupVin();
                },
              ),
              const SizedBox(height: 24),

              // Error
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.accentRed),
                  ),
                ),

              // Results
              if (_vehicleInfo != null) ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_vehicleInfo!.year ?? ''} ${_vehicleInfo!.make ?? ''} ${_vehicleInfo!.model ?? ''}'
                            .trim(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('VIN', _vehicleInfo!.vin),
                      _buildInfoRow('Body', _vehicleInfo!.bodyClass ?? 'N/A'),
                      _buildInfoRow(
                        'Engine',
                        _vehicleInfo!.engineType ?? 'N/A',
                      ),
                      _buildInfoRow('Fuel', _vehicleInfo!.fuelType ?? 'N/A'),
                      _buildInfoRow('Drive', _vehicleInfo!.driveType ?? 'N/A'),
                      _buildInfoRow(
                        'Transmission',
                        _vehicleInfo!.transmission ?? 'N/A',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Market Intelligence
                if (_vehicleInfo!.msrp != null ||
                    _vehicleInfo!.marketAverage != null) ...[
                  const Text(
                    'MARKET INTELLIGENCE',
                    style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_vehicleInfo!.msrp != null)
                          _buildPriceRow('MSRP', _vehicleInfo!.msrp!),
                        if (_vehicleInfo!.marketAverage != null)
                          _buildPriceRow(
                            'Market Average',
                            _vehicleInfo!.marketAverage!,
                          ),
                        if (_vehicleInfo!.fairPriceLow != null &&
                            _vehicleInfo!.fairPriceHigh != null)
                          _buildInfoRow(
                            'Fair Price Range',
                            '₹${_vehicleInfo!.fairPriceLow!.toStringAsFixed(0)} - ₹${_vehicleInfo!.fairPriceHigh!.toStringAsFixed(0)}',
                          ),
                        if (_vehicleInfo!.incentives.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Available Incentives:',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._vehicleInfo!.incentives.map(
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 16,
                                    color: AppTheme.accentGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    i,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_vehicleInfo!.dataSources.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Sources: ${_vehicleInfo!.dataSources.join(", ")}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Recalls
                if (_vehicleInfo!.recalls.isNotEmpty) ...[
                  const Text(
                    'RECALLS',
                    style: TextStyle(
                      color: AppTheme.accentRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._vehicleInfo!.recalls.map(
                    (recall) => _buildRecallCard(recall),
                  ),
                ] else
                  GlassCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.accentGreen,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'No recalls found',
                          style: TextStyle(color: AppTheme.accentGreen),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.accentGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecallCard(VehicleRecall recall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  size: 20,
                  color: AppTheme.accentOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recall.component,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recall.summary,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }
}
