import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/expense_model.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/member_avatar.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final groupsProvider = context.watch<GroupsProvider>();
    final payer = groupsProvider.getUserById(expense.payerId);
    final currencyFmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final dateFmt = DateFormat('EEEE, MMMM d, yyyy');

    Color splitColor;
    switch (expense.splitType) {
      case SplitType.equal:
        splitColor = AppColors.primary;
        break;
      case SplitType.itemized:
        splitColor = AppColors.accent;
        break;
      case SplitType.custom:
        splitColor = AppColors.warning;
        break;
      default:
        splitColor = AppColors.success;
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Expense Details', style: TextStyle(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            onPressed: () {
              final groupMembers = groupsProvider.getMembersOfGroup(expense.groupId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(
                    groupId: expense.groupId,
                    members: groupMembers,
                    existingExpense: expense,
                  ),
                ),
              );
            },
          ),
        ],
        backgroundColor: theme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Hero Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: splitColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: splitColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${expense.splitType.icon}  ${expense.splitType.label} Split',
                        style: GoogleFonts.inter(
                          color: splitColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateFmt.format(expense.date),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  expense.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFmt.format(expense.amount),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (payer != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      MemberAvatar(user: payer, radius: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Paid by ${payer.name}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Itemized breakdown
          if (expense.splitType == SplitType.itemized &&
              expense.items.isNotEmpty) ...[
            Text(
              'Items',
              style: GoogleFonts.inter(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...expense.items.map((item) {
              final assignees = item.assignedUserIds
                  .map((id) => groupsProvider.getUserById(id))
                  .where((u) => u != null)
                  .cast<dynamic>()
                  .toList();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.inter(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (assignees.isNotEmpty)
                            Text(
                              assignees.length == 1
                                  ? (assignees.first as dynamic).name as String
                                  : 'Shared (${assignees.map((u) => (u as dynamic).firstName).join(', ')})',
                              style: GoogleFonts.inter(
                                color: theme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFmt.format(item.price),
                          style: GoogleFonts.inter(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.assignedUserIds.length > 1)
                          Text(
                            '${currencyFmt.format(item.pricePerUser)} each',
                            style: GoogleFonts.inter(
                              color: theme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
          // Per-person breakdown
          Text(
            'Who Owes What',
            style: GoogleFonts.inter(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...expense.splits.map((split) {
            final user = groupsProvider.getUserById(split.userId);
            if (user == null) return const SizedBox.shrink();
            final isPayer = split.userId == expense.payerId;
            final netAmount = isPayer
                ? expense.amount - split.amount
                : -split.amount;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.cardBorder),
              ),
              child: Row(
                children: [
                  MemberAvatar(user: user, radius: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          isPayer ? 'Paid the bill' : 'Owes share',
                          style: GoogleFonts.inter(
                            color: theme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFmt.format(split.amount),
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        netAmount > 0
                            ? '+ ${currencyFmt.format(netAmount)}'
                            : currencyFmt.format(netAmount),
                        style: GoogleFonts.inter(
                          color: netAmount > 0
                              ? AppColors.success
                              : AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
