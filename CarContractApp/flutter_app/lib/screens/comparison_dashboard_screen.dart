import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/contract.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

/// Comparison Dashboard Screen (Gap 12 & 19)
/// Displays side-by-side comparison of car lease/loan offers with
/// interactive charts and Liquid Glass aesthetic.
class ComparisonDashboardScreen extends StatefulWidget {
  final List<String>? contractIds;
  const ComparisonDashboardScreen({super.key, this.contractIds});

  @override
  State<ComparisonDashboardScreen> createState() =>
      _ComparisonDashboardScreenState();
}

class _ComparisonDashboardScreenState extends State<ComparisonDashboardScreen>
    with TickerProviderStateMixin {
  List<Contract> _contracts = [];
  Map<String, dynamic>? _comparisonData;
  final Set<int> _selectedIndices = {};
  bool _isLoading = true;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    // We expect the contractIds to be passed via Navigator arguments in the route generator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as List<String>?;
      _loadContracts(args ?? widget.contractIds);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadContracts(List<String>? initialIds) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (initialIds != null && initialIds.isNotEmpty) {
        // Fetch detailed comparison data from backend using Gap 4 API
        final compData = await ApiService.compareContracts(initialIds);
        _comparisonData = compData;

        // Also load the full contract details for these IDs so we can render the existing UI
        // In a real app we might avoid this double-fetch, but for this demo we'll load them
        // one-by-one or rely on the cached list. We'll fetch all and filter.
        final allData = await ApiService.getContracts();
        final allContracts = (allData as List)
            .map((j) => Contract.fromJson(j))
            .toList();

        final analyzed = allContracts
            .where((c) => initialIds.contains(c.id))
            .toList();

        if (mounted) {
          setState(() {
            _contracts = analyzed;
            _isLoading = false;
            // Select all by default when coming from dashboard
            _selectedIndices.addAll(List.generate(analyzed.length, (i) => i));
          });
          _animController.forward();
        }
      } else {
        // Fallback: If no IDs provided, just load all analyzed contracts (legacy behavior)
        final data = await ApiService.getContracts();
        if (mounted) {
          final analyzed = (data as List)
              .map((j) => Contract.fromJson(j))
              .where((c) => c.analysis?.fairnessScore != null)
              .toList();
          setState(() {
            _contracts = analyzed;
            _isLoading = false;
            if (analyzed.length >= 2) {
              _selectedIndices.addAll({0, 1});
            } else if (analyzed.isNotEmpty) {
              _selectedIndices.add(0);
            }
          });
          _animController.forward();
        }
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

  List<Contract> get _selected =>
      _selectedIndices.map((i) => _contracts[i]).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accentGreen),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.accentRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading contracts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Contract selector chips
            SliverToBoxAdapter(child: _buildContractSelector()),
            // Summary metrics
            if (_selected.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSummaryMetrics()),
              // Charts section
              if (_selected.length >= 2) ...[
                SliverToBoxAdapter(child: _buildChartSection()),
                SliverToBoxAdapter(child: _buildRiskComparison()),
              ],
              // Detailed comparison table
              SliverToBoxAdapter(child: _buildDetailedTable()),
              // Best deal recommendation
              if (_selected.length >= 2)
                SliverToBoxAdapter(child: _buildRecommendation()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.background.withOpacity(0.85),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Comparison Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_selected.length >= 2)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _animController.reset();
              _animController.forward();
            },
          ),
      ],
    );
  }

  Widget _buildContractSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT CONTRACTS TO COMPARE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _contracts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final c = _contracts[i];
                final selected = _selectedIndices.contains(i);
                return FilterChip(
                  selected: selected,
                  label: Text(
                    c.title.length > 20
                        ? '${c.title.substring(0, 20)}…'
                        : c.title,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.background
                          : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  avatar: selected
                      ? const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.background,
                        )
                      : null,
                  selectedColor: AppTheme.accentGreen,
                  backgroundColor: AppTheme.surface,
                  side: BorderSide(
                    color: selected
                        ? AppTheme.accentGreen
                        : AppTheme.glassBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedIndices.add(i);
                      } else {
                        _selectedIndices.remove(i);
                      }
                    });
                    if (_selected.length >= 2) {
                      _animController.reset();
                      _animController.forward();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: _selected.map((c) {
            final score = c.analysis?.fairnessScore ?? 0;
            final apr = c.analysis?.slaData?.apr;
            final monthly = c.analysis?.slaData?.monthlyPayment;
            return Expanded(
              child: GlassCard(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title.length > 16
                          ? '${c.title.substring(0, 16)}…'
                          : c.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _metricRow(
                      'Fairness',
                      '$score/100',
                      _scoreColor(score),
                      Icons.shield_outlined,
                    ),
                    const SizedBox(height: 8),
                    _metricRow(
                      'APR',
                      apr != null ? '${apr.toStringAsFixed(1)}%' : 'N/A',
                      apr != null && apr <= 6
                          ? AppTheme.accentGreen
                          : AppTheme.accentOrange,
                      Icons.percent,
                    ),
                    const SizedBox(height: 8),
                    _metricRow(
                      'Monthly',
                      monthly != null
                          ? '\$${monthly.toStringAsFixed(0)}'
                          : 'N/A',
                      AppTheme.accentBlue,
                      Icons.payments_outlined,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: AppTheme.accentBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Key Metrics Comparison',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _BarChartPainter(
                    contracts: _selected,
                    animation: _fadeAnim.value,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Legend
              Wrap(
                spacing: 16,
                children: _selected.asMap().entries.map((entry) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _chartColors[entry.key % _chartColors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.value.title.length > 18
                            ? '${entry.value.title.substring(0, 18)}…'
                            : entry.value.title,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskComparison() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: AppTheme.glowPurple,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Risk Overview',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._selected.map((c) {
                final score = c.analysis?.fairnessScore ?? 0;
                final flags = c.analysis?.redFlags.length ?? 0;
                final riskLevel = score >= 80
                    ? 'Low'
                    : score >= 60
                    ? 'Medium'
                    : 'High';
                final riskColor = score >= 80
                    ? AppTheme.accentGreen
                    : score >= 60
                    ? AppTheme.accentOrange
                    : AppTheme.accentRed;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          c.title.length > 20
                              ? '${c.title.substring(0, 20)}…'
                              : c.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: riskColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          '$riskLevel Risk',
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flag_rounded,
                              color: AppTheme.accentRed,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$flags flags',
                              style: const TextStyle(
                                color: AppTheme.accentRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTable() {
    final terms = [
      ('Monthly Payment', (SlaData? s) => s?.monthlyPayment, r'$', ''),
      ('Down Payment', (SlaData? s) => s?.downPayment, r'$', ''),
      ('APR', (SlaData? s) => s?.apr, '', '%'),
      ('Term', (SlaData? s) => s?.termMonths?.toDouble(), '', ' mo'),
      ('Mileage Limit', (SlaData? s) => s?.mileageLimit?.toDouble(), '', ' mi'),
      ('Buyout Price', (SlaData? s) => s?.buyoutPrice, r'$', ''),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.table_chart_rounded,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Detailed Breakdown',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Header
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Metric',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ..._selected.map(
                  (c) => Expanded(
                    child: Text(
                      c.title.length > 12
                          ? '${c.title.substring(0, 12)}…'
                          : c.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.glassBorder, height: 20),
            // Rows
            for (final (label, getter, prefix, suffix) in terms) ...[
              _buildTableRow(label, prefix, suffix, getter),
              if (label != terms.last.$1)
                const Divider(color: AppTheme.glassBorder, height: 16),
            ],
            const Divider(color: AppTheme.glassBorder, height: 20),
            // Fairness score row
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Fairness Score',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ..._selected.map((c) {
                  final score = c.analysis?.fairnessScore ?? 0;
                  return Expanded(
                    child: Text(
                      '$score/100',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _scoreColor(score),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(
    String label,
    String prefix,
    String suffix,
    double? Function(SlaData?) getter,
  ) {
    // Find the best (lowest for costs, highest for mileage/term) value
    final values = _selected.map((c) => getter(c.analysis?.slaData)).toList();
    final nonNull = values.whereType<double>().toList();

    // Lower is better for payments/APR, higher for mileage/term
    final lowerBetter = label != 'Mileage Limit' && label != 'Term';
    double? bestVal;
    if (nonNull.isNotEmpty) {
      bestVal = lowerBetter
          ? nonNull.reduce(math.min)
          : nonNull.reduce(math.max);
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
        ...values.asMap().entries.map((entry) {
          final val = entry.value;
          final isBest =
              val != null &&
              bestVal != null &&
              val == bestVal &&
              nonNull.length > 1;
          final formatted = val != null
              ? '$prefix${val.toStringAsFixed(label == 'APR' ? 1 : 0)}$suffix'
              : 'N/A';

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: isBest
                  ? BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                formatted,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isBest ? AppTheme.accentGreen : AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendation() {
    final best = _selected.reduce((a, b) {
      final sa = a.analysis?.fairnessScore ?? 0;
      final sb = b.analysis?.fairnessScore ?? 0;
      return sa > sb ? a : b;
    });
    final bestScore = best.analysis?.fairnessScore ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.glassBlurStandard,
            sigmaY: AppTheme.glassBlurStandard,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentGreen.withOpacity(0.12),
                  AppTheme.glowBlue.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppTheme.accentGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Recommendation',
                        style: TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _comparisonData != null
                            ? 'AI Insights Available'
                            : '"${best.title}" is the strongest offer',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _comparisonData != null
                            ? _comparisonData!['recommendation'] ??
                                  'Analysis complete.'
                            : 'With a fairness score of $bestScore/100, this contract offers the most competitive terms overall. '
                                  '${bestScore >= 80 ? "It meets or exceeds industry benchmarks." : "Consider negotiating the flagged terms before signing."}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.accentGreen;
    if (score >= 60) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  static const _chartColors = [
    Color(0xFF0A84FF),
    Color(0xFF30D158),
    Color(0xFFBF5AF2),
    Color(0xFFFF9F0A),
  ];
}

// ==================== Custom Bar Chart Painter ====================

class _BarChartPainter extends CustomPainter {
  final List<Contract> contracts;
  final double animation;

  _BarChartPainter({required this.contracts, required this.animation});

  static const _colors = [
    Color(0xFF0A84FF),
    Color(0xFF30D158),
    Color(0xFFBF5AF2),
    Color(0xFFFF9F0A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (contracts.isEmpty) return;

    final metrics = ['Fairness', 'APR×10', 'Monthly÷100'];
    final groupCount = metrics.length;
    final barCount = contracts.length;
    final groupWidth = size.width / groupCount;
    final barWidth = math.min(28.0, (groupWidth - 30) / barCount);
    final maxVal = 100.0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Grid labels
      final labelText = TextPainter(
        text: TextSpan(
          text: '${(maxVal * i / 4).toInt()}',
          style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      labelText.layout();
      labelText.paint(canvas, Offset(-2, y - labelText.height - 2));
    }

    // Draw bars for each metric group
    for (int g = 0; g < groupCount; g++) {
      final groupCenterX = groupWidth * g + groupWidth / 2;
      final totalBarsWidth = barWidth * barCount + (barCount - 1) * 3;
      final startX = groupCenterX - totalBarsWidth / 2;

      // Metric label
      final label = TextPainter(
        text: TextSpan(
          text: metrics[g],
          style: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      label.paint(
        canvas,
        Offset(groupCenterX - label.width / 2, size.height + 4),
      );

      for (int b = 0; b < barCount; b++) {
        final c = contracts[b];
        double value = 0;
        switch (g) {
          case 0:
            value = (c.analysis?.fairnessScore ?? 0).toDouble();
            break;
          case 1:
            value = math.min(100, (c.analysis?.slaData?.apr ?? 0) * 10);
            break;
          case 2:
            value = math.min(
              100,
              (c.analysis?.slaData?.monthlyPayment ?? 0) / 10,
            );
            break;
        }

        final barHeight = (value / maxVal) * size.height * animation;
        final x = startX + b * (barWidth + 3);
        final y = size.height - barHeight;

        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        );

        // Gradient fill
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _colors[b % _colors.length],
              _colors[b % _colors.length].withOpacity(0.5),
            ],
          ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

        canvas.drawRRect(barRect, barPaint);

        // Value label on top
        if (animation > 0.5) {
          String valStr;
          switch (g) {
            case 0:
              valStr = '${value.toInt()}';
              break;
            case 1:
              valStr = '${(value / 10).toStringAsFixed(1)}%';
              break;
            default:
              valStr = '\$${(value * 10).toInt()}';
          }
          final valLabel = TextPainter(
            text: TextSpan(
              text: valStr,
              style: TextStyle(
                color: _colors[b % _colors.length],
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          valLabel.layout();
          valLabel.paint(
            canvas,
            Offset(
              x + barWidth / 2 - valLabel.width / 2,
              y - valLabel.height - 2,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.contracts != contracts;
}
