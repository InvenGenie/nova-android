import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Center(
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
              Text('Solve topic-wise practice questions to master each subject.', style: TextStyle(color: Colors.grey.shade600, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _modeChip('Summary', Icons.summarize, AppTheme.primary),
                  _modeChip('MCQ', Icons.quiz, AppTheme.warning),
                  _modeChip('Numerical', Icons.calculate, AppTheme.accent),
                  _modeChip('Mixed', Icons.shuffle, AppTheme.success),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, IconData icon, Color color) {
    return FilterChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      selected: false,
      onSelected: (_) {},
      selectedColor: color.withValues(alpha: 0.1),
    );
  }
}
