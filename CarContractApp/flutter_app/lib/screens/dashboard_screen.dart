import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/contract.dart';
import '../animations/animations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

/// ============================================================
/// DASHBOARD SCREEN
/// iOS 26 Liquid Glass with Scroll-Reactive Effects
/// ============================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<Contract> _contracts = [];
  bool _isLoading = true;
  String? _error;

  // Controllers
  late ScrollController _scrollController;
  late AnimationController _fabController;
  late AnimationController _listController;

  // Animations
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initAnimations();
    _loadContracts();
  }

  void _initAnimations() {
    // FAB entrance animation
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    // List stagger controller
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getContracts();
      setState(() {
        _contracts = data.map((e) => Contract.fromJson(e)).toList();
        _isLoading = false;
      });
      // Animate in
      _fabController.forward();
      _listController.forward();
    } on AuthExpiredException catch (_) {
      if (mounted) {
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).handleAuthExpired(context);
      }
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
      body: Stack(
        children: [
          // Main content with scroll-reactive header
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Scroll-reactive app bar
              _buildScrollReactiveAppBar(),

              // Content
              SliverToBoxAdapter(
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                    ? _buildError()
                    : _contracts.isEmpty
                    ? _buildEmpty()
                    : const SizedBox.shrink(),
              ),

              // Contract list
              if (!_isLoading && _error == null && _contracts.isNotEmpty)
                _buildContractList(),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),

          // Animated FAB
          Positioned(right: 20, bottom: 30, child: _buildAnimatedFAB()),
        ],
      ),
    );
  }

  Widget _buildScrollReactiveAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          final scrollOffset = _scrollController.hasClients
              ? _scrollController.offset.clamp(0.0, 80.0)
              : 0.0;
          final progress = scrollOffset / 80.0;
          final blur = 10.0 + (progress * 20.0);
          final opacity = 0.0 + (progress * 0.8);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.background.withOpacity(opacity),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.glassBorder.withOpacity(progress * 0.5),
                    ),
                  ),
                ),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: progress > 0.5 ? 1.0 : 0.0,
                    child: const Text(
                      'My Contracts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PhysicsTapButton(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/vin-lookup'),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.glassBorder,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.search,
                                    color: AppTheme.textPrimary,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              PhysicsTapButton(
                                onTap: () {
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  ).logout();
                                  Navigator.pushReplacementNamed(context, '/');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.accentRed.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.logout,
                                    color: AppTheme.accentRed,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Opacity(
                            opacity: 1.0 - progress,
                            child: const Text(
                              'My Contracts',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.glassBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.accentGreen),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading contracts...',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: AnimatedEntrance(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: AppTheme.accentRed,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GlowRippleButton(
                  onTap: _loadContracts,
                  glowColor: AppTheme.accentGreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: AnimatedEntrance(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.glassBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Icon(
                    Icons.folder_open_outlined,
                    size: 50,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No contracts yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your first car contract to get started',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContractList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final contract = _contracts[index];

          // Staggered animation
          final startTime = (index * 0.1).clamp(0.0, 0.5);
          final endTime = (startTime + 0.5).clamp(0.0, 1.0);

          return AnimatedBuilder(
            animation: _listController,
            builder: (context, child) {
              final animation = CurvedAnimation(
                parent: _listController,
                curve: Interval(startTime, endTime, curve: Curves.easeOutBack),
              );

              return Transform.translate(
                offset: Offset(0, 30 * (1 - animation.value)),
                child: Opacity(
                  opacity: animation.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * animation.value),
                    child: _buildContractCard(contract, index),
                  ),
                ),
              );
            },
          );
        }, childCount: _contracts.length),
      ),
    );
  }

  // Selection state
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _enterCompareMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      _selectedIds.add(id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select a second contract to compare')),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        if (_selectedIds.length < 2) {
          _selectedIds.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select exactly 2 contracts to compare'),
            ),
          );
        }
      }
    });
  }

  void _navigateToCompare() {
    if (_selectedIds.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select exactly 2 contracts to compare')),
      );
      return;
    }
    Navigator.pushNamed(context, '/compare', arguments: _selectedIds.toList());
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _confirmDelete(Contract contract) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Delete Contract',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to delete this contract? This action cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.accentRed),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteContract(contract.id);
    }
  }

  Future<void> _deleteContract(String contractId) async {
    try {
      await ApiService.deleteContract(contractId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract deleted successfully')),
        );
        _loadContracts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete contract: $e')),
        );
      }
    }
  }

  void _showContextualMenu(Contract contract) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              contract.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMenuOption(
              icon: Icons.open_in_new,
              title: 'View Analysis',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/contract/${contract.id}');
              },
            ),
            const SizedBox(height: 8),
            _buildMenuOption(
              icon: Icons.compare_arrows,
              title: 'Compare with another',
              onTap: () {
                Navigator.pop(context);
                _enterCompareMode(contract.id);
              },
            ),
            const SizedBox(height: 8),
            _buildMenuOption(
              icon: Icons.delete_outline,
              title: 'Delete Contract',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(contract);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.accentRed : AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDestructive
              ? AppTheme.accentRed.withOpacity(0.1)
              : AppTheme.glassBg,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(Contract contract, int index) {
    final hasAnalysis = contract.analysis != null;
    final score = contract.analysis?.fairnessScore ?? 0;
    final scoreColor = score >= 80
        ? AppTheme.accentGreen
        : score >= 60
        ? AppTheme.accentOrange
        : AppTheme.accentRed;

    final isSelected = _selectedIds.contains(contract.id);

    // Format timestamp
    String dateStr = 'Unknown Date';
    if (contract.createdAt != null) {
      dateStr = DateFormat('MMM dd, yyyy').format(contract.createdAt!);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(contract.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 30,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: AppTheme.surface,
                title: const Text(
                  'Delete Contract',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                content: const Text(
                  'Are you sure you want to delete this contract?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: AppTheme.accentRed),
                    ),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) async {
          _deleteContract(contract.id);
        },
        child: Hero(
          tag: 'contract_${contract.id}',
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentBlue.withOpacity(0.1)
                  : AppTheme.glassBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppTheme.accentBlue : AppTheme.glassBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onLongPress: () {
                  if (_isSelectionMode) {
                    _toggleSelection(contract.id);
                  } else {
                    _showContextualMenu(contract);
                  }
                },
                onTap: _isSelectionMode
                    ? () => _toggleSelection(contract.id)
                    : () => Navigator.pushNamed(
                        context,
                        '/contract/${contract.id}',
                      ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Identity: PDF Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.accentBlue.withOpacity(0.2),
                              AppTheme.accentBlue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppTheme.accentBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Metadata: Title, timestamp, and status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              contract.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasAnalysis
                                        ? AppTheme.accentGreen.withOpacity(0.1)
                                        : AppTheme.glassBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: hasAnalysis
                                          ? AppTheme.accentGreen.withOpacity(
                                              0.3,
                                            )
                                          : AppTheme.glassBorder,
                                    ),
                                  ),
                                  child: Text(
                                    contract.analysis?.contractType
                                            ?.toUpperCase() ??
                                        contract.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: hasAnalysis
                                          ? AppTheme.accentGreen
                                          : AppTheme.textMuted,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Score
                      if (contract.analysis != null)
                        _buildAnimatedScoreRing(score, scoreColor),

                      // Action Affordance (Chevron or Checkbox in selection mode)
                      const SizedBox(width: 12),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textMuted,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedScoreRing(int score, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: score / 100.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: AppTheme.glassBg,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFAB() {
    return AnimatedBuilder(
      animation: _fabScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScale.value,
          child: GlowRippleButton(
            onTap: _isSelectionMode
                ? _navigateToCompare
                : () => Navigator.pushNamed(context, '/upload'),
            glowColor: _isSelectionMode
                ? AppTheme.accentBlue
                : AppTheme.accentGreen,
            borderRadius: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: _isSelectionMode
                    ? const LinearGradient(
                        colors: [AppTheme.accentBlue, Color(0xFF0055DD)],
                      )
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isSelectionMode
                                ? AppTheme.accentBlue
                                : AppTheme.accentGreen)
                            .withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSelectionMode ? Icons.compare_arrows : Icons.add,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSelectionMode
                        ? 'Compare (${_selectedIds.length})'
                        : 'Upload',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
