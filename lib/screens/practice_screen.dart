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
          _subjects = data.whereType<Map<String, dynamic>>().map((s) => Subject.fromJson(s)).toList();
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
      appBar: AppBar(title: const Text('Practice')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.edit_note, size: 40, color: AppTheme.warning),
                        ),
                        const SizedBox(height: 24),
                        Text('Practice Questions', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        Text('Select a subject and mode to start practicing.', style: TextStyle(color: Colors.grey.shade600, height: 1.5), textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _modeChip('Summary', Icons.summarize, AppTheme.primary, () {}),
                            _modeChip('MCQ', Icons.quiz, AppTheme.warning, () {}),
                            _modeChip('Numerical', Icons.calculate, AppTheme.accent, () {}),
                            _modeChip('Mixed', Icons.shuffle, AppTheme.success, () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubjects,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Choose a subject to practice', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      ..._subjects.map((s) => _subjectCard(s)),
                      const SizedBox(height: 24),
                      Text('Practice Mode', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _modeChip('Summary', Icons.summarize, AppTheme.primary, () {}),
                          _modeChip('MCQ', Icons.quiz, AppTheme.warning, () {}),
                          _modeChip('Numerical', Icons.calculate, AppTheme.accent, () {}),
                          _modeChip('Mixed', Icons.shuffle, AppTheme.success, () {}),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _subjectCard(Subject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.auto_stories, color: AppTheme.primary),
        ),
        title: Text(subject.subjectName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Tap to practice', style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, '/study', arguments: {
          'subject_id': subject.subjectId,
          'subject_name': subject.subjectName,
        }),
      ),
    );
  }

  Widget _modeChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
