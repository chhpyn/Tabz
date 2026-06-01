import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/expense_model.dart';
import '../../core/models/user_model.dart';
import '../../core/models/group_model.dart';
import '../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/providers/groups_provider.dart';
import 'member_avatar.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final UserModel payer;
  final String currentUserId;
  final GroupModel? group;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.payer,
    required this.currentUserId,
    this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final currencyFmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final userShare = expense.getUserShare(currentUserId);
    final isCurrentUserPayer = expense.payerId == currentUserId;
    final netForCurrentUser = isCurrentUserPayer
        ? expense.amount - userShare
        : -userShare;

    final groupsProvider = context.watch<GroupsProvider>();
    String titleText = expense.title;
    String payerNameStr = isCurrentUserPayer ? 'you' : payer.firstName;
    String receiverNameStr = '';

    if (expense.splitType == SplitType.payment) {
      final receiverId = expense.splits.isNotEmpty ? expense.splits.first.userId : '';
      final receiver = groupsProvider.getUserById(receiverId);
      receiverNameStr = receiver?.id == currentUserId ? 'you' : (receiver?.firstName ?? 'someone');
      titleText = 'Bill Settlement';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (group != null) ...[
              Row(
                children: [
                  Text(group!.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    group!.name,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                // Date badge
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(expense.date).toUpperCase(),
                        style: GoogleFonts.inter(
                          color: theme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        DateFormat('d').format(expense.date),
                        style: GoogleFonts.inter(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: GoogleFonts.inter(
                          color: theme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (expense.splitType == SplitType.payment) ...[
                            MemberAvatar(user: payer, radius: 9),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Paid by $payerNameStr to $receiverNameStr',
                                style: GoogleFonts.inter(
                                  color: theme.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            MemberAvatar(user: payer, radius: 9),
                            const SizedBox(width: 5),
                            Text(
                              'Paid by $payerNameStr',
                              style: GoogleFonts.inter(
                                color: theme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.textSecondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                expense.splitType.label,
                                style: GoogleFonts.inter(
                                  color: theme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amounts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFmt.format(expense.amount),
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (expense.splitType != SplitType.payment) ...[
                      const SizedBox(height: 3),
                      Text(
                        netForCurrentUser > 0
                            ? 'you get ${currencyFmt.format(netForCurrentUser)}'
                            : netForCurrentUser < 0
                            ? 'you owe ${currencyFmt.format(-netForCurrentUser)}'
                            : 'settled',
                        style: GoogleFonts.inter(
                          color: netForCurrentUser > 0
                              ? AppColors.success
                              : netForCurrentUser < 0
                              ? AppColors.accent
                              : theme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ), // Close inner Row
          ],
        ), // Close outer Column
      ),
    );
  }
}
