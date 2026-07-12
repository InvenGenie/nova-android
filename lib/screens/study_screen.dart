import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/lesson.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/explanation_sheet.dart';

class StudyScreen extends StatefulWidget {
  final int? subjectId;
  final String? subjectName;
  final int? lessonId;
  final int? boardId;
  final int? classId;
  final int? pubId;

  const StudyScreen({
    super.key,
    this.subjectId,
    this.subjectName,
    this.lessonId,
    this.boardId,
    this.classId,
    this.pubId,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final _api = ApiService();
  List<Lesson> _lessons = [];
  Lesson? _selectedLesson;
  String? _selectedContent;
  bool _loading = true;
  bool _loadingContent = false;

  String _boardName(int id) {
    switch (id) {
      case 2:
        return 'ICSE';
      case 3:
        return 'IB';
      default:
        return 'CBSE';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final user = context.read<AuthProvider>().user;
      final userClass = user?.userClass ?? '';
      final classNum =
          int.tryParse(userClass.replaceAll(RegExp(r'[^\d]'), '')) ?? 1;
      final classId = widget.classId ?? classNum;
      final board = widget.boardId ?? 1;
      final pub = widget.pubId ?? 1;

      final data = await _api.getLessons(
          board, classId, pub, widget.subjectId ?? 10);
      if (mounted) {
        setState(() {
          _lessons = data
              .whereType<Map<String, dynamic>>()
              .map((l) => Lesson.fromJson(l))
              .toList();
          _loading = false;
          if (_lessons.isNotEmpty) {
            _selectLesson(widget.lessonId != null
                ? _lessons.firstWhere(
                    (l) => l.lessonId == widget.lessonId,
                    orElse: () => _lessons.first)
                : _lessons.first);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Oops! Couldn\'t load lessons. Check your internet and try again! 🌐'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _selectLesson(Lesson lesson) async {
    setState(() {
      _selectedLesson = lesson;
      _selectedContent = null;
      _loadingContent = true;
    });
    try {
      final user = context.read<AuthProvider>().user;
      final classNum =
          (user?.userClass ?? '').replaceAll(RegExp(r'[^\d]'), '');
      final content = await _api.getLessonContent(
        chapter: lesson.lessonName,
        subject: widget.subjectName,
        board: _boardName(widget.boardId ?? 1),
        lessonClass: classNum.isNotEmpty ? classNum : null,
        publication: 'NCERT',
      );
      if (mounted) setState(() => _selectedContent = content);
    } catch (_) {
      if (mounted) setState(() => _selectedContent = '');
    }
    if (mounted) setState(() => _loadingContent = false);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName ?? 'Study',
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        actions: [
          // On mobile: lesson picker button in AppBar
          if (!isWide && _lessons.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list_rounded),
              tooltip: 'Switch lesson',
              onPressed: () => _showLessonPicker(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _lessons.isEmpty
              ? _buildEmptyState()
              : isWide
                  // Tablet/wide: side-by-side
                  ? Row(
                      children: [
                        SizedBox(width: 280, child: _buildLessonList()),
                        Expanded(child: _buildLessonContent()),
                      ],
                    )
                  // Mobile: full-screen lesson content, lesson picker in modal
                  : _buildLessonContent(),
    );
  }

  void _showLessonPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scroll) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  const Text('📖 ', style: TextStyle(fontSize: 20)),
                  Text('Choose a Lesson',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: _lessons.length,
                itemBuilder: (context, i) {
                  final lesson = _lessons[i];
                  final isSelected =
                      lesson.lessonId == _selectedLesson?.lessonId;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.grey.shade600,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      lesson.lessonName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontFamily: 'Nunito',
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFF1A0A3E),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppTheme.primary, size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectLesson(lesson);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('No lessons available yet',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Check back later for new content',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontFamily: 'Nunito')),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView.builder(
        itemCount: _lessons.length,
        itemBuilder: (context, i) {
          final lesson = _lessons[i];
          final isSelected = lesson.lessonId == _selectedLesson?.lessonId;
          return ListTile(
            selected: isSelected,
            selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
            title: Text(lesson.lessonName,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
                  fontFamily: 'Nunito',
                )),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.primary : Colors.grey,
                    )),
              ),
            ),
            onTap: () => _selectLesson(lesson),
          );
        },
      ),
    );
  }

  Widget _buildLessonContent() {
    if (_loadingContent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text('Loading lesson... 📖',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      );
    }

    if (_selectedLesson == null) {
      return const Center(child: Text('Select a lesson to begin'));
    }

    final content = _selectedContent;
    final hasContent = content != null && content.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson title
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C3CE1), Color(0xFF4ECDC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedLesson!.lessonName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lesson content — rendered as Markdown
          if (hasContent)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: Color(0xFF2D2D2D),
                    fontFamily: 'Nunito',
                  ),
                  h1: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A0A3E),
                    fontFamily: 'Nunito',
                  ),
                  h2: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A0A3E),
                    fontFamily: 'Nunito',
                  ),
                  h3: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    fontFamily: 'Nunito',
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A0A3E),
                  ),
                  listBullet: TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: AppTheme.primary,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: AppTheme.primary, width: 4),
                    ),
                  ),
                  code: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                ),
              ),
            )
          else
            // No content state — friendly message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Text('🔨', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Content coming soon!',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey.shade600,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'We\'re still preparing study material for this lesson. Try the Explain button below! 💡',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontFamily: 'Nunito',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Action buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasContent
                          ? () {
                              Navigator.pushNamed(context, '/practice',
                                  arguments: {
                                    'subject_id': widget.subjectId,
                                    'subject_name': widget.subjectName,
                                    'lesson_name':
                                        _selectedLesson!.lessonName,
                                    'lesson_id': _selectedLesson!.lessonId,
                                  });
                            }
                          : null,
                      icon: const Icon(Icons.quiz_outlined),
                      label: const Text('Practice'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontFamily: 'Nunito', fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/quiz', arguments: {
                          'subject_id': widget.subjectId,
                          'subject_name': widget.subjectName,
                          'lesson_name': _selectedLesson!.lessonName,
                        });
                      },
                      icon: const Icon(Icons.assessment_outlined),
                      label: const Text('Quiz'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontFamily: 'Nunito', fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showExplanationSheet(
                    context: context,
                    api: _api,
                    username:
                        context.read<AuthProvider>().user?.username ?? '',
                    title: '💡 Explain: ${_selectedLesson!.lessonName}',
                    kind: 'topic',
                    topic: _selectedLesson!.lessonName,
                    subject: widget.subjectName,
                    chapter: _selectedLesson!.lessonName,
                    class_: (context.read<AuthProvider>().user?.userClass ?? '')
                        .replaceAll(RegExp(r'[^\d]'), ''),
                    board: _boardName(widget.boardId ?? 1),
                    publication: 'NCERT',
                  ),
                  icon: const Icon(Icons.lightbulb_rounded),
                  label: const Text('Explain this lesson 🔊'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: const Color(0xFF1A0A3E),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
