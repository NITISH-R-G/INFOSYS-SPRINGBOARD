import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import '../models/contract.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class DealerDashboardScreen extends StatefulWidget {
  const DealerDashboardScreen({super.key});

  @override
  State<DealerDashboardScreen> createState() => _DealerDashboardScreenState();
}

class _DealerDashboardScreenState extends State<DealerDashboardScreen> {
  List<Contract> _activeDeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    // In a real app, we'd filter by dealer_id
    // For now, show all contracts that are 'negotiating' or created
    try {
      final data = await ApiService.getContracts();
      if (mounted) {
        setState(() {
          _activeDeals = data.map((e) => Contract.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer Portal'),
        automaticallyImplyLeading: false, // Hide back button if it's a main tab
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Provider.of<AuthService>(context, listen: false).logout();
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                Navigator.pushNamed(context, '/dealer/offer-builder'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activeDeals.length,
              itemBuilder: (context, index) {
                final deal = _activeDeals[index];
                return _buildDealCard(deal);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/dealer/offer-builder'),
        label: const Text('New Offer'),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }

  Widget _buildDealCard(Contract deal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'ID: ${deal.id.substring(0, 8)}...',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(deal.status),
                ],
              ),
              const Divider(color: AppTheme.glassBorder, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    'Fairness',
                    '${deal.analysis?.fairnessScore ?? "-"}',
                  ),
                  _buildStat('Type', deal.analysis?.contractType ?? 'Unknown'),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Dealer negotiation view
                      Navigator.pushNamed(context, '/contract/${deal.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen.withOpacity(0.2),
                      foregroundColor: AppTheme.accentGreen,
                      elevation: 0,
                    ),
                    child: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = AppTheme.accentBlue;
    if (status == 'pending') color = AppTheme.accentOrange;
    if (status == 'reviewed') color = AppTheme.accentBlue;
    if (status == 'accepted') color = AppTheme.accentGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
