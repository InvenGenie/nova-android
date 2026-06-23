import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _api = ApiService();
  List<Subject> _subjects = [];
  bool _loading = true;
  String _error = '';
  int? _boardId = 1;
  int? _pubId = 1;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      final classesData = await _api.getClasses();
      final userClass = user.userClass;
      Map<String, dynamic>? matchedClass;
      for (final c in classesData) {
        if (c is! Map) continue;
        final name = (c['class_name'] as String? ?? '').toLowerCase().replaceAll(RegExp(r'[^\d]'), '');
        final userCls = (userClass ?? '').toLowerCase().replaceAll(RegExp(r'[^\d]'), '');
        if (name == userCls) {
          matchedClass = c as Map<String, dynamic>;
          break;
        }
      }
      final classId = matchedClass?['class_id'] ?? (classesData.isNotEmpty && classesData[0] is Map ? classesData[0]['class_id'] : 1);

      final subjectsData = await _api.getSubjects(board: _boardId, classId: classId, pub: _pubId);
      if (mounted) {
        setState(() {
          _subjects = subjectsData.map((s) => s is Map<String, dynamic> ? Subject.fromJson(s) : Subject(subjectId: 0, subjectName: '')).toList();
          _classes = classesData.whereType<Map<String, dynamic>>().toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          if (_classes.isNotEmpty)
            PopupMenuButton<int>(
              icon: const Icon(Icons.filter_list),
              onSelected: (classId) async {
                setState(() => _loading = true);
                try {
                  final data = await _api.getSubjects(board: _boardId, classId: classId, pub: _pubId);
                  if (mounted) setState(() { _subjects = data.map((s) => s is Map<String, dynamic> ? Subject.fromJson(s) : Subject(subjectId: 0, subjectName: '')).toList(); _loading = false; });
                } catch (e) {
                  if (mounted) setState(() { _error = e.toString(); _loading = false; });
                }
              },
              itemBuilder: (_) => _classes.map<PopupMenuItem<int>>((c) => PopupMenuItem(value: c['class_id'] as int? ?? 0, child: Text(c['class_name'] as String? ?? ''))).toList(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Error: $_error'))
              : _subjects.isEmpty
                  ? const Center(child: Text('No subjects found'))
                  : RefreshIndicator(
                      onRefresh: _initData,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Choose a subject', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _subjects.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final subject = _subjects[i];
                                  return _SubjectCard(
                                    subject: subject,
                                    onTap: () => Navigator.pushNamed(context, '/study', arguments: {
                                      'subject_id': subject.subjectId,
                                      'subject_name': subject.subjectName,
                                    }),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;

  const _SubjectCard({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Maths': const Color(0xFF3B82F6),
      'Science': const Color(0xFF10B981),
      'Social': const Color(0xFFF59E0B),
    };
    final color = colors[subject.subjectName] ?? AppTheme.accent;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(_getIcon(subject.subjectName), color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.subjectName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Tap to view lessons', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name.toLowerCase()) {
      case 'maths':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'social':
        return Icons.public;
      default:
        return Icons.auto_stories;
    }
  }
}
