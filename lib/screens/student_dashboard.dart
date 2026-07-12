import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/study_plan.dart';
import '../models/user.dart';
import 'subjects_screen.dart';
import 'practice_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final _api = ApiService();
  List<StudyPlan> _todayPlans = [];
  bool _loadingPlans = false;

  // Stats state variables
  String _streak = '—';
  String _xpToday = '—';
  String _accuracy = '—';

  late AnimationController _headerController;
  late AnimationController _floatController;
  late Animation<double> _headerAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _headerAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _headerController.forward();
    _loadPlan();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _loadingPlans = true);
    try {
      final results = await Future.wait([
        _api.getStudyPlan(user.username),
        _api.getWeeklyReport(user.username),
      ]);

      final planData = results[0];
      if (planData['success'] == true && planData['plans'] != null) {
        _todayPlans =
            (planData['plans'] as List).map((e) => StudyPlan.fromJson(e)).toList();
      }

      // Map weekly report to stats
      final report = results[1];
      final streakVal = report['streak'];
      final accuracyVal = report['accuracy'];
      final totalQueries = report['total_queries'];

      if (mounted) {
        setState(() {
          _streak = streakVal != null ? '$streakVal 🔥' : '—';
          _accuracy = accuracyVal != null
              ? '${(accuracyVal as num).toStringAsFixed(0)}%'
              : '—';
          _xpToday = totalQueries != null ? '$totalQueries' : '—';
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load your dashboard. Pull down to refresh! 🔄'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted) setState(() => _loadingPlans = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    final screens = [
      _buildDashboard(user),
      const SubjectsScreen(),
      const PracticeScreen(),
      const ReportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home', 'emoji': '🏠'},
      {'icon': Icons.auto_stories_rounded, 'label': 'Subjects', 'emoji': '📚'},
      {'icon': Icons.sports_esports_rounded, 'label': 'Practice', 'emoji': '🎮'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Progress', 'emoji': '📊'},
      {'icon': Icons.person_rounded, 'label': 'Me', 'emoji': '👤'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = _currentIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16 : 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accentCyan])
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          items[i]['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(User user) {
    final firstName = user.name.split(' ').first;
    return RefreshIndicator(
      onRefresh: _loadPlan,
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Hero header
          SliverToBoxAdapter(child: _buildHeroHeader(firstName, user)),
          // XP / stats strip
          SliverToBoxAdapter(child: _buildStatsStrip()),
          // Section title: Features
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  const Text('🎯 ', style: TextStyle(fontSize: 20)),
                  Text("What's next?",
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ),
          // Feature grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildFeatureCard(i),
                childCount: 4,
              ),
            ),
          ),
          // Today's mission
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🚀 ', style: TextStyle(fontSize: 20)),
                      Text("Today's Mission",
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  if (_todayPlans.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_todayPlans.length} tasks',
                          style: const TextStyle(
                            color: Color(0xFFB8860B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            fontFamily: 'Nunito',
                          )),
                    ),
                ],
              ),
            ),
          ),
          // Plans
          _loadingPlans
              ? SliverToBoxAdapter(child: _buildLoadingShimmer())
              : _todayPlans.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyPlan())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildMissionCard(_todayPlans[i], i),
                          childCount: _todayPlans.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(String firstName, User user) {
    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (context, child) => Opacity(
        opacity: _headerAnim.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _headerAnim.value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D0B7A), Color(0xFF6C3CE1), Color(0xFF4ECDC4)],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hey, $firstName! 👋',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (user.userClass != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '📚 Class ${user.userClass}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Floating avatar
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: child,
                  ),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Motivational badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text(
                    'Keep the streak alive!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('⭐ Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito',
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsStrip() {
    final stats = [
      {
        'emoji': '🔥',
        'label': 'Streak',
        'value': _streak,
        'color': AppTheme.accent,
      },
      {
        'emoji': '⭐',
        'label': 'XP Today',
        'value': _xpToday,
        'color': AppTheme.accentYellow,
      },
      {
        'emoji': '🎯',
        'label': 'Accuracy',
        'value': _accuracy,
        'color': AppTheme.accentMint,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (s['color'] as Color).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(s['emoji'] as String,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  // AnimatedSwitcher so the value animates in when it loads
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Text(
                      s['value'] as String,
                      key: ValueKey(s['value']),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: s['color'] as Color,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                  Text(s['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureCard(int i) {
    final features = [
      {
        'emoji': '📚',
        'label': 'Subjects',
        'sub': 'Explore topics',
        'gradient': const LinearGradient(
            colors: [Color(0xFF6C3CE1), Color(0xFF8B5CF6)]),
        'route': '/subjects',
      },
      {
        'emoji': '🎮',
        'label': 'Practice',
        'sub': 'Sharpen skills',
        'gradient': const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)]),
        'route': '/practice',
      },
      {
        'emoji': '🏆',
        'label': 'Quiz',
        'sub': 'Test yourself',
        'gradient': const LinearGradient(
            colors: [Color(0xFF4ECDC4), Color(0xFF6BCB77)]),
        'route': '/quiz',
      },
      {
        'emoji': '📊',
        'label': 'Progress',
        'sub': 'See your stats',
        'gradient': const LinearGradient(
            colors: [Color(0xFFFF6EAB), Color(0xFFFF6B6B)]),
        'route': '/report',
      },
    ];

    final f = features[i];
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, f['route'] as String),
      child: Container(
        decoration: BoxDecoration(
          gradient: f['gradient'] as LinearGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (f['gradient'] as LinearGradient)
                  .colors
                  .first
                  .withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorative circle
            Positioned(
              right: -16,
              bottom: -16,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(f['emoji'] as String,
                      style: const TextStyle(fontSize: 32)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['label'] as String,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Nunito',
                          )),
                      Text(f['sub'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(2, (i) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
        )),
      ),
    );
  }

  Widget _buildEmptyPlan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🎒', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text('No missions today yet!',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: const Color(0xFF1A0A3E))),
            const SizedBox(height: 6),
            Text(
              'No missions yet! Ask your teacher or tap Subjects to begin your adventure 📚',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accentCyan]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Explore Subjects 📚',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(StudyPlan plan, int index) {
    final emojis = ['🌟', '⚡', '🎯', '🔥', '💡', '🚀'];
    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      AppTheme.accentMint,
      AppTheme.accentOrange,
      AppTheme.accentCyan,
      AppTheme.accentPink,
    ];
    final color = colors[index % colors.length];
    final emoji = emojis[index % emojis.length];

    return GestureDetector(
      onTap: () {
        if (plan.subject != null) {
          Navigator.pushNamed(context, '/study', arguments: {
            'subject_name': plan.subject,
            'lesson_id': null,
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.subject ?? 'Subject',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                        color: Color(0xFF1A0A3E),
                      )),
                  Text(plan.lesson ?? 'Let\'s learn!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontFamily: 'Nunito',
                      )),
                ],
              ),
            ),
            plan.completed
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppTheme.accentMint, size: 20),
                  )
                : Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}
