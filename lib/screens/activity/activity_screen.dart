import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/expense_card.dart';
import '../expenses/expense_detail_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final auth = context.watch<AuthProvider>();
    final groupsProvider = context.watch<GroupsProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final currentUserId = auth.currentUser?.id ?? '';
    final allExpenses = List.of(expenseProvider.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group expenses by date header
    final grouped = <String, List<dynamic>>{};
    for (final expense in allExpenses) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expDay = DateTime(expense.date.year, expense.date.month, expense.date.day);
      final diff = today.difference(expDay).inDays;

      String header;
      if (diff == 0) {
        header = 'Today';
      } else if (diff == 1) {
        header = 'Yesterday';
      } else if (diff < 7) {
        header = DateFormat('EEEE').format(expense.date);
      } else {
        header = DateFormat('MMMM d, yyyy').format(expense.date);
      }
      grouped.putIfAbsent(header, () => []).add(expense);
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Activity',
          style: GoogleFonts.inter(
            color: theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            if (allExpenses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_rounded, size: 56, color: theme.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses yet',
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Add expenses via the + button',
                        style: GoogleFonts.inter(
                          color: theme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final entries = grouped.entries.toList();
                      int remaining = i;
                      for (final entry in entries) {
                        if (remaining == 0) {
                          // Date header
                          return Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              entry.key,
                              style: GoogleFonts.inter(
                                color: theme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }
                        remaining--;
                        if (remaining < entry.value.length) {
                          final expense = entry.value[remaining];
                          final payer = groupsProvider.getUserById(expense.payerId);
                          final group = groupsProvider.getGroupById(expense.groupId);
                          if (payer == null) return const SizedBox.shrink();
                          return ExpenseCard(
                            expense: expense,
                            payer: payer,
                            currentUserId: currentUserId,
                            group: group,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExpenseDetailScreen(expense: expense),
                              ),
                            ),
                          );
                        }
                        remaining -= entry.value.length;
                      }
                      return null;
                    },
                    childCount: grouped.entries.fold<int>(
                      0,
                      (sum, e) => sum + 1 + e.value.length,
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
