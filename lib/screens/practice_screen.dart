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

  /// Currently selected practice mode (drives the chip grid highlight and API call)
  String _selectedMode = 'mixed';

  /// Parsed questions list. Each map:
  ///   { 'index': int, 'text': String, 'answer': String,
  ///     'submitted': bool, 'feedback': String }
  List<Map<String, dynamic>> _questions = [];

  /// Controllers for each question's answer TextField
  final List<TextEditingController> _answerControllers = [];

  // ─── Mode definitions ────────────────────────────────────────────────────
  static const _modes = [
    {'emoji': '📝', 'label': 'Summary', 'sub': 'Review key points', 'value': 'summary'},
    {'emoji': '🧠', 'label': 'MCQ', 'sub': 'Multiple choice', 'value': 'mcq'},
    {'emoji': '🔢', 'label': 'Numerical', 'sub': 'Solve problems', 'value': 'numerical'},
    {'emoji': '🎲', 'label': 'Mixed', 'sub': 'Random mix', 'value': 'mixed'},
  ];

  static const _modeColors = {
    'summary': AppTheme.primary,
    'mcq': AppTheme.accentOrange,
    'numerical': AppTheme.accentCyan,
    'mixed': AppTheme.accentPink,
  };

  // ─── Lifecycle ────────────────────────────────────────────────────────────

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

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _classNum() {
    final user = context.read<AuthProvider>().user;
    return (user?.userClass ?? '').replaceAll(RegExp(r'[^\d]'), '');
  }

  Color _modeColor(String value) =>
      _modeColors[value] ?? AppTheme.primary;

  // ─── Data loading ─────────────────────────────────────────────────────────

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
    // Dispose old controllers
    for (final c in _answerControllers) {
      c.dispose();
    }
    _answerControllers.clear();

    setState(() {
      _activeSubject = Subject(
        subjectId: widget.args?['subject_id'] ?? 0,
        subjectName: subjectName,
      );
      _lessonName = lesson;
      _practiceLoading = true;
      _practiceText = null;
      _practiceError = null;
      _questions = [];
    });

    try {
      final text = await _api.getPracticeQuestions(
        lessonName: lesson,
        numQuestions: 5,
        subject: subjectName,
        board: 'CBSE',
        lessonClass: _classNum().isNotEmpty ? _classNum() : null,
        publication: 'NCERT',
        mode: _selectedMode,
      );
      if (mounted) {
        final parsed = _parseQuestions(text);
        // Create a controller for every question (or 1 for free-form fallback)
        final count = parsed.isEmpty ? 1 : parsed.length;
        for (var i = 0; i < count; i++) {
          _answerControllers.add(TextEditingController());
        }
        setState(() {
          _practiceText = text;
          _questions = parsed;
          _practiceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _practiceError =
              "Oops! Couldn't load practice questions. Check your internet and try again! 🎮";
          _practiceLoading = false;
        });
      }
    }
  }

  // ─── Question parser ──────────────────────────────────────────────────────

  /// Splits raw AI text on numbered lines (`1.`, `2.`, `3.` …).
  /// Returns an empty list when no numbered items are found (triggers fallback).
  List<Map<String, dynamic>> _parseQuestions(String raw) {
    if (raw.trim().isEmpty) return [];

    // Match lines that start with a number followed by `.` or `)` optionally
    // preceded by whitespace/newline.
    final pattern = RegExp(r'(?:^|\n)\s*(\d+)[.)]\s+', multiLine: true);
    final matches = pattern.allMatches(raw).toList();

    if (matches.length < 2) return []; // Not enough numbered items → fallback

    final List<Map<String, dynamic>> result = [];
    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
      final text = raw.substring(start, end).trim();
      if (text.isEmpty) continue;
      result.add({
        'index': result.length + 1,
        'text': text,
        'answer': '',
        'submitted': false,
        'feedback': '',
      });
    }
    return result;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
                                    style: Theme.of(context).textTheme.titleLarge),
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

  // ─── Session view ──────────────────────────────────────────────────────────

  Widget _buildSession() {
    return CustomScrollView(
      slivers: [
        // Session header
        SliverToBoxAdapter(child: _buildSessionHeader()),

        // Content area
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _practiceLoading
                ? _buildPracticeLoading()
                : _practiceError != null
                    ? _errorCard(_practiceError!)
                    : _practiceText != null && _practiceText!.isNotEmpty
                        ? _questions.isNotEmpty
                            ? _buildQuestionList()
                            : _buildFreeFormFallback()
                        : _errorCard('No practice questions generated.'),
          ),
        ),

        // Generate More button
        if (!_practiceLoading && (_practiceText != null || _practiceError != null))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              child: ElevatedButton.icon(
                onPressed: () => _startPractice(
                  _lessonName ?? _activeSubject!.subjectName,
                  _activeSubject!.subjectName,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Generate More Questions 🔄'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionHeader() {
    return Container(
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
            onTap: () => setState(() {
              _activeSubject = null;
              _practiceText = null;
              _practiceError = null;
              _questions = [];
              for (final c in _answerControllers) {
                c.dispose();
              }
              _answerControllers.clear();
            }),
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
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(
              _modes.firstWhere(
                (m) => m['value'] == _selectedMode,
                orElse: () => _modes.last,
              )['label'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Practice loading indicator ────────────────────────────────────────────

  Widget _buildPracticeLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.accent),
          SizedBox(height: 20),
          Text(
            '✨ Nova is crafting your questions…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Parsed question list ──────────────────────────────────────────────────

  Widget _buildQuestionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${_questions.length} Questions – Good luck! 🍀',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
        ),
        ...List.generate(_questions.length, (i) => _buildQuestionCard(i)),
      ],
    );
  }

  Widget _buildQuestionCard(int i) {
    final q = _questions[i];
    final submitted = q['submitted'] as bool;
    final accentColor = _modeColor(_selectedMode);

    // Ensure controller exists
    while (_answerControllers.length <= i) {
      _answerControllers.add(TextEditingController());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number badge + text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${q['index']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Nunito',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    q['text'] as String,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF1A0A3E),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Answer TextField
            TextField(
              controller: _answerControllers[i],
              enabled: !submitted,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontFamily: 'Nunito',
                  fontSize: 13,
                ),
                filled: true,
                fillColor: submitted ? Colors.green.shade50 : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: submitted ? Colors.green.shade200 : Colors.grey.shade200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accentColor, width: 1.8),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.green.shade200),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Color(0xFF1A0A3E),
              ),
            ),

            const SizedBox(height: 12),

            // Submit button or affirmation chip
            if (!submitted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final typed = _answerControllers[i].text.trim();
                    if (typed.isEmpty) return;
                    setState(() {
                      _questions[i] = {
                        ..._questions[i],
                        'answer': typed,
                        'submitted': true,
                        'feedback': '✅ Answer saved! Nova will check it.',
                      };
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  child: const Text('Submit Answer ✓'),
                ),
              )
            else
              _buildAffirmationChip(q['feedback'] as String),
          ],
        ),
      ),
    );
  }

  Widget _buildAffirmationChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.green,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Free-form fallback ────────────────────────────────────────────────────

  Widget _buildFreeFormFallback() {
    // Ensure at least one controller exists for free-form
    if (_answerControllers.isEmpty) {
      _answerControllers.add(TextEditingController());
    }
    final submitted = _questions.isNotEmpty &&
        (_questions.first['submitted'] as bool? ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _practiceText!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _answerControllers[0],
          maxLines: 4,
          minLines: 2,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontFamily: 'Nunito',
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: AppTheme.accent, width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: Color(0xFF1A0A3E),
          ),
        ),
        const SizedBox(height: 12),
        if (!submitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final typed = _answerControllers[0].text.trim();
                if (typed.isEmpty) return;
                setState(() {
                  if (_questions.isEmpty) {
                    _questions = [
                      {
                        'index': 1,
                        'text': '',
                        'answer': typed,
                        'submitted': true,
                        'feedback': '✅ Answer saved! Nova will check it.',
                      }
                    ];
                  } else {
                    _questions[0] = {
                      ..._questions[0],
                      'answer': typed,
                      'submitted': true,
                      'feedback': '✅ Answer saved! Nova will check it.',
                    };
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              child: const Text('Submit Answer ✓'),
            ),
          )
        else
          _buildAffirmationChip('✅ Answer saved! Nova will check it.'),
      ],
    );
  }

  // ─── Error card ────────────────────────────────────────────────────────────

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
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontFamily: 'Nunito')),
          ],
        ),
      );

  // ─── Subject-picker header ────────────────────────────────────────────────

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

  // ─── Mode section (interactive chips) ────────────────────────────────────

  Widget _buildModeSection() {
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
            itemCount: _modes.length,
            itemBuilder: (context, i) {
              final m = _modes[i];
              final value = m['value'] as String;
              final color = _modeColor(value);
              final isSelected = _selectedMode == value;

              return GestureDetector(
                onTap: () {
                  if (_selectedMode != value) {
                    setState(() => _selectedMode = value);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.18)
                        : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? color : color.withValues(alpha: 0.25),
                      width: isSelected ? 2.2 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
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
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: color, size: 18),
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

  // ─── Subject card ─────────────────────────────────────────────────────────

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
              decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16)),
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
                          color: Color(0xFF1A0A3E))),
                  Text(
                    'Mode: ${_modes.firstWhere((m) => m['value'] == _selectedMode, orElse: () => _modes.last)['label']} • Tap to practice',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontFamily: 'Nunito'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('Start ▶',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito')),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Global loading skeleton ───────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)]),
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(36)),
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
                        color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
