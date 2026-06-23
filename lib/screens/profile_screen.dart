import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover, width: 96, height: 96),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
                      Text('@${user.username}', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Column(
                    children: [
                      _tile(Icons.person_outline, 'Role', user.role),
                      if (user.userClass != null) _tile(Icons.school_outlined, 'Class', user.userClass!),
                      if (user.syllabus != null) _tile(Icons.book_outlined, 'Syllabus', user.syllabus!),
                      if (user.school != null) _tile(Icons.business_outlined, 'School', user.school!),
                      if (user.email != null) _tile(Icons.email_outlined, 'Email', user.email!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dark_mode),
                        title: const Text('Dark Mode'),
                        trailing: Switch(
                          value: context.watch<ThemeProvider>().isDark,
                          onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    );
  }
}
