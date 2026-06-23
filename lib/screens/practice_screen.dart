import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _api = ApiService();
  List<Subject> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final data = await _api.getSubjects(board: 1, classId: 1, pub: 1);
      if (mounted) {
        setState(() {
          _subjects = data
              .whereType<Map<String, dynamic>>()
              .map((s) => Subject.fromJson(s))
              .toList();
          _loading = false;
        });
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
              onRefresh: _loadSubjects,
              color: AppTheme.accent,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildModeSection()),
                  if (_subjects.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Row(
                          children: [
                            const Text('📖 ', style: TextStyle(fontSize: 20)),
                            Text('Choose Subject',
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _subjectCard(_subjects[i], i),
                        childCount: _subjects.length,
                      ),
                    ),
                  ),
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
          colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎮 Practice',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Nunito',
              )),
          Text('Sharpen your skills & master topics!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerBadge('🎯 Daily Challenge', AppTheme.accentYellow),
              const SizedBox(width: 10),
              _headerBadge('⚡ Quick Practice', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          )),
    );
  }

  Widget _buildModeSection() {
    final modes = [
      {
        'emoji': '📝',
        'label': 'Summary',
        'sub': 'Review key points',
        'color': AppTheme.primary,
      },
      {
        'emoji': '🧠',
        'label': 'MCQ',
        'sub': 'Multiple choice',
        'color': AppTheme.accentOrange,
      },
      {
        'emoji': '🔢',
        'label': 'Numerical',
        'sub': 'Solve problems',
        'color': AppTheme.accentCyan,
      },
      {
        'emoji': '🎲',
        'label': 'Mixed',
        'sub': 'Random mix',
        'color': AppTheme.accentPink,
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
              Text('Practice Modes',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: modes.length,
            itemBuilder: (context, i) {
              final m = modes[i];
              final color = m['color'] as Color;
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: color.withValues(alpha: 0.25), width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Text(m['emoji'] as String,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: color,
                                  fontFamily: 'Nunito',
                                )),
                            Text(m['sub'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color.withValues(alpha: 0.7),
                                  fontFamily: 'Nunito',
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(Subject subject, int index) {
    final gradient = AppTheme.subjectGradient(subject.subjectName);
    final emoji = AppTheme.subjectEmoji(subject.subjectName);
    final color = gradient.colors.first;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/study', arguments: {
        'subject_id': subject.subjectId,
        'subject_name': subject.subjectName,
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.subjectName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                        color: Color(0xFF1A0A3E),
                      )),
                  Text('Tap to practice',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontFamily: 'Nunito',
                      )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Start ▶',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.accent),
                SizedBox(height: 16),
                Text('Loading practice... 🎮',
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
