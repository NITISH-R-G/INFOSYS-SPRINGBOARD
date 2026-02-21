import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/contract.dart';
import '../animations/animations.dart';

/// Collapsible VIN Info Card widget for displaying auto-detected VIN data
/// Updated with iOS 26 Liquid Glass animations
class VinInfoCard extends StatefulWidget {
  final VinLookupResult vinLookup;

  const VinInfoCard({super.key, required this.vinLookup});

  @override
  State<VinInfoCard> createState() => _VinInfoCardState();
}

class _VinInfoCardState extends State<VinInfoCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConfig.fast,
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: AnimationConfig.primaryCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vinLookup = widget.vinLookup;
    final vehicle = vinLookup.vehicleDetails;
    final crossCheck = vinLookup.crossCheck;

    // Status color
    Color statusColor;
    IconData statusIcon;
    switch (vinLookup.vinStatus) {
      case 'Valid':
        statusColor = AppTheme.accentGreen;
        statusIcon = Icons.verified;
        break;
      case 'Invalid':
        statusColor = AppTheme.accentRed;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusIcon = Icons.help_outline;
    }

    return LiquidGlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          PhysicsTapButton(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'VIN DETECTED',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(statusIcon, color: statusColor, size: 14),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vinLookup.vinNumber ?? 'N/A',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animated Content
          AnimatedCrossFade(
            firstChild: _buildSummary(vehicle),
            secondChild: _buildExpandedContent(vehicle, crossCheck),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: AnimationConfig.normal,
            sizeCurve: AnimationConfig.primaryCurve,
            firstCurve: AnimationConfig.exitCurve,
            secondCurve: AnimationConfig.entranceCurve,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(VinVehicleDetails? vehicle) {
    if (vehicle == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFF2C2C2E), height: 1),
          const SizedBox(height: 16),
          Text(
            '${vehicle.year ?? ''} ${vehicle.make ?? ''} ${vehicle.model ?? ''}'.trim(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          if (vehicle.recallCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, color: AppTheme.accentOrange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${vehicle.recallCount} Active Recall${vehicle.recallCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedContent(VinVehicleDetails? vehicle, VinCrossCheck? crossCheck) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(color: Color(0xFF2C2C2E), height: 1),
          const SizedBox(height: 16),

          // Vehicle Overview
          _buildSection('VEHICLE OVERVIEW', [
            if (vehicle != null) ...[
              _buildDetailRow('Make', vehicle.make),
              _buildDetailRow('Model', vehicle.model),
              _buildDetailRow('Year', vehicle.year?.toString()),
              _buildDetailRow('Trim', vehicle.trim),
              _buildDetailRow('Body Type', vehicle.bodyType),
              _buildDetailRow('Vehicle Type', vehicle.vehicleType),
            ],
          ]),

          const SizedBox(height: 16),

          // Powertrain
          _buildSection('POWERTRAIN', [
            if (vehicle != null) ...[
              _buildDetailRow('Engine', vehicle.engine),
              _buildDetailRow('Transmission', vehicle.transmission),
              _buildDetailRow('Drivetrain', vehicle.drivetrain),
              _buildDetailRow('Fuel Type', vehicle.fuelType),
            ],
          ]),

          // Recalls
          if (vehicle != null && vehicle.recalls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              'RECALLS (${vehicle.recallCount})',
              vehicle.recalls.map((recall) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recall['component'] ?? 'Component',
                        style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (recall['summary'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          recall['summary'],
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              headerColor: AppTheme.accentOrange,
            ),
          ],

          // Cross-check
          if (crossCheck != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              'CONTRACT VERIFICATION',
              [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: crossCheck.mismatchDetected
                        ? AppTheme.accentRed.withOpacity(0.1)
                        : AppTheme.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: crossCheck.mismatchDetected
                          ? AppTheme.accentRed.withOpacity(0.3)
                          : AppTheme.accentGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        crossCheck.mismatchDetected ? Icons.warning : Icons.check_circle,
                        color: crossCheck.mismatchDetected ? AppTheme.accentRed : AppTheme.accentGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          crossCheck.mismatchDetected
                              ? 'Mismatch detected! Verify vehicle details.'
                              : 'Vehicle data matches contract.',
                          style: TextStyle(
                            color: crossCheck.mismatchDetected ? AppTheme.accentRed : AppTheme.accentGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (crossCheck.mismatchDetected) ...[
                  const SizedBox(height: 8),
                  ...crossCheck.mismatchDetails.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppTheme.textSecondary)),
                          Expanded(
                            child: Text(
                              detail,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              headerColor: crossCheck.mismatchDetected ? AppTheme.accentRed : AppTheme.accentGreen,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {Color headerColor = AppTheme.textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: headerColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
          Flexible(
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
