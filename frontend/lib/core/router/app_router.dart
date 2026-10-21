import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/roadmap/presentation/roadmap_page.dart';
import '../../features/schedule/presentation/schedule_page.dart';
import '../../features/goals/presentation/goals_page.dart';
import '../../features/notes/presentation/notes_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPage(),
          ),
        ),
        GoRoute(
          path: '/roadmap',
          name: 'roadmap',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RoadmapPage(),
          ),
        ),
        GoRoute(
          path: '/schedule',
          name: 'schedule',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SchedulePage(),
          ),
        ),
        GoRoute(
          path: '/goals',
          name: 'goals',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GoalsPage(),
          ),
        ),
        GoRoute(
          path: '/notes',
          name: 'notes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotesPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
      ],
    ),
  ],
);
