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

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  Map<String, dynamic>? _report;
  bool _loading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _loadReport();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    try {
      final data = await _api.getWeeklyReport(user.username);
      if (mounted) {
        setState(() {
          _report = data;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? _buildLoading()
          : RefreshIndicator(
              onRefresh: _loadReport,
              color: AppTheme.accentPink,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildSuperPowersSection()),
                  if (_report != null && _report!['subjects'] != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Row(
                          children: [
                            const Text('📊 ', style: TextStyle(fontSize: 20)),
                            Text('Subject Performance',
                                style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final s = (_report!['subjects'] as List)[i]
                                as Map<String, dynamic>;
                            return _buildSubjectPerf(s, i);
                          },
                          childCount:
                              (_report!['subjects'] as List).length,
                        ),
                      ),
                    ),
                  ],
                  if (_report != null && _report!['behaviour'] != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Row(
                          children: [
                            const Text('🧠 ', style: TextStyle(fontSize: 20)),
                            Text('Behaviour Insights',
                                style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final entries = (_report!['behaviour']
                                    as Map<String, dynamic>)
                                .entries
                                .toList();
                            return _buildBehaviourCard(
                                entries[i].key, entries[i].value, i);
                          },
                          childCount:
                              (_report!['behaviour'] as Map).length,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6EAB), Color(0xFF6C3CE1)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💪 Your Report',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Nunito',
              )),
          Text('See how awesome you are this week!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('📅 Weekly Overview',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperPowersSection() {
    final stats = [
      {
        'emoji': '🕑',
        'label': 'Study Time',
        'value':
            '${_report?['total_study_time'] ?? '—'} min',
        'gradient': const LinearGradient(
            colors: [Color(0xFF6C3CE1), Color(0xFF8B5CF6)]),
      },
      {
        'emoji': '💬',
        'label': 'Queries',
        'value': '${_report?['total_queries'] ?? '—'}',
        'gradient': const LinearGradient(
            colors: [Color(0xFFFF9F43), Color(0xFFFFD93D)]),
      },
      {
        'emoji': '🎯',
        'label': 'Accuracy',
        'value': '${_report?['accuracy'] ?? '—'}%',
        'gradient': const LinearGradient(
            colors: [Color(0xFF6BCB77), Color(0xFF4ECDC4)]),
      },
      {
        'emoji': '🔥',
        'label': 'Streak',
        'value': '${_report?['streak'] ?? '—'} days',
        'gradient': const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF6EAB)]),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡ ', style: TextStyle(fontSize: 20)),
              Text('Your Superpowers',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: stats.length,
            itemBuilder: (context, i) {
              final s = stats[i];
              return Container(
                decoration: BoxDecoration(
                  gradient: s['gradient'] as LinearGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: (s['gradient'] as LinearGradient)
                          .colors
                          .first
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s['emoji'] as String,
                        style: const TextStyle(fontSize: 28)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['value'] as String,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                            )),
                        Text(s['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerf(Map<String, dynamic> subject, int index) {
    final score = (subject['score'] as num? ?? 0).toDouble();
    final name = subject['name'] as String? ?? 'Subject';
    final gradient = AppTheme.subjectGradient(name);
    final emoji = AppTheme.subjectEmoji(name);
    final color = gradient.colors.first;
    final isPassing = score >= 50;

    return AnimatedBuilder(
      animation: _animController,
      builder: (_, child) {
        final t = ((_animController.value - index * 0.1).clamp(0.0, 1.0));
        return Opacity(
            opacity: t,
            child:
                Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                            color: Color(0xFF1A0A3E),
                          )),
                      Text(isPassing ? 'Great work! 🌟' : 'Keep practicing! 💪',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPassing
                                ? AppTheme.accentMint
                                : AppTheme.accentOrange,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${score.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      )),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (_, __) => LinearProgressIndicator(
                  value: score / 100 * _animController.value,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviourCard(String label, dynamic value, int index) {
    final icons = {
      'attentiveness': ('👀', AppTheme.primary),
      'participation': ('🙋', AppTheme.accentCyan),
      'completion_rate': ('✅', AppTheme.accentMint),
      'consistency': ('🔄', AppTheme.accentOrange),
    };

    final entry = icons[label.toLowerCase()] ??
        ('🧠', AppTheme.accentPink);
    final emoji = entry.$1;
    final color = entry.$2;
    final numVal = value is num ? value.toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((w) => w.isNotEmpty
                      ? '${w[0].toUpperCase()}${w.substring(1)}'
                      : '')
                  .join(' '),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
                color: Color(0xFF1A0A3E),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: numVal >= 50
                      ? [AppTheme.accentMint, AppTheme.accentCyan]
                      : [AppTheme.accentOrange, AppTheme.accentYellow]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontSize: 14,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFFF6EAB), Color(0xFF6C3CE1)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.accentPink),
                SizedBox(height: 16),
                Text('Loading your progress... 💪',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
