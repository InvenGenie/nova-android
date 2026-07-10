import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const QuizScreen({super.key, this.args});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _api = ApiService();
  List<Subject> _subjects = [];
  bool _loading = true;

  Subject? _activeSubject;
  String? _lessonName;
  List<dynamic>? _questions;
  bool _quizLoading = false;
  String? _quizError;

  @override
  void initState() {
    super.initState();
    _loadData();
    final lesson = widget.args?['lesson_name'] as String?;
    final subjectName = widget.args?['subject_name'] as String?;
    if (lesson != null && subjectName != null) {
      _startQuiz(lesson, subjectName);
    }
  }

  String _classNum() {
    final user = context.read<AuthProvider>().user;
    return (user?.userClass ?? '').replaceAll(RegExp(r'[^\d]'), '');
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

  Future<void> _startQuiz(String lesson, String subjectName) async {
    setState(() {
      _activeSubject = Subject(subjectId: widget.args?['subject_id'] ?? 0, subjectName: subjectName);
      _lessonName = lesson;
      _quizLoading = true;
      _questions = null;
      _quizError = null;
    });
    try {
      final data = await _api.getQuiz(
        lessonName: lesson,
        subject: subjectName,
        board: 'CBSE',
        lessonClass: _classNum().isNotEmpty ? _classNum() : null,
        publication: 'NCERT',
      );
      if (mounted) {
        if (data['success'] == false) {
          setState(() {
            _quizError = data['error']?.toString() ?? 'Could not generate quiz.';
            _quizLoading = false;
          });
        } else {
          final q = data['questions'] ??
              data['quiz'] ??
              (data['raw_quiz'] is Map ? data['raw_quiz']['questions'] : null) ??
              (data['raw_quiz'] is List ? data['raw_quiz'] : null);
          setState(() {
            _questions = q is List ? List.from(q) : [];
            _quizLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quizError = e.toString();
          _quizLoading = false;
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
                                    style: Theme.of(context).textTheme.titleLarge),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _buildSubjectQuizCard(_subjects[i], i),
                              childCount: _subjects.length,
                            ),
                          ),
                        ),
                      ],
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
                colors: [Color(0xFF4ECDC4), Color(0xFF6BCB77)],
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
                      const Text('🏆 Quiz',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                              color: Colors.white, fontFamily: 'Nunito')),
                      Text(_lessonName ?? '',
                          style: const TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'Nunito')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_quizLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_quizError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: Text(_quizError!, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
              ),
            ),
          )
        else if (_questions != null && _questions!.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildQuestionCard(_questions![i], i),
                childCount: _questions!.length,
              ),
            ),
          )
        else
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No questions generated.')),),
          ),
        if (!_quizLoading && _questions != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: ElevatedButton.icon(
                onPressed: () => _startQuiz(_lessonName ?? _activeSubject!.subjectName, _activeSubject!.subjectName),
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate Quiz'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(dynamic raw, int index) {
    final q = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final question = q['question']?.toString() ?? '';
    final answer = q['answer']?.toString() ?? '';
    final optionsRaw = q['options'];
    List<MapEntry<String, String>> options = [];
    if (optionsRaw is Map) {
      optionsRaw.forEach((k, v) => options.add(MapEntry(k.toString(), v.toString())));
    } else if (optionsRaw is List) {
      for (var i = 0; i < optionsRaw.length; i++) {
        options.add(MapEntry(String.fromCharCode(65 + i), optionsRaw[i].toString()));
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.accentMint.withValues(alpha: 0.1),
              blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. $question',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito', color: Color(0xFF1A0A3E))),
          const SizedBox(height: 12),
          ...options.map((opt) => _optionTile(opt.key, opt.value, answer)),
        ],
      ),
    );
  }

  Widget _optionTile(String key, String value, String answer) {
    final isAnswer = key.trim().toUpperCase() == answer.trim().toUpperCase() ||
        value.trim().toLowerCase() == answer.trim().toLowerCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isAnswer ? AppTheme.accentMint.withValues(alpha: 0.2) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(key, style: TextStyle(fontWeight: FontWeight.w800,
                  color: isAnswer ? AppTheme.accentMint : Colors.grey.shade600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 14, color: isAnswer ? AppTheme.accentMint : Colors.black87)),
          ),
          if (isAnswer) const Icon(Icons.check_circle, color: AppTheme.accentMint, size: 18),
        ],
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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                        color: Colors.white, fontFamily: 'Nunito')),
                Text('Test your knowledge & win stars! ⭐',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85),
                        fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
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
          const Text('🏆', style: TextStyle(fontSize: 56)),
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
          style: const TextStyle(fontSize: 12, color: Colors.white,
              fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
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
              Text('Quiz Types', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: types.map((t) {
              final color = t['color'] as Color;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(t['emoji'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(t['label'] as String,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: color, fontFamily: 'Nunito')),
                    ],
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
      onTap: () => _startQuiz(subject.subjectName, subject.subjectName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4)),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito', color: Color(0xFF1A0A3E))),
                  Row(
                    children: [
                      const Text('⭐⭐⭐', style: TextStyle(fontSize: 12)),
                      Text(' 10 questions',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Nunito')),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
              child: const Text('Play ▶',
                  style: TextStyle(color: Colors.white, fontSize: 13,
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
            gradient: LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF6BCB77)]),
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
                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
