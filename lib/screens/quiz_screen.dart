import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _api = ApiService();
  List<Subject> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final subjects = await _api.getSubjects(board: 1, classId: 1, pub: 1);
      if (mounted) {
        setState(() {
          _subjects = subjects.whereType<Map<String, dynamic>>().map((s) => Subject.fromJson(s)).toList();
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
      appBar: AppBar(title: const Text('Quiz')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.quiz, size: 40, color: AppTheme.accent),
                          ),
                          const SizedBox(height: 16),
                          Text('Weekly Quiz', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text('Test your knowledge across subjects', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Select a subject', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (_subjects.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('No subjects available', style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      )
                    else
                      ..._subjects.map((s) => _subjectQuizCard(s)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _subjects.isNotEmpty
                            ? () => Navigator.pushNamed(context, '/study', arguments: {
                                  'subject_id': _subjects.first.subjectId,
                                  'subject_name': _subjects.first.subjectName,
                                })
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Quiz (First Subject)'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.history),
                        label: const Text('Past Results'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _subjectQuizCard(Subject subject) {
    final colors = [AppTheme.primary, AppTheme.warning, AppTheme.success, AppTheme.accent, AppTheme.error];
    final color = colors[_subjects.indexOf(subject) % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.quiz_outlined, color: color),
        ),
        title: Text(subject.subjectName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('10 questions', style: TextStyle(color: Colors.grey.shade600)),
        trailing: Icon(Icons.play_circle_outline, color: color),
        onTap: () => Navigator.pushNamed(context, '/study', arguments: {
          'subject_id': subject.subjectId,
          'subject_name': subject.subjectName,
        }),
      ),
    );
  }
}
