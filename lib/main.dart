import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/subjects_screen.dart';
import 'screens/study_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/report_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    // Builds can provide API_BASE_URL with --dart-define instead.
  }
  runApp(const NovaApp());
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Nova',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/splash',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/splash':
                  return MaterialPageRoute(builder: (_) => const SplashScreen());
                case '/login':
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
                case '/dashboard':
                  return MaterialPageRoute(builder: (_) => const StudentDashboard());
                case '/subjects':
                  return MaterialPageRoute(builder: (_) => const SubjectsScreen());
                case '/study':
                  final args = settings.arguments as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (_) => StudyScreen(
                      subjectId: args['subject_id'],
                      subjectName: args['subject_name'],
                      lessonId: args['lesson_id'],
                    ),
                  );
                case '/practice':
                  return MaterialPageRoute(
                    builder: (_) => PracticeScreen(
                      args: settings.arguments as Map<String, dynamic>?,
                    ),
                  );
                case '/quiz':
                  return MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      args: settings.arguments as Map<String, dynamic>?,
                    ),
                  );
                case '/profile':
                  return MaterialPageRoute(builder: (_) => const ProfileScreen());
                case '/report':
                  return MaterialPageRoute(builder: (_) => const ReportScreen());
                default:
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
              }
            },
          );
        },
      ),
    );
  }
}
