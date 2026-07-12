import 'package:flutter/material.dart';
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

  const StudyScreen({super.key, this.subjectId, this.subjectName, this.lessonId, this.boardId, this.classId, this.pubId});

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
      final classNum = int.tryParse(userClass.replaceAll(RegExp(r'[^\d]'), '')) ?? 1;
      final classId = widget.classId ?? classNum;
      final board = widget.boardId ?? 1;
      final pub = widget.pubId ?? 1;

      final data = await _api.getLessons(board, classId, pub, widget.subjectId ?? 10);
      if (mounted) {
        setState(() {
          _lessons = data.whereType<Map<String, dynamic>>().map((l) => Lesson.fromJson(l)).toList();
          _loading = false;
          if (_lessons.isNotEmpty) {
            _selectLesson(widget.lessonId != null
                ? _lessons.firstWhere((l) => l.lessonId == widget.lessonId, orElse: () => _lessons.first)
                : _lessons.first);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
      if (mounted) _selectedContent = content;
    } catch (_) {
      if (mounted) _selectedContent = '';
    }
    if (mounted) setState(() => _loadingContent = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName ?? 'Study')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_stories, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No lessons available', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Check back later for new content', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                )
              : Row(
                  children: [
                    if (MediaQuery.of(context).size.width > 600)
                      SizedBox(
                        width: 280,
                        child: _buildLessonList(),
                      ),
                    Expanded(
                      child: _loadingContent
                          ? const Center(child: CircularProgressIndicator())
                          : _selectedLesson != null
                              ? _buildLessonContent()
                              : const Center(child: Text('Select a lesson')),
                    ),
                  ],
                ),
      bottomSheet: MediaQuery.of(context).size.width <= 600
          ? Container(
              height: 70,
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: _lessons.length,
                itemBuilder: (context, i) {
                  final lesson = _lessons[i];
                  final isSelected = lesson.lessonId == _selectedLesson?.lessonId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(lesson.lessonName, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : null)),
                      selected: isSelected,
                      onSelected: (_) => _selectLesson(lesson),
                      selectedColor: AppTheme.primary,
                    ),
                  );
                },
              ),
            )
          : null,
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
            title: Text(lesson.lessonName, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            onTap: () => _selectLesson(lesson),
          );
        },
      ),
    );
  }

  Widget _buildLessonContent() {
    final content = _selectedContent;
    final hasContent = content != null && content.isNotEmpty;
    final safeContent = content ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_selectedLesson!.lessonName, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          if (hasContent)
            Text(safeContent, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.construction, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Content being prepared', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('This lesson will have study material soon', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasContent
                      ? () {
                          Navigator.pushNamed(context, '/practice', arguments: {
                            'subject_id': widget.subjectId,
                            'subject_name': widget.subjectName,
                            'lesson_name': _selectedLesson!.lessonName,
                            'lesson_id': _selectedLesson!.lessonId,
                          });
                        }
                      : null,
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Practice Questions'),
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
                  label: const Text('Take Quiz'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showExplanationSheet(
                  context: context,
                  api: _api,
                  username: context.read<AuthProvider>().user?.username ?? '',
                  title: 'Explain: ${_selectedLesson!.lessonName}',
                  kind: 'topic',
                  topic: _selectedLesson!.lessonName,
                  subject: widget.subjectName,
                  chapter: _selectedLesson!.lessonName,
                  class_: (context.read<AuthProvider>().user?.userClass ?? '').replaceAll(RegExp(r'[^\d]'), ''),
                  board: _boardName(widget.boardId ?? 1),
                  publication: 'NCERT',
                ),
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Explain this lesson'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
