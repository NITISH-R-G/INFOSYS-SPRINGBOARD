import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

/// Screen to display Audit Logs
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final logs = await ApiService.getAuditLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.accentRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load logs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(onPressed: _loadLogs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'No audit logs found.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return _buildLogCard(log);
        },
      ),
    );
  }

  Widget _buildLogCard(dynamic log) {
    final action = log['action'] ?? 'UNKNOWN_ACTION';
    final timestamp = log['timestamp'] ?? '';
    final details = log['details'] as Map<String, dynamic>? ?? {};
    final contractId = log['contract_id'];
    final userId = log['user_id'];

    IconData icon;
    Color iconColor;

    if (action.contains('STATUS')) {
      icon = Icons.sync_alt;
      iconColor = AppTheme.glowBlue;
    } else if (action.contains('UPLOAD')) {
      icon = Icons.upload_file;
      iconColor = AppTheme.accentGreen;
    } else if (action.contains('DELETE')) {
      icon = Icons.delete_outline;
      iconColor = AppTheme.accentRed;
    } else if (action.contains('FORWARD')) {
      icon = Icons.forward_to_inbox;
      iconColor = AppTheme.glowPurple;
    } else {
      icon = Icons.info_outline;
      iconColor = AppTheme.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          action,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (contractId != null)
                    Text(
                      'Contract ID: $contractId',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  if (userId != null)
                    Text(
                      'User ID: $userId',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (details.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        details.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(timestamp),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
