import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: user == null
          ? _buildNotLoggedIn(context)
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeroCard(context, user)),
                SliverToBoxAdapter(child: _buildAchievements(context)),
                SliverToBoxAdapter(child: _buildInfoCards(context, user)),
                SliverToBoxAdapter(child: _buildSettings(context)),
                SliverToBoxAdapter(child: _buildLogout(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildHeroCard(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D0B7A), Color(0xFF6C3CE1), Color(0xFFFF6EAB)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Stars decoration
          ...List.generate(6, (i) {
            final rng = math.Random(i * 7);
            return Positioned(
              left: rng.nextDouble() * 300,
              top: rng.nextDouble() * 150,
              child: Text(
                ['⭐', '✨', '🌟'][i % 3],
                style: TextStyle(
                  fontSize: rng.nextDouble() * 12 + 10,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            );
          }),
          // Main content
          Column(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.cover, width: 100, height: 100),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppTheme.accentYellow, AppTheme.accentOrange]),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                          child: Text('🌟', style: TextStyle(fontSize: 12))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(user.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    letterSpacing: -0.3,
                  )),
              const SizedBox(height: 4),
              Text('@${user.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 16),
              // Info chips
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (user.userClass != null)
                    _infoBadge('📚 Class ${user.userClass}'),
                  if (user.school != null)
                    _infoBadge('🏫 ${user.school}'),
                  _infoBadge('🎓 ${user.role}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(text,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          )),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    final badges = [
      {'emoji': '🔥', 'label': 'On Fire'},
      {'emoji': '🏆', 'label': 'Champion'},
      {'emoji': '⚡', 'label': 'Speedy'},
      {'emoji': '🧠', 'label': 'Smart'},
      {'emoji': '📚', 'label': 'Scholar'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅 ', style: TextStyle(fontSize: 20)),
              Text('Badges', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              itemBuilder: (context, i) {
                final b = badges[i];
                final colors = [
                  [AppTheme.primary, AppTheme.accentCyan],
                  [AppTheme.accentOrange, AppTheme.accentYellow],
                  [AppTheme.accentMint, AppTheme.accentCyan],
                  [AppTheme.accentPink, AppTheme.accent],
                  [AppTheme.primary, AppTheme.accentPink],
                ];
                return Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: colors[i % colors.length]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colors[i % colors.length][0]
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b['emoji']!,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(b['label']!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, dynamic user) {
    final items = <Map<String, dynamic>>[
      if (user.email != null)
        {'emoji': '📧', 'label': 'Email', 'value': user.email, 'color': AppTheme.primary},
      if (user.syllabus != null)
        {'emoji': '📋', 'label': 'Syllabus', 'value': user.syllabus, 'color': AppTheme.accentCyan},
      {'emoji': '🎭', 'label': 'Role', 'value': user.role, 'color': AppTheme.accentPink},
    ];

    if (items.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👤 ', style: TextStyle(fontSize: 20)),
              Text('Your Info', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: items.map((item) {
                final color = item['color'] as Color;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: items.last != item
                        ? Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade100, width: 1))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                            child: Text(item['emoji'] as String,
                                style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['value'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Nunito',
                                  color: Color(0xFF1A0A3E),
                                )),
                            Text(item['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontFamily: 'Nunito',
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚙️ ', style: TextStyle(fontSize: 20)),
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Center(
                        child: Text('🌙', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Dark Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito',
                          color: Color(0xFF1A0A3E),
                        )),
                  ),
                  Switch.adaptive(
                    value: context.watch<ThemeProvider>().isDark,
                    onChanged: (_) =>
                        context.read<ThemeProvider>().toggleTheme(),
                    activeThumbColor: AppTheme.primary,
                    activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () async {
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.error.withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('👋 ', style: TextStyle(fontSize: 20)),
              Text('Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                    fontFamily: 'Nunito',
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text('Not logged in',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }
}
