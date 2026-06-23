import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';

class StudyScreen extends StatefulWidget {
  final int? subjectId;
  final String? subjectName;
  final int? lessonId;

  const StudyScreen({super.key, this.subjectId, this.subjectName, this.lessonId});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final _api = ApiService();
  List<Lesson> _lessons = [];
  Lesson? _selectedLesson;
  bool _loading = true;
  bool _loadingContent = false;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final data = await _api.getLessons(1, 4, 1, widget.subjectId ?? 10);
      if (mounted) {
        setState(() {
          _lessons = data.map((l) => Lesson.fromJson(l)).toList();
          _loading = false;
          if (_lessons.isNotEmpty) {
            _selectLesson(_lessons.first);
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
      _loadingContent = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _loadingContent = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName ?? 'Study')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? const Center(child: Text('No lessons available'))
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_selectedLesson!.lessonName, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Text(
            _selectedLesson!.content ?? 'Lesson content will be loaded from the server.\n\nThis is an interactive learning module designed to help you understand the topic thoroughly.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Practice Questions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assessment_outlined),
                  label: const Text('Take Quiz'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
