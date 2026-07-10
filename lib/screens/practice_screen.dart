import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class PracticeScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const PracticeScreen({super.key, this.args});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _api = ApiService();
  List<Subject> _subjects = [];
  bool _loading = true;

  Subject? _activeSubject;
  String? _lessonName;
  String? _practiceText;
  bool _practiceLoading = false;
  String? _practiceError;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    final lesson = widget.args?['lesson_name'] as String?;
    final subjectName = widget.args?['subject_name'] as String?;
    if (lesson != null && subjectName != null) {
      _startPractice(lesson, subjectName);
    }
  }

  String _classNum() {
    final user = context.read<AuthProvider>().user;
    return (user?.userClass ?? '').replaceAll(RegExp(r'[^\d]'), '');
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

  Future<void> _startPractice(String lesson, String subjectName) async {
    setState(() {
      _activeSubject = Subject(subjectId: widget.args?['subject_id'] ?? 0, subjectName: subjectName);
      _lessonName = lesson;
      _practiceLoading = true;
      _practiceText = null;
      _practiceError = null;
    });
    try {
      final text = await _api.getPracticeQuestions(
        lessonName: lesson,
        numQuestions: 5,
        subject: subjectName,
        board: 'CBSE',
        lessonClass: _classNum().isNotEmpty ? _classNum() : null,
        publication: 'NCERT',
      );
      if (mounted) {
        setState(() {
          _practiceText = text;
          _practiceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _practiceError = e.toString();
          _practiceLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _activeSubject != null
          ? _buildSession()
          : (_loading
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
                )),
    );
  }

  Widget _buildSession() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _activeSubject = null),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎮 Practice',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Nunito')),
                      Text(_lessonName ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontFamily: 'Nunito')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: _practiceLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _practiceError != null
                    ? _errorCard(_practiceError!)
                    : _practiceText != null && _practiceText!.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: SelectableText(_practiceText!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(height: 1.6)),
                          )
                        : _errorCard('No practice questions generated.'),
          ),
        ),
        if (!_practiceLoading && _practiceText != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: ElevatedButton.icon(
                onPressed: () => _startPractice(_lessonName ?? _activeSubject!.subjectName, _activeSubject!.subjectName),
                icon: const Icon(Icons.refresh),
                label: const Text('Generate Again'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _errorCard(String msg) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

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
      {'emoji': '📝', 'label': 'Summary', 'sub': 'Review key points', 'color': AppTheme.primary},
      {'emoji': '🧠', 'label': 'MCQ', 'sub': 'Multiple choice', 'color': AppTheme.accentOrange},
      {'emoji': '🔢', 'label': 'Numerical', 'sub': 'Solve problems', 'color': AppTheme.accentCyan},
      {'emoji': '🎲', 'label': 'Mixed', 'sub': 'Random mix', 'color': AppTheme.accentPink},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡ ', style: TextStyle(fontSize: 20)),
              Text('Practice Modes', style: Theme.of(context).textTheme.titleLarge),
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
              return Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(m['emoji'] as String, style: const TextStyle(fontSize: 22)),
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
                                  fontFamily: 'Nunito')),
                          Text(m['sub'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color.withValues(alpha: 0.7),
                                  fontFamily: 'Nunito')),
                        ],
                      ),
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

  Widget _subjectCard(Subject subject, int index) {
    final gradient = AppTheme.subjectGradient(subject.subjectName);
    final emoji = AppTheme.subjectEmoji(subject.subjectName);
    final color = gradient.colors.first;
    return GestureDetector(
      onTap: () => _startPractice(subject.subjectName, subject.subjectName),
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
              decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.subjectName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito', color: Color(0xFF1A0A3E))),
                  Text('Tap to practice',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Nunito')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
              child: const Text('Start ▶',
                  style: TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
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
            gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)]),
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
                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
