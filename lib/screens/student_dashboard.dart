import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/study_plan.dart';
import '../models/user.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  final _api = ApiService();
  List<StudyPlan> _todayPlans = [];
  bool _loadingPlans = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _loadingPlans = true);
    try {
      final data = await _api.getStudyPlan(user.username);
      if (data['success'] == true && data['plans'] != null) {
        _todayPlans = (data['plans'] as List).map((e) => StudyPlan.fromJson(e)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingPlans = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    final screens = [
      _buildDashboard(user),
      const SizedBox(),
      const SizedBox(),
      const SizedBox(),
      _buildProfile(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Subjects'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), activeIcon: Icon(Icons.quiz), label: 'Practice'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboard(User user) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadPlan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, ${user.name.split(' ').first}', style: Theme.of(context).textTheme.headlineMedium),
                      Text('Class ${user.userClass ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildFeatureGrid(user),
              const SizedBox(height: 24),
              Text("Today's Plan", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (_loadingPlans)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_todayPlans.isEmpty)
                _buildEmptyPlan()
              else
                ..._todayPlans.map((p) => _buildPlanCard(p)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(User user) {
    final features = [
      {'icon': Icons.library_books, 'label': 'Subjects', 'color': const Color(0xFF3B82F6), 'route': '/subjects'},
      {'icon': Icons.quiz, 'label': 'Practice', 'color': const Color(0xFFF59E0B), 'route': '/practice'},
      {'icon': Icons.assessment, 'label': 'Quiz', 'color': const Color(0xFF8B5CF6), 'route': '/quiz'},
      {'icon': Icons.bar_chart, 'label': 'Progress', 'color': const Color(0xFF10B981), 'route': '/report'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final f = features[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, f['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: (f['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(f['icon'] as IconData, color: f['color'] as Color, size: 36),
                const SizedBox(height: 10),
                Text(f['label'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: f['color'] as Color)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyPlan() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.event_note, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No plan for today', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Add subjects to your study plan', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(StudyPlan plan) {
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
          child: const Icon(Icons.auto_stories, color: AppTheme.primary),
        ),
        title: Text(plan.subject ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(plan.lesson ?? 'No lesson', style: TextStyle(color: Colors.grey.shade600)),
        trailing: plan.completed
            ? const Icon(Icons.check_circle, color: AppTheme.success)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
        onTap: () {
          if (plan.subject != null && plan.lesson != null) {
            Navigator.pushNamed(context, '/study', arguments: {
              'subject_name': plan.subject,
              'lesson_id': null,
            });
          }
        },
      ),
    );
  }

  Widget _buildProfile() {
    return const SizedBox();
  }
}
