import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    try {
      final data = await _api.getWeeklyReport(user.username);
      if (mounted) setState(() { _report = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('No report data'))
              : RefreshIndicator(
                  onRefresh: _loadReport,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Overview', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _statCard('Study Time', '${_report!['total_study_time'] ?? '0'} min', Icons.timer, AppTheme.primary),
                            const SizedBox(width: 12),
                            _statCard('Queries', '${_report!['total_queries'] ?? '0'}', Icons.chat, AppTheme.warning),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard('Accuracy', '${_report!['accuracy'] ?? '0'}%', Icons.check_circle, AppTheme.success),
                            const SizedBox(width: 12),
                            _statCard('Streak', '${_report!['streak'] ?? '0'} days', Icons.local_fire_department, AppTheme.error),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('Subject Performance', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        if (_report!['subjects'] != null)
                          ...(_report!['subjects'] as List).map((s) => _subjectPerformance(s)),
                        const SizedBox(height: 24),
                        Text('Behavioural Assessment', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        if (_report!['behaviour'] != null)
                          ...(_report!['behaviour'] as Map<String, dynamic>).entries.map((e) => _behaviourTile(e.key, e.value)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectPerformance(Map<String, dynamic> subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(subject['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${subject['score'] ?? 0}%', style: TextStyle(color: (subject['score'] ?? 0) >= 50 ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ((subject['score'] ?? 0) as num) / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation((subject['score'] ?? 0) >= 50 ? AppTheme.success : AppTheme.error),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _behaviourTile(String label, dynamic value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_behaviourIcon(label), color: AppTheme.primary),
        title: Text(label.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (value is num && value >= 50) ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${value ?? 0}', style: TextStyle(fontWeight: FontWeight.w600, color: (value is num && value >= 50) ? AppTheme.success : AppTheme.warning)),
        ),
      ),
    );
  }

  IconData _behaviourIcon(String label) {
    switch (label.toLowerCase()) {
      case 'attentiveness': return Icons.visibility;
      case 'participation': return Icons.how_to_vote;
      case 'completion_rate': return Icons.checklist;
      case 'consistency': return Icons.repeat;
      default: return Icons.analytics;
    }
  }
}
