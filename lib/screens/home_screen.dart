import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../core/models/group_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/top_banner.dart';
import './widgets/member_avatar.dart';
import './widgets/expense_card.dart';
import './notification/notification_screen.dart';
import './expenses/expense_detail_screen.dart';
import './activity/activity_screen.dart';
import './groups/group_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _CreateGroupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final auth = context.watch<AuthProvider>();
    final groupsProvider = context.watch<GroupsProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    Future.microtask(() => expenseProvider.setCurrentUser(user.id));

    final currentUserId = user.id;
    final groups = groupsProvider.groups;
    final currencyFmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    // Calculate "To transfer" (total owed to others) and "To receive" (total owed by others)
    double toTransfer = 0;
    double toReceive = 0;

    for (final group in groups) {
      final settlements = expenseProvider.calculateSettlements(
        group.id,
        group.memberIds,
      );
      for (final s in settlements) {
        if (s.fromUserId == currentUserId) toTransfer += s.amount;
        if (s.toUserId == currentUserId) toReceive += s.amount;
      }
    }

    int receiveFlex = 1;
    int transferFlex = 1;
    if (toReceive > 0 || toTransfer > 0) {
      final total = toReceive + toTransfer;
      receiveFlex = 50 + ((toReceive / total) * 50).toInt();
      transferFlex = 50 + ((toTransfer / total) * 50).toInt();
    }

    final allExpenses = List.of(expenseProvider.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentExpenses = allExpenses.take(3).toList();

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              // Date
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEEE, ').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            color: theme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('d MMM yyyy').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            color: theme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      // Avatar circle
                      MemberAvatar(
                        user: user,
                        radius: 27,
                      ),
                      const SizedBox(width: 12),
                      // Greeting + name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Day,',
                              style: GoogleFonts.inter(
                                color: theme.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${user.firstName}!',
                              style: GoogleFonts.inter(
                                color: theme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification bell with unread badge
                      Builder(
                        builder: (context) {
                          final unread = context
                              .watch<NotificationProvider>()
                              .unreadCount;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    unread > 0
                                        ? Icons.notifications_rounded
                                        : Icons.notifications_outlined,
                                    color: theme.textPrimary,
                                    size: 22,
                                  ),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unread > 9 ? '9+' : '$unread',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Stats Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: receiveFlex,
                        child: _StatChip(
                          label: 'To receive',
                          value: currencyFmt.format(toReceive),
                          icon: Icons.move_to_inbox_rounded,
                          color: AppColors.success,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: transferFlex,
                        child: _StatChip(
                          label: 'To transfer',
                          value: currencyFmt.format(toTransfer),
                          icon: Icons.outbound_rounded,
                          color: AppColors.error,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // My Groups Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
                  child: Row(
                    children: [
                      Text(
                        'My Groups',
                        style: GoogleFonts.inter(
                          color: theme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showCreateGroupSheet,
                        child: Text(
                          '+ New Group',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (groups.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'No groups yet',
                            style: GoogleFonts.inter(
                              color: theme.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Tap "+ New Group" to get started',
                            style: GoogleFonts.inter(
                              color: theme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Group Cards (Wallet Stack)
              if (groups.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _StackedGroupCarousel(
                      groups: groups,
                      groupsProvider: groupsProvider,
                      expenseProvider: expenseProvider,
                      currentUserId: currentUserId,
                      theme: theme,
                    ),
                  ),
                ),
              // ── Pending Invitations ──
              if (groupsProvider.pendingInvitations.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: _GroupInvitationsView(
                      invitations: groupsProvider.pendingInvitations,
                      groupsProvider: groupsProvider,
                      theme: theme,
                    ),
                  ),
                ),
              // Recent Activity
              if (recentExpenses.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: GoogleFonts.inter(
                            color: theme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ActivityScreen(),
                            ),
                          ),
                          child: Text(
                            'View All >>',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, index) {
                      final expense = recentExpenses[index];
                      final payer = groupsProvider.getUserById(expense.payerId);
                      final group = groupsProvider.getGroupById(
                        expense.groupId,
                      );
                      if (payer == null || group == null) {
                        return const SizedBox.shrink();
                      }

                      return ExpenseCard(
                        expense: expense,
                        payer: payer,
                        currentUserId: currentUserId,
                        group: group,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ExpenseDetailScreen(expense: expense),
                          ),
                        ),
                      );
                    }, childCount: recentExpenses.length),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

// Stacked Wallet Carousel
class _StackedGroupCarousel extends StatefulWidget {
  final List<GroupModel> groups;
  final GroupsProvider groupsProvider;
  final ExpenseProvider expenseProvider;
  final String currentUserId;
  final AppDynColors theme;

  const _StackedGroupCarousel({
    required this.groups,
    required this.groupsProvider,
    required this.expenseProvider,
    required this.currentUserId,
    required this.theme,
  });

  @override
  State<_StackedGroupCarousel> createState() => _StackedGroupCarouselState();
}

class _StackedGroupCarouselState extends State<_StackedGroupCarousel> {
  late PageController _pageController;
  double _page = 0.0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _page = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: _isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: _buildStackedView(context),
      secondChild: _buildExpandedView(context),
    );
  }

  Widget _buildExpandedView(BuildContext context) {
    return Column(
      children: [
        ...widget.groups.map(
          (g) => _buildCard(
            g,
            overrideOnTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(groupId: g.id),
                ),
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _isExpanded = false),
          icon: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: widget.theme.textSecondary,
          ),
          label: Text(
            'Collapse stack',
            style: GoogleFonts.inter(
              color: widget.theme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStackedView(BuildContext context) {
    // Dynamic height: Base card height (~230px) + space for cards stacked behind
    final int stackDepth = math.min(widget.groups.length - 1, 3);
    final double dynamicHeight = 230.0 + (stackDepth + 23.0);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
          setState(() => _isExpanded = true);
        }
      },
      child: SizedBox(
        height: dynamicHeight,
        child: Stack(
          children: [
            // The visible card stack
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = <Widget>[];

                // Paint from back to front (highest index to lowest)
                // So index 0 (front card) is painted last and sits on top
                for (int i = widget.groups.length - 1; i >= 0; i--) {
                  final group = widget.groups[i];
                  final offset = i - _page;

                  // If swiped away to the left
                  if (offset < -1) continue;

                  // If deep in the stack (only show top 3 to save rendering)
                  if (offset > 3) continue;

                  double verticalShift = 0.0;
                  double horizontalShift = 0.0;
                  double scale = 1.0;
                  double opacity = 1.0;

                  if (offset < 0) {
                    // Swiping off screen to the left
                    horizontalShift = offset * constraints.maxWidth;
                    opacity = (1.0 + offset).clamp(0.0, 1.0);
                  } else {
                    // Stacked behind the current card
                    // Shift upwards by 22px per card deep
                    verticalShift = -22.0 * offset;
                    // Scale down slightly to create depth
                    scale = math.max(0.0, 1.0 - (0.05 * offset));
                    // Dim the cards behind
                    opacity = math.max(0.0, 1.0 - (0.15 * offset));
                  }

                  cards.add(
                    Positioned.fill(
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(horizontalShift, verticalShift)
                          ..scale(scale, scale),
                        alignment: Alignment.bottomCenter,
                        child: Opacity(
                          opacity: opacity,
                          child: Align(
                            alignment: widget.groups.length > 1
                                ? Alignment.bottomCenter
                                : Alignment.topCenter,
                            child: _buildCard(group),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Stack(clipBehavior: Clip.none, children: cards);
              },
            ),

            // Invisible PageView to natively handle horizontal swipes
            PageView.builder(
              controller: _pageController,
              itemCount: widget.groups.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Only open if they tap the current front card area
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupDetailScreen(groupId: widget.groups[index].id),
                      ),
                    );
                  },
                  child: const SizedBox.expand(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(GroupModel group, {VoidCallback? overrideOnTap}) {
    final members = widget.groupsProvider.getMembersOfGroup(group.id);
    final totalSpent = widget.expenseProvider.getTotalSpentForGroup(group.id);
    final settlements = widget.expenseProvider.calculateSettlements(
      group.id,
      group.memberIds,
    );

    double totalOwed = 0;
    double totalGet = 0;
    for (final s in settlements) {
      if (s.fromUserId == widget.currentUserId) totalOwed += s.amount;
      if (s.toUserId == widget.currentUserId) totalGet += s.amount;
    }

    debugPrint(
      'Group ${group.name} - User ${widget.currentUserId}: totalOwed=$totalOwed, totalGet=$totalGet',
    );

    return _GroupCard(
      group: group,
      members: members,
      totalSpent: totalSpent,
      totalOwed: totalOwed,
      totalGet: totalGet,
      theme: widget.theme,
      onTap: overrideOnTap ?? () {}, // Handled by invisible PageView above
    );
  }
}

// Stat Chip
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final AppDynColors theme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: theme.contrast,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: theme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Group Card
class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final List<UserModel> members;
  final double totalSpent;
  final double totalOwed;
  final double totalGet;
  final VoidCallback onTap;
  final AppDynColors theme;

  const _GroupCard({
    required this.group,
    required this.members,
    required this.totalSpent,
    required this.totalOwed,
    required this.totalGet,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.cardBorder.withValues(
              alpha: 0.5,
            ), // Subtle border to distinguish layers
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.cardElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      group.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        group.description,
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.textMuted),
              ],
            ),
            const SizedBox(height: 16),
            MemberAvatarStack(members: members, radius: 15),
            const SizedBox(height: 16),
            Divider(height: 1, color: theme.cardBorder),
            const SizedBox(height: 14),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total spent',
                      style: GoogleFonts.inter(
                        color: theme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currencyFmt.format(totalSpent),
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (totalGet > 0.01)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'You get',
                              style: GoogleFonts.inter(
                                color: AppColors.success,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              currencyFmt.format(totalGet),
                              style: GoogleFonts.inter(
                                color: AppColors.success,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      if (totalGet > 0.01 && totalOwed > 0.01)
                        const SizedBox(width: 12),
                      if (totalOwed > 0.01)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'You owe',
                              style: GoogleFonts.inter(
                                color: AppColors.accent,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              currencyFmt.format(totalOwed),
                              style: GoogleFonts.inter(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      if (totalGet <= 0.01 && totalOwed <= 0.01)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Settled',
                              style: GoogleFonts.inter(
                                color: theme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '—',
                              style: GoogleFonts.inter(
                                color: theme.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Create Group Sheet
class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _customEmojiController = TextEditingController();
  String _selectedEmoji = '🎉';
  final Set<String> _selectedMemberIds = {};

  static const _emojis = [
    '🏝️',
    '🏠',
    '🍽️',
    '🎉',
    '✈️',
    '🚗',
    '🎮',
    '🛒',
    '🎓',
    '💼',
    '🏋️',
    '🎸',
  ];

  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      await context.read<GroupsProvider>().createGroup(
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        description: _descController.text.trim(),
        memberIds: _selectedMemberIds.toList(),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final friends = context.watch<FriendsProvider>().friends;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                'Create New Group',
                style: GoogleFonts.inter(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Emoji',
                style: GoogleFonts.inter(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._emojis.map((e) {
                    final selected = e == _selectedEmoji;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : theme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : theme.cardBorder,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                  // Simple custom box: opens dialog to type/paste emoji
                  GestureDetector(
                    onTap: () async {
                      final res = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            backgroundColor: theme.background,
                            title: Text(
                              'Enter emoji',
                              style: GoogleFonts.inter(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: TextField(
                              controller: _customEmojiController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Paste emoji here',
                              ),
                              style: const TextStyle(fontSize: 22),
                              maxLines: 1,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(
                                  ctx,
                                  _customEmojiController.text.trim(),
                                ),
                                child: const Text('Use'),
                              ),
                            ],
                          );
                        },
                      );
                      if (res != null && res.isNotEmpty) {
                        setState(() {
                          _selectedEmoji = res;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.cardBorder),
                      ),
                      child: Center(
                        child: Text(
                          _customEmojiController.text.trim().isNotEmpty
                              ? _customEmojiController.text.trim()
                              : '+',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: theme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                validator: (v) => v != null && v.trim().length >= 2
                    ? null
                    : 'Enter a group name',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                style: TextStyle(color: theme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Invite Members',
                style: GoogleFonts.inter(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              if (friends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add friends first to include them in a group.',
                          style: GoogleFonts.inter(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...friends.map((user) {
                  final selected = _selectedMemberIds.contains(user.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedMemberIds.add(user.id);
                      } else {
                        _selectedMemberIds.remove(user.id);
                      }
                    }),
                    title: Text(
                      user.name,
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      user.displayUsername,
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                    secondary: MemberAvatar(user: user, radius: 18),
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.contrast,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Create Group',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Group Invitations View
class _GroupInvitationsView extends StatelessWidget {
  final List<GroupModel> invitations;
  final GroupsProvider groupsProvider;
  final AppDynColors theme;

  const _GroupInvitationsView({
    required this.invitations,
    required this.groupsProvider,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invitations (${invitations.length})',
          style: GoogleFonts.inter(
            color: theme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...invitations.map((group) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Text(group.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.inter(
                          color: theme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Invited you to join',
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                      onPressed: () =>
                          groupsProvider.declineInvitation(group.id),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 28,
                      ),
                      onPressed: () {
                        final friendsProvider = context.read<FriendsProvider>();
                        bool hasMutual = false;
                        final members = groupsProvider.getMembersOfGroup(
                          group.id,
                        );
                        final nonFriendsWithRequests = <UserModel>[];
                        final nonFriendsWithoutRequests = <UserModel>[];

                        for (final member in members) {
                          if (friendsProvider.friends.any(
                            (f) => f.id == member.id,
                          )) {
                            hasMutual = true;
                            break;
                          } else {
                            if (friendsProvider.receivedRequests.any(
                              (r) => r.id == member.id,
                            )) {
                              nonFriendsWithRequests.add(member);
                            } else {
                              nonFriendsWithoutRequests.add(member);
                            }
                          }
                        }

                        if (hasMutual) {
                          groupsProvider.acceptInvitation(group.id);
                        } else {
                          _showAddFriendsDialog(
                            context,
                            nonFriendsWithRequests,
                            nonFriendsWithoutRequests,
                            theme,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showAddFriendsDialog(
    BuildContext context,
    List<UserModel> nonFriendsWithRequests,
    List<UserModel> nonFriendsWithoutRequests,
    AppDynColors theme,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.background,
          title: Text(
            'Mutual Friend Required',
            style: GoogleFonts.inter(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You must be friends with at least one active member before you can accept this invitation.',
                  style: GoogleFonts.inter(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                if (nonFriendsWithRequests.isNotEmpty) ...[
                  Text(
                    'Friend Requests',
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...nonFriendsWithRequests.map(
                    (user) => _buildUserListTile(context, user, true, theme),
                  ),
                  const SizedBox(height: 16),
                ],

                if (nonFriendsWithoutRequests.isNotEmpty) ...[
                  Text(
                    'Suggested to Add',
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...nonFriendsWithoutRequests.map(
                    (user) => _buildUserListTile(context, user, false, theme),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserListTile(
    BuildContext context,
    UserModel user,
    bool isRequest,
    AppDynColors theme,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: MemberAvatar(user: user, radius: 18),
      title: Text(
        user.name,
        style: GoogleFonts.inter(color: theme.textPrimary, fontSize: 14),
      ),
      subtitle: Text(
        user.displayUsername,
        style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11),
      ),
      trailing: IconButton(
        icon: Icon(
          isRequest ? Icons.check_circle_rounded : Icons.person_add_rounded,
          color: isRequest ? AppColors.success : AppColors.primary,
        ),
        onPressed: () async {
          final res = await context.read<FriendsProvider>().addFriend(user);
          if (context.mounted) {
            Navigator.pop(context); // Close the dialog
            if (res == AddFriendResult.success) {
              TopBanner.show(
                context,
                isRequest
                    ? 'Friend request accepted! You can now accept the group invitation.'
                    : 'Friend added! You can now accept the group invitation.',
                backgroundColor: AppColors.success,
              );
            } else if (res == AddFriendResult.alreadyFriend) {
              TopBanner.show(context, 'Already a friend!');
            } else {
              TopBanner.show(
                context,
                'Failed to add friend.',
                backgroundColor: AppColors.error,
              );
            }
          }
        },
      ),
    );
  }
}
