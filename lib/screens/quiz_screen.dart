import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<Subject> _subjects = [];
  bool _loading = true;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
    _loadData();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final subjects = await _api.getSubjects(board: 1, classId: 1, pub: 1);
      if (mounted) {
        setState(() {
          _subjects = subjects
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
              onRefresh: _loadData,
              color: AppTheme.accentMint,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildQuizTypeRow()),
                  if (_subjects.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Row(
                          children: [
                            const Text('📚 ', style: TextStyle(fontSize: 20)),
                            Text('Pick a Subject',
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) =>
                              _buildSubjectQuizCard(_subjects[i], i),
                          childCount: _subjects.length,
                        ),
                      ),
                    ),
                  ],
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
          colors: [Color(0xFF4ECDC4), Color(0xFF6BCB77)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏆 Quiz Time!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    )),
                Text('Test your knowledge & win stars! ⭐',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _badge('🥇 Weekly', AppTheme.accentYellow),
                    const SizedBox(width: 10),
                    _badge('⚡ Quick', Colors.white),
                  ],
                ),
              ],
            ),
          ),
          // Bouncing trophy
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _bounceAnim.value),
              child: child,
            ),
            child: const Text('🏆', style: TextStyle(fontSize: 56)),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          )),
    );
  }

  Widget _buildQuizTypeRow() {
    final types = [
      {'emoji': '🎯', 'label': '10 Qs', 'color': AppTheme.primary},
      {'emoji': '⚡', 'label': 'Speed', 'color': AppTheme.accentOrange},
      {'emoji': '🔥', 'label': 'Hard', 'color': AppTheme.error},
      {'emoji': '🌟', 'label': 'Mixed', 'color': AppTheme.accentPink},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡ ', style: TextStyle(fontSize: 20)),
              Text('Quiz Types',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: types.map((t) {
              final color = t['color'] as Color;
              return Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: color.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(t['emoji'] as String,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(t['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                              fontFamily: 'Nunito',
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectQuizCard(Subject subject, int index) {
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
                  Row(
                    children: [
                      const Text('⭐⭐⭐',
                          style: TextStyle(fontSize: 12)),
                      Text(' 10 questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontFamily: 'Nunito',
                          )),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Play ▶',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
            gradient: LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF6BCB77)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.accentMint),
                SizedBox(height: 16),
                Text('Loading quiz... 🏆',
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
