import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/settlement_model.dart';
import '../../core/widgets/top_banner.dart';
import '../widgets/expense_card.dart';
import '../widgets/member_avatar.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';
import 'edit_group_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final Set<String> _processingSettlements = {};

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final auth = context.watch<AuthProvider>();
    final groupsProvider = context.watch<GroupsProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final group = groupsProvider.getGroupById(widget.groupId);
    if (group == null)
      return const Scaffold(body: Center(child: Text('Group not found')));

    final members = groupsProvider.getMembersOfGroup(widget.groupId);
    final expenses = expenseProvider.getExpensesForGroup(widget.groupId);
    final totalSpent = expenseProvider.getTotalSpentForGroup(widget.groupId);
    final balances = expenseProvider.calculateNetBalances(
      widget.groupId,
      group.memberIds,
    );
    var settlements = expenseProvider.calculateSettlements(
      widget.groupId,
      group.memberIds,
    );
    final currentUserId = auth.currentUser!.id;

    settlements = settlements
        .where((s) => !_processingSettlements.contains(s.id))
        .toList();
    settlements.sort((a, b) {
      final aInvolved =
          a.fromUserId == currentUserId || a.toUserId == currentUserId;
      final bInvolved =
          b.fromUserId == currentUserId || b.toUserId == currentUserId;
      if (aInvolved && !bInvolved) return -1;
      if (!aInvolved && bInvolved) return 1;
      return 0;
    });

    double totalOwed = 0;
    double totalGet = 0;
    for (final s in settlements) {
      if (s.fromUserId == currentUserId) totalOwed += s.amount;
      if (s.toUserId == currentUserId) totalGet += s.amount;
    }

    final currencyFmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditGroupScreen(groupId: group.id),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Group Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group name and emoji
                    Row(
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                group.description,
                                style: GoogleFonts.inter(
                                  color: theme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Members
                    Row(
                      children: [
                        Text(
                          '${members.length} Members',
                          style: GoogleFonts.inter(
                            color: theme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        MemberAvatarStack(members: members, radius: 14),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Divider(height: 1, color: theme.cardBorder),
                    const SizedBox(height: 18),
                    // Balance Summary
                    Row(
                      children: [
                        Expanded(
                          child: (totalGet <= 0.01 && totalOwed <= 0.01)
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'All settled',
                                      style: GoogleFonts.inter(
                                        color: theme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '—',
                                      style: GoogleFonts.inter(
                                        color: theme.textMuted,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    if (totalGet > 0.01)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'You receive',
                                            style: GoogleFonts.inter(
                                              color: AppColors.success,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currencyFmt.format(totalGet),
                                            style: GoogleFonts.inter(
                                              color: AppColors.success,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (totalGet > 0.01 && totalOwed > 0.01)
                                      const SizedBox(width: 16),
                                    if (totalOwed > 0.01)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'You owe',
                                            style: GoogleFonts.inter(
                                              color: AppColors.accent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currencyFmt.format(totalOwed),
                                            style: GoogleFonts.inter(
                                              color: AppColors.accent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total group spend',
                              style: GoogleFonts.inter(
                                color: theme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFmt.format(totalSpent),
                              style: GoogleFonts.inter(
                                color: theme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // To Settle Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settlements.isNotEmpty)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To Settle',
                          style: GoogleFonts.inter(
                            color: theme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...settlements.map((settlement) {
                          final fromUser = groupsProvider.getUserById(
                            settlement.fromUserId,
                          );
                          final toUser = groupsProvider.getUserById(
                            settlement.toUserId,
                          );
                          if (fromUser == null || toUser == null) {
                            return const SizedBox.shrink();
                          }

                          final isCurrentUserPayer =
                              currentUserId == settlement.fromUserId;
                          final isCurrentUserReceiver =
                              currentUserId == settlement.toUserId;
                          final isCurrentUserInvolved =
                              isCurrentUserPayer || isCurrentUserReceiver;

                          return AnimatedOpacity(
                            opacity: settlement.isPaid ? 0.5 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: settlement.isPaid
                                    ? theme.card.withValues(alpha: 0.7)
                                    : theme.card,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // From (payer)
                                      Column(
                                        children: [
                                          MemberAvatar(
                                            user: fromUser,
                                            radius: 22,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            fromUser.firstName,
                                            style: GoogleFonts.inter(
                                              color: theme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Arrow + amount
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              currencyFmt.format(
                                                settlement.amount,
                                              ),
                                              style: GoogleFonts.inter(
                                                color: theme.textPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 2,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: settlement.isPaid
                                                          ? [
                                                              AppColors.success,
                                                              AppColors.success,
                                                            ]
                                                          : [
                                                              AppColors.accent,
                                                              AppColors.primary,
                                                            ],
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: settlement.isPaid
                                                      ? AppColors.success
                                                      : AppColors.primary,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              settlement.isPaid
                                                  ? 'Paid'
                                                  : 'Pending',
                                              style: GoogleFonts.inter(
                                                color: settlement.isPaid
                                                    ? AppColors.success
                                                    : theme.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // To (receiver)
                                      Column(
                                        children: [
                                          MemberAvatar(
                                            user: toUser,
                                            radius: 22,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            toUser.firstName,
                                            style: GoogleFonts.inter(
                                              color: theme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (isCurrentUserInvolved) ...[
                                    const SizedBox(height: 12),
                                    // Action buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              setState(() {
                                                _processingSettlements.add(
                                                  settlement.id,
                                                );
                                              });
                                              // Record the payment
                                              await expenseProvider
                                                  .recordPayment(
                                                    groupId: group.id,
                                                    fromUserId:
                                                        settlement.fromUserId,
                                                    toUserId:
                                                        settlement.toUserId,
                                                    amount: settlement.amount,
                                                  );
                                              if (context.mounted) {
                                                TopBanner.show(
                                                  context,
                                                  'Payment recorded successfully!',
                                                  backgroundColor:
                                                      AppColors.success,
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: AppColors.success
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .check_circle_outline_rounded,
                                                    color: AppColors.success,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Mark as Settled',
                                                    style: GoogleFonts.inter(
                                                      color: AppColors.success,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isCurrentUserPayer) ...[
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                TopBanner.show(
                                                  context,
                                                  'Payment gateway integration coming soon!',
                                                  backgroundColor:
                                                      AppColors.primary,
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.payment_rounded,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Settle Now',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (isCurrentUserReceiver) ...[
                                          const SizedBox(width: 10),
                                          // Remind button
                                          GestureDetector(
                                            onTap: () {
                                              final currentUser = context
                                                  .read<AuthProvider>()
                                                  .currentUser;
                                              if (currentUser != null) {
                                                context
                                                    .read<
                                                      NotificationProvider
                                                    >()
                                                    .sendReminder(
                                                      toUserId: fromUser.id,
                                                      fromUserName:
                                                          currentUser.firstName,
                                                      amount: settlement.amount,
                                                      groupName: group.name,
                                                      groupId: group.id,
                                                      groupEmoji: group.emoji,
                                                      settlementId:
                                                          settlement.id,
                                                    );

                                                TopBanner.show(
                                                  context,
                                                  'Reminder sent to ${fromUser.firstName}',
                                                  accentColor:
                                                      AppColors
                                                          .avatarColors[fromUser
                                                              .id
                                                              .hashCode
                                                              .abs() %
                                                          AppColors
                                                              .avatarColors
                                                              .length],
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: theme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: theme.cardBorder,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.notifications_rounded,
                                                color: AppColors.primary,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Expenses Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Row(
                children: [
                  Text(
                    'All Expenses',
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${expenses.length} total',
                    style: GoogleFonts.inter(
                      color: theme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expenses.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Text(
                        'No expenses yet',
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Tap + to add the first one',
                        style: GoogleFonts.inter(
                          color: theme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final expense = expenses[i];
                  final payer = groupsProvider.getUserById(expense.payerId)!;
                  return ExpenseCard(
                    expense: expense,
                    payer: payer,
                    currentUserId: currentUserId,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseDetailScreen(expense: expense),
                      ),
                    ),
                  );
                }, childCount: expenses.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddExpenseScreen(groupId: widget.groupId, members: members),
            ),
          ),
          backgroundColor: theme.contrast,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Add Expense',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
