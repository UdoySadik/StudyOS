import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/analytics/application/streak_provider.dart';
import '../../features/timer/presentation/active_timer_bar.dart';

/// Nav item model
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final String shortcut;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    required this.shortcut,
  });
}

const _navItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    route: '/dashboard',
    shortcut: 'Ctrl+1',
  ),
  _NavItem(
    label: 'Roadmap',
    icon: Icons.map_outlined,
    activeIcon: Icons.map,
    route: '/roadmap',
    shortcut: 'Ctrl+2',
  ),
  _NavItem(
    label: 'Schedule',
    icon: Icons.schedule_outlined,
    activeIcon: Icons.schedule,
    route: '/schedule',
    shortcut: 'Ctrl+3',
  ),
  _NavItem(
    label: 'Goals',
    icon: Icons.flag_outlined,
    activeIcon: Icons.flag,
    route: '/goals',
    shortcut: 'Ctrl+4',
  ),
  _NavItem(
    label: 'Notes',
    icon: Icons.sticky_note_2_outlined,
    activeIcon: Icons.sticky_note_2,
    route: '/notes',
    shortcut: 'Ctrl+5',
  ),
  _NavItem(
    label: 'Projects',
    icon: Icons.code_rounded,
    activeIcon: Icons.code,
    route: '/projects',
    shortcut: 'Ctrl+6',
  ),
  _NavItem(
    label: 'AI Planner',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome,
    route: '/ai-planner',
    shortcut: 'Ctrl+7',
  ),
  _NavItem(
    label: 'Recall',
    icon: Icons.psychology_outlined,
    activeIcon: Icons.psychology,
    route: '/recall',
    shortcut: 'Ctrl+8',
  ),
  _NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    route: '/settings',
    shortcut: 'Ctrl+9',
  ),
];

/// App shell — persistent sidebar + content area + desktop keyboard navigation
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => context.go('/dashboard'),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => context.go('/roadmap'),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => context.go('/schedule'),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => context.go('/goals'),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => context.go('/notes'),
        const SingleActivator(LogicalKeyboardKey.digit6, control: true): () => context.go('/projects'),
        const SingleActivator(LogicalKeyboardKey.digit7, control: true): () => context.go('/ai-planner'),
        const SingleActivator(LogicalKeyboardKey.digit8, control: true): () => context.go('/recall'),
        const SingleActivator(LogicalKeyboardKey.digit9, control: true): () => context.go('/settings'),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.darkBg,
          bottomNavigationBar: const ActiveStudyTimerBar(),
          body: Row(
            children: [
              _Sidebar(currentLocation: location),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentLocation;
  const _Sidebar({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App logo / name
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 26, 12, 22),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'StudyOS',
                  style: TextStyle(
                    color: AppColors.textDarkPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                const _SidebarStreakBadge(),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppColors.darkBorder, height: 1),
          ),
          const SizedBox(height: 12),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: _navItems.map((item) {
                final isActive = currentLocation.startsWith(item.route);
                return _SidebarNavItem(item: item, isActive: isActive);
              }).toList(),
            ),
          ),

          // Version badge
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: AppColors.textDarkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  const _SidebarNavItem({required this.item, required this.isActive});

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;

    return Tooltip(
      message: '${widget.item.label} (${widget.item.shortcut})',
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go(widget.item.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : _hovered
                      ? AppColors.darkCard
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? widget.item.activeIcon : widget.item.icon,
                  size: 18,
                  color: isActive ? AppColors.primary : AppColors.textDarkSecondary,
                ),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: isActive ? AppColors.primary : AppColors.textDarkSecondary,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.darkCard.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.darkBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    widget.item.shortcut,
                    style: TextStyle(
                      color: isActive ? AppColors.primary : AppColors.textDarkMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarStreakBadge extends ConsumerWidget {
  const _SidebarStreakBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return streakAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (streak) {
        final count = streak.currentStreak;
        final hasStreak = count > 0;

        return Tooltip(
          message: hasStreak
              ? '$count-day study streak! Keep it going!'
              : 'Start your study streak today!',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: hasStreak
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasStreak
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                    : AppColors.darkBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasStreak ? '🔥' : '⚡',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: hasStreak
                        ? const Color(0xFFFBBF24)
                        : AppColors.textDarkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

