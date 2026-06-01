import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/top_banner.dart';
import './home_screen.dart';
import './profile/profile_screen.dart';
import './expenses/add_expense_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  static const _screens = [
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.currentUser == null) return;
      
      final currentUserId = auth.currentUser!.id;
      
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.setCurrentUser(currentUserId);
      
      final expenseProvider = context.read<ExpenseProvider>();
      final groupsProvider = context.read<GroupsProvider>();
      groupsProvider.setCurrentUser(currentUserId);
      groupsProvider.loadGroups().then((_) {
        // Caching settlements for all groups eagerly
        for (final group in groupsProvider.groups) {
          final members = groupsProvider.getMembersOfGroup(group.id).map((u) => u.id).toList();
          expenseProvider.calculateSettlements(group.id, members);
        }
      });
      
      final friendsProvider = context.read<FriendsProvider>();
      friendsProvider.setCurrentUser(currentUserId);
      friendsProvider.loadFriends();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showQuickAddSheet() async {
    final groupsProvider = context.read<GroupsProvider>();
    final groups = groupsProvider.groups;

    if (groups.isEmpty) {
      TopBanner.show(context, 'Create a group first!');
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _QuickAddSheet(groups: groups),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! > 0 && _currentIndex > 0) {
                  // Swiped right (go back)
                  _onTabTap(_currentIndex - 1);
                } else if (details.primaryVelocity! < 0 && _currentIndex < _screens.length - 1) {
                  // Swiped left (go forward)
                  _onTabTap(_currentIndex + 1);
                }
              },
              child: _FloatingPillNav(
                currentIndex: _currentIndex,
                onTap: _onTabTap,
                theme: theme,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            _AddFab(onTap: _showQuickAddSheet),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Animated FAB
class _AddFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  State<_AddFab> createState() => _AddFabState();
}

class _AddFabState extends State<_AddFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 64,
                height: 64,
                color: (isDark ? theme.cardElevated : const Color.fromARGB(255, 0, 0, 0)),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Floating Pill Navigation Bar
class _FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppDynColors theme;
  final bool isDark;

  const _FloatingPillNav({
    required this.currentIndex,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(8),
            color: (isDark ? theme.cardElevated : Colors.black),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PillTab(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _PillTab(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                  theme: theme,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppDynColors theme;
  final bool isDark;

  const _PillTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 48,
        width: isSelected ? 120 : 48,
        decoration: BoxDecoration(
          color: isSelected ? theme.background : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            width: isSelected ? 120 : 48,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? theme.textPrimary : Colors.white,
                  size: 24,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Quick Add Sheet
class _QuickAddSheet extends StatelessWidget {
  final List groups;

  const _QuickAddSheet({required this.groups});

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final groupsProvider = context.read<GroupsProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add Expense to',
            style: GoogleFonts.inter(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose which group to add an expense to',
            style: GoogleFonts.inter(color: theme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...groups.map((group) {
            final members = groupsProvider.getMembersOfGroup(group.id);
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(
                      groupId: group.id,
                      members: members,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.cardBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      group.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.inter(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${members.length} members',
                            style: GoogleFonts.inter(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.textMuted,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
