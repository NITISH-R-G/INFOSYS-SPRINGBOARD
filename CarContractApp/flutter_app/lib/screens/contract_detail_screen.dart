import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/contract.dart';
import '../widgets/vin_info_card.dart';
import '../animations/animations.dart';
import '../widgets/market_value_card.dart';
import '../widgets/analysis_section_card.dart';
import '../widgets/sla_summary_card.dart';
import '../widgets/fair_price_card.dart';
import '../widgets/fairness_score_card.dart';
import '../models/valuation_model.dart';
import '../models/fairness_model.dart';
import 'risk_strategy_screen.dart';
import 'dealer_chat_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dealer_forwarding_dialog.dart';

class ContractDetailScreen extends StatefulWidget {
  final String contractId;

  const ContractDetailScreen({super.key, required this.contractId});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen>
    with TickerProviderStateMixin {
  Contract? _contract;
  VehicleValuation? _valuation;
  FairnessScore? _fairnessData;
  bool _isLoading = true;
  String? _error;

  // Controllers
  late ScrollController _scrollController;
  late AnimationController _contentController;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadContract();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadContract() async {
    try {
      final data = await ApiService.getContract(widget.contractId);
      if (mounted) {
        setState(() {
          _contract = Contract.fromJson(data);

          if (_contract!.status == 'analyzing') {
            _isLoading = true;
            _startPolling();
          } else {
            _isLoading = false;
            _pollingTimer?.cancel();
            _contentController.forward();
            _fetchAdvancedMetrics(); // Fetch additional intelligence
          }
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

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadContract();
    });
  }

  Future<void> _fetchAdvancedMetrics() async {
    if (_contract?.analysis?.slaData == null) return;
    final sla = _contract!.analysis!.slaData!;

    // Fallback VIN for testing if none is provided via OCR
    final vinToUse =
        _contract?.vinLookup?.vinNumber ??
        '1G1RC6E45BU12345'; // Dummy VIN as fallback

    try {
      final valuation = await ApiService.fetchVehicleValuation(vinToUse);

      final contractPrice =
          sla.buyoutPrice ??
          ((sla.monthlyPayment ?? 0) * (sla.termMonths ?? 0) +
              (sla.downPayment ?? 0));

      if (contractPrice > 0) {
        final fairness = await ApiService.calculateFairness(
          contractPrice: contractPrice,
          marketAverage: valuation.metrics.marketAverage,
          apr: sla.apr,
          fees: 500.0, // Assuming a hardcoded 500 for fees if not parsed
        );
        if (mounted) {
          setState(() {
            _valuation = valuation;
            _fairnessData = fairness;
          });
        }
      }
    } catch (e) {
      // It's okay if advanced metrics fail, we just won't show them
      print("Advanced metrics fetch failed: $e");
    }
  }

  String _formatCurrency(Object? value, String currencyCode) {
    if (value == null || value == 'Not Mentioned') return 'N/A';
    // If it's already a formatted string or text formula, return as is
    if (value is String &&
        (value.contains('₹') ||
            value.contains('₹') ||
            value.contains('Formula'))) {
      return value;
    }

    // Try to parse double if it's a number-like string
    double? val;
    if (value is num) {
      val = value.toDouble();
    } else if (value is String) {
      val = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
      // If parsing fails, just return the original string (e.g. "TBD")
      if (val == null) return value;
    }

    if (val == null) return 'N/A';

    final format = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return format.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDealer = authProvider.role?.toString().contains('dealer') == true;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_dealer',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DealerChatScreen(contractId: widget.contractId),
          ),
        ),
        backgroundColor: AppTheme.accentBlue,
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(isDealer ? 'Message Client' : 'Message Dealer'),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: _isLoading
                    ? _buildLoading()
                    : _error != null
                    ? _buildError()
                    : _buildContent(),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 80),
              ), // Increased padding for FAB
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_contract != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String result) async {
              if (result == 'forward') {
                DealerForwardingDialog.show(context, widget.contractId);
                return;
              }
              try {
                await ApiService.updateContractStatus(
                  widget.contractId,
                  result,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status updated to $result')),
                  );
                  _loadContract();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update status: $e')),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'review',
                child: Text('Mark as In Review'),
              ),
              const PopupMenuItem<String>(
                value: 'counter_offer',
                child: Text('Mark as Counter Offer Made'),
              ),
              const PopupMenuItem<String>(
                value: 'finalized',
                child: Text('Mark as Finalized'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'forward',
                child: Row(
                  children: [
                    Icon(
                      Icons.forward_to_inbox,
                      size: 18,
                      color: AppTheme.glowPurple,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Forward to Dealer',
                      style: TextStyle(color: AppTheme.glowPurple),
                    ),
                  ],
                ),
              ),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.analytics_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RiskStrategyScreen(contractId: widget.contractId),
            ),
          ),
        ),
      ],
      flexibleSpace: ScrollReactiveGlassHeader(
        scrollController: _scrollController,
        height: 100,
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
          title: Text(
            _contract?.title ?? 'Contract Details',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.accentGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analyzing contract with AI...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Looking for SLA terms and hidden clauses',
              style: TextStyle(
                color: AppTheme.textMuted.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: AppTheme.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadContract,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final analysis = _contract!.analysis;
    if (analysis == null) {
      return const Center(child: Text('No analysis available'));
    }

    final sla = analysis.slaData;
    final currency = sla?.currencyCode ?? 'INR';
    final detailed = analysis.detailedAnalysis;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If advanced metrics are loaded, show the FairnessScoreCard
          if (_fairnessData != null)
            AnimatedEntrance(
              delay: const Duration(milliseconds: 100),
              child: FairnessScoreCard(fairnessScore: _fairnessData!),
            )
          else
            // Legacy Fairness Score Card with Hero
            AnimatedEntrance(
              delay: const Duration(milliseconds: 100),
              child: LiquidGlassContainer(
                heroTag: 'contract_${_contract!.id}',
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildAnimatedScoreRing(analysis.fairnessScore, 140),
                    const SizedBox(height: 16),
                    Text(
                      analysis.fairnessExplanation ?? 'Contract analyzed',
                      style: const TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // If advanced metrics are loaded, show FairPriceCard
          if (_valuation != null && sla != null)
            AnimatedEntrance(
              delay: const Duration(milliseconds: 150),
              child: FairPriceCard(
                contractPrice:
                    sla.buyoutPrice ??
                    ((sla.monthlyPayment ?? 0) * (sla.termMonths ?? 0) +
                        (sla.downPayment ?? 0)),
                marketAverage: _valuation!.metrics.marketAverage,
                fairRangeLow: _valuation!.metrics.fairRangeLow,
                fairRangeHigh: _valuation!.metrics.fairRangeHigh,
              ),
            ),
          if (_valuation != null && sla != null) const SizedBox(height: 24),

          // SLA Summary Card
          if (sla != null)
            AnimatedEntrance(
              delay: const Duration(milliseconds: 200),
              child: SlaSummaryCard(slaData: sla),
            ),
          if (sla != null) const SizedBox(height: 24),

          // VIN Info Card
          if (_contract!.vinLookup != null)
            AnimatedEntrance(
              delay: const Duration(milliseconds: 300),
              slideFrom: const Offset(0, 50),
              child: VinInfoCard(vinLookup: _contract!.vinLookup!),
            ),
          if (_contract!.vinLookup != null) const SizedBox(height: 24),

          // Market Value Card
          if (sla != null && sla.marketValue != null)
            AnimatedEntrance(
              delay: const Duration(milliseconds: 250),
              slideFrom: const Offset(50, 0),
              child: MarketValueCard(
                contractPrice:
                    sla.buyoutPrice ??
                    (sla.monthlyPayment! * sla.termMonths! +
                        (sla.downPayment ?? 0)),
                estimatedValue: sla.marketValue!,
                highValue: sla.marketValueHigh,
                lowValue: sla.marketValueLow,
                confidence: sla.marketConfidence ?? 'medium',
              ),
            ),
          if (sla != null && sla.marketValue != null)
            const SizedBox(height: 24),

          // Detailed 12-Section Analysis
          if (detailed != null) ...[
            AnimatedEntrance(
              delay: const Duration(milliseconds: 300),
              child: const Text(
                'COMPREHENSIVE ANALYSIS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            StaggeredList(
              staggerDelay: const Duration(milliseconds: 100),
              children: _buildDetailedSections(detailed, currency),
            ),
          ]
          // Legacy View (if no detailed analysis)
          else if (sla != null) ...[
            AnimatedEntrance(
              delay: const Duration(milliseconds: 300),
              child: const Text(
                'KEY TERMS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 400),
              child: LiquidGlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTermRow(
                      'APR',
                      '${sla.apr?.toStringAsFixed(2) ?? 'N/A'}%',
                      0,
                    ),
                    _buildTermRow(
                      'Term',
                      '${sla.termMonths ?? 'N/A'} months',
                      1,
                    ),
                    _buildTermRow(
                      'Monthly Payment',
                      _formatCurrency(sla.monthlyPayment, currency),
                      2,
                    ),
                    _buildTermRow(
                      'Down Payment',
                      _formatCurrency(sla.downPayment, currency),
                      3,
                    ),
                    _buildTermRow(
                      'Mileage Limit',
                      '${sla.mileageLimit ?? 'N/A'} mi/year',
                      4,
                    ),
                    if (sla.buyoutPrice != null)
                      _buildTermRow(
                        'Buyout Price',
                        _formatCurrency(sla.buyoutPrice, currency),
                        5,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Red Flags (Legacy)
            if (analysis.redFlags.isNotEmpty) ...[
              AnimatedEntrance(
                delay: const Duration(milliseconds: 500),
                child: const Text(
                  'RED FLAGS',
                  style: TextStyle(
                    color: AppTheme.accentRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StaggeredList(
                staggerDelay: const Duration(milliseconds: 100),
                children: analysis.redFlags
                    .map((flag) => _buildRedFlagCard(flag))
                    .toList(),
              ),
            ],
          ],

          const SizedBox(height: 24),
          if (detailed != null && detailed.missingSections.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "⚠️ Missing Sections",
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...detailed.missingSections.map(
                    (s) => Text(
                      "• $s",
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailedSections(
    DetailedAnalysis detailed,
    String currency,
  ) {
    return [
      AnalysisSectionCard(
        title: '1. Vehicle Details',
        initiallyExpanded: true,
        details: {
          'Make': detailed.vehicleDetails.make,
          'Model': detailed.vehicleDetails.model,
          'Trim': detailed.vehicleDetails.variantTrim,
          'Year': detailed.vehicleDetails.manufacturingYear,
          'VIN': detailed.vehicleDetails.vin,
          'Condition': detailed.vehicleDetails.vehicleCondition,
        },
        risks: detailed.vehicleDetails.riskFlags,
      ),
      AnalysisSectionCard(
        title: '2. Lease Payment Terms',
        details: {
          'Monthly Payment': _formatCurrency(
            detailed.leasePaymentTerms.monthlyPaymentAmount,
            currency,
          ),
          'Down Payment': _formatCurrency(
            detailed.leasePaymentTerms.securityDeposit,
            currency,
          ),
          'Due Date': detailed.leasePaymentTerms.paymentDueDate,
          'Late Fees': detailed.leasePaymentTerms.latePaymentPenalties,
        },
        risks: detailed.leasePaymentTerms.riskFlags,
      ),
      AnalysisSectionCard(
        title: '3. Lease Duration',
        details: {
          'Start Date': detailed.leaseDuration.leaseStartDate,
          'End Date': detailed.leaseDuration.leaseEndDate,
          'Total Period': detailed.leaseDuration.totalLeasePeriod,
        },
        risks: detailed.leaseDuration.riskFlags,
      ),
      AnalysisSectionCard(
        title: '4. Mileage & Usage',
        details: {
          'Allowance': detailed.mileageUsageLimits.allowedMileageLimit,
          'Excess Charge': detailed.mileageUsageLimits.excessMileageCharges,
        },
        risks: detailed.mileageUsageLimits.riskFlags,
      ),
      AnalysisSectionCard(
        title: '5. Maintenance',
        details: {
          'Responsibility': detailed
              .maintenanceResponsibilities
              .regularMaintenanceResponsibility,
          'Repairs':
              detailed.maintenanceResponsibilities.repairCostResponsibility,
        },
        risks: detailed.maintenanceResponsibilities.riskFlags,
      ),
      AnalysisSectionCard(
        title: '6. Insurance',
        details: {
          'Required Type': detailed.insuranceRequirements.requiredInsuranceType,
          'Payment By':
              detailed.insuranceRequirements.insurancePaymentResponsibility,
        },
        risks: detailed.insuranceRequirements.riskFlags,
      ),
      AnalysisSectionCard(
        title: '7. Damage & Wear',
        details: {
          'Normal Wear':
              detailed.damageAndWearConditions.normalWearAndTearDefinition,
          'Excess Damage': detailed.damageAndWearConditions.excessDamageCharges,
        },
        risks: detailed.damageAndWearConditions.riskFlags,
      ),
      AnalysisSectionCard(
        title: '8. Early Termination',
        details: {
          'Allowed': detailed.earlyTerminationTerms.earlyTerminationAllowed,
          'Termination Fee': detailed.earlyTerminationTerms.terminationCharges,
        },
        risks: detailed.earlyTerminationTerms.riskFlags,
      ),
      AnalysisSectionCard(
        title: '9. Ownership',
        details: {
          'Owner': detailed.ownershipTerms.vehicleOwnershipHolder,
          'Purchase Option': detailed.ownershipTerms.endOfLeasePurchaseOption,
          'Purchase Price': _formatCurrency(
            detailed.ownershipTerms.purchasePriceOrFormula,
            currency,
          ),
        },
        risks: detailed.ownershipTerms.riskFlags,
      ),
      AnalysisSectionCard(
        title: '10. Usage Restrictions',
        details: {
          'Drivers': detailed.usageRestrictions.authorizedDrivers,
          'Geo Limits': detailed.usageRestrictions.geographicUsageRestrictions,
        },
        risks: detailed.usageRestrictions.riskFlags,
      ),
      AnalysisSectionCard(
        title: '11. Legal & Default',
        details: {
          'Default': detailed.defaultAndLegalClauses.defaultConditions,
          'Repossession': detailed.defaultAndLegalClauses.repossessionRights,
        },
        risks: detailed.defaultAndLegalClauses.riskFlags,
      ),
      AnalysisSectionCard(
        title: '12. End of Lease',
        details: {
          'Procedure': detailed.endOfLeaseProcess.returnProcedure,
          'Renewal': detailed.endOfLeaseProcess.renewalOptions,
        },
        risks: detailed.endOfLeaseProcess.riskFlags,
      ),
    ];
  }

  Widget _buildAnimatedScoreRing(int score, double size) {
    final scoreColor = score >= 80
        ? AppTheme.accentGreen
        : score >= 60
        ? AppTheme.accentOrange
        : AppTheme.accentRed;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: score / 100.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.glassBg,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (value * 100).toInt().toString(),
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Fairness',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: size * 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTermRow(String label, String value, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedFlagCard(RedFlag flag) {
    final riskColor = flag.riskLevel == 'high'
        ? AppTheme.accentRed
        : flag.riskLevel == 'medium'
        ? AppTheme.accentOrange
        : AppTheme.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: riskColor.withOpacity(0.05),
        borderColor: riskColor.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    flag.riskLevel.toUpperCase(),
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    flag.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (flag.plainExplanation != null) ...[
              const SizedBox(height: 8),
              Text(
                flag.plainExplanation!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            if (flag.suggestion != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppTheme.accentGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        flag.suggestion!,
                        style: const TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
