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

class _SubjectsScreenState extends State<SubjectsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<Subject> _subjects = [];
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _classes = [];
  // Curriculum class IDs are database IDs, not the numeric display label.
  // Example: 9th is class_id 4 in New-Nova's curriculum database.
  int _activeClassId = 1;
  late AnimationController _animController;
  bool _animated = false;
  // Real per-subject progress from weekly report
  Map<String, double> _subjectProgress = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _initData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int _resolveClassId(List<dynamic> classesData, String? userClass) {
    Map<String, dynamic>? matchedClass;
    for (final c in classesData) {
      if (c is! Map) continue;
      final name = (c['class_name'] as String? ?? '')
          .toLowerCase()
          .replaceAll(RegExp(r'[^\d]'), '');
      final userCls =
          (userClass ?? '').toLowerCase().replaceAll(RegExp(r'[^\d]'), '');
      if (name == userCls) {
        matchedClass = c as Map<String, dynamic>;
        break;
      }
    }
    return matchedClass?['class_id'] ??
        (classesData.isNotEmpty && classesData[0] is Map
            ? classesData[0]['class_id']
            : 1);
  }

  void _applySubjects(List<dynamic> subjectsData, List<dynamic> classesData) {
    if (!mounted) return;
    setState(() {
      _subjects = subjectsData
          .map((s) => s is Map<String, dynamic>
              ? Subject.fromJson(s)
              : Subject(subjectId: 0, subjectName: ''))
          .toList();
      _classes = classesData.whereType<Map<String, dynamic>>().toList();
      _loading = false;
    });
    if (!_animated) {
      _animController.forward();
      _animated = true;
    }
  }

  Future<void> _initData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Cache-first: show instantly from local cache if previously loaded
    final cachedClasses = _api.getCachedClasses();
    if (cachedClasses != null) {
      final classId = _resolveClassId(cachedClasses, user.userClass);
      _activeClassId = classId;
      final cachedSubjects =
          _api.getCachedSubjects(board: 1, classId: classId, pub: 1);
      if (cachedSubjects != null) {
        _applySubjects(cachedSubjects, cachedClasses);
      }
    }

    // Background refresh from network (keeps data current)
    try {
      final classesData = await _api.getClasses();
      final classId = _resolveClassId(classesData, user.userClass);
      _activeClassId = classId;
      final subjectsData =
          await _api.getSubjects(board: 1, classId: classId, pub: 1);
      _applySubjects(subjectsData, classesData);
    } catch (e) {
      if (mounted && _subjects.isEmpty) {
        setState(() {
          _error =
              'Oops! Couldn\'t load your subjects. Check your internet and try again! 🌐';
          _loading = false;
        });
      }
    }

    // Load real subject progress from weekly report
    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        final report = await _api.getWeeklyReport(user.username);
        if (report['subjects'] is List) {
          final Map<String, double> progress = {};
          for (final s in report['subjects'] as List) {
            if (s is Map) {
              final name = (s['name'] ?? '').toString();
              final score = (s['score'] as num? ?? 0).toDouble();
              if (name.isNotEmpty) progress[name.toLowerCase()] = score / 100;
            }
          }
          if (mounted) setState(() => _subjectProgress = progress);
        }
      }
    } catch (_) {
      // Progress is cosmetic — silently skip if report fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? _buildLoadingState()
          : _error.isNotEmpty
              ? _buildErrorState()
              : _subjects.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _initData,
                      color: AppTheme.primary,
                      child: CustomScrollView(
                        slivers: [
                          _buildSliverHeader(),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) =>
                                    _buildSubjectCard(_subjects[i], i),
                                childCount: _subjects.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C3CE1), Color(0xFF8B5CF6), Color(0xFF4ECDC4)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📚 Subjects',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        )),
                    Text('Choose your adventure!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                if (_classes.isNotEmpty)
                  PopupMenuButton<int>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.filter_alt_rounded,
                          color: Colors.white, size: 20),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    onSelected: (classId) async {
                      setState(() => _loading = true);
                      try {
                        final data = await _api.getSubjects(
                            board: 1, classId: classId, pub: 1);
                        if (mounted) {
                          setState(() {
                            _activeClassId = classId;
                            _subjects = data
                                .map((s) => s is Map<String, dynamic>
                                    ? Subject.fromJson(s)
                                    : Subject(subjectId: 0, subjectName: ''))
                                .toList();
                            _loading = false;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _error = e.toString();
                            _loading = false;
                          });
                        }
                      }
                    },
                    itemBuilder: (_) => _classes
                        .map<PopupMenuItem<int>>((c) => PopupMenuItem(
                              value: c['class_id'] as int? ?? 0,
                              child: Text(c['class_name'] as String? ?? '',
                                  style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Subject count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '✅ ${_subjects.length} subjects available',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject, int index) {
    final gradient = AppTheme.subjectGradient(subject.subjectName);
    final emoji = AppTheme.subjectEmoji(subject.subjectName);
    final delay = index * 100;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final start = (delay / 800).clamp(0.0, 1.0);
        final end = ((delay + 300) / 800).clamp(0.0, 1.0);
        final t = CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ).value;
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/study', arguments: {
          'subject_id': subject.subjectId,
          'subject_name': subject.subjectName,
          'board_id': 1,
          'class_id': _activeClassId,
          'pub_id': 1,
        }),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Subject emoji in white bubble
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject.subjectName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Nunito',
                              )),
                          const SizedBox(height: 4),
                          Text('Tap to explore lessons →',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 10),
                          // Real progress bar from weekly report
                          Builder(builder: (ctx) {
                            final progress = _subjectProgress[
                                    subject.subjectName.toLowerCase()] ??
                                0.0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation(
                                        Colors.white),
                                    minHeight: 5,
                                  ),
                                ),
                                if (progress > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${(progress * 100).toStringAsFixed(0)}% score this week',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C3CE1), Color(0xFF4ECDC4)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text('Loading your subjects... 📚',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text('Oops! Something went wrong',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = '';
                });
                _initData();
              },
              child: const Text('Try Again 🔄'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📭', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text('No subjects found',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Ask your teacher to set up your subjects',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }
}
