import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/top_banner.dart';
import '../expenses/expense_detail_screen.dart';
import '../groups/group_detail_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // No auto-read: keep unread state so users can see what's new
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

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
          'Notifications',
          style: GoogleFonts.inter(
            color: theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                context.read<NotificationProvider>().markAllRead();
              },
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: theme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Clear all notifications?',
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    content: Text(
                      'This will remove all notifications.',
                      style: GoogleFonts.inter(
                        color: theme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: theme.textMuted),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<NotificationProvider>().clearAll();
                        },
                        child: Text(
                          'Clear',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Slidable(
                  key: ValueKey(notif.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.25,
                    children: [
                      CustomSlidableAction(
                        onPressed: (context) {
                          context.read<NotificationProvider>().removeNotification(notif.id);
                        },
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.accent,
                        padding: EdgeInsets.zero,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline_rounded, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (!notif.isRead) {
                        context.read<NotificationProvider>().markRead(notif.id);
                      }
                      
                      if (notif.type == NotificationType.newExpense) {
                        final expenseId = notif.id.replaceFirst('notif_exp_', '');
                        final expenseProvider = context.read<ExpenseProvider>();
                        try {
                          final expense = expenseProvider.expenses.firstWhere((e) => e.id == expenseId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpenseDetailScreen(expense: expense),
                            ),
                          );
                        } catch (e) {
                          TopBanner.show(
                            context,
                            'Expense details not available.',
                            backgroundColor: theme.card,
                          );
                        }
                      } else if (notif.type == NotificationType.settlementReminder) {
                        if (notif.groupId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(groupId: notif.groupId!),
                            ),
                          );
                        }
                      }
                    },
                    child: _NotificationTile(
                      notification: notif,
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(AppDynColors theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: const Center(
              child: Icon(Icons.notifications_active_rounded, size: 40, color: AppColors.primary),
            ),
          ),
          Text(
            'All caught up!',
            style: GoogleFonts.inter(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No new notifications right now.',
            style: GoogleFonts.inter(color: theme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// Notification Tile
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final AppDynColors theme;
  final bool isDark;

  const _NotificationTile({
    required this.notification,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    IconData iconData;
    String typeLabel;

    switch (notification.type) {
      case NotificationType.newExpense:
        accentColor = AppColors.primary;
        iconData = Icons.receipt_long_rounded;
        typeLabel = 'New Expense';
        break;
      case NotificationType.settlementReminder:
        accentColor = AppColors.warning;
        iconData = Icons.payments_rounded;
        typeLabel = 'Reminder';
        break;
      case NotificationType.groupRequest:
        accentColor = AppColors.success;
        iconData = Icons.group_add_rounded;
        typeLabel = 'Group Request';
        break;
      case NotificationType.friendRequest:
        accentColor = AppColors.accent;
        iconData = Icons.person_add_rounded;
        typeLabel = 'Friend Request';
        break;
    }

    final timeStr = _formatTime(notification.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: notification.isRead
            ? theme.card
            : accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? theme.cardBorder
              : accentColor.withValues(alpha: 0.3),
          width: notification.isRead ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: accentColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.inter(
                            color: theme.textPrimary,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Unread dot
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildBodyText(notification.body, theme, isDark),
                  const SizedBox(height: 8),
                  // Type chip + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.inter(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          color: theme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }

  Widget _buildBodyText(String text, AppDynColors theme, bool isDark) {
    final regex = RegExp(r'(RM\s[\d,]+\.\d{2})');
    final matches = regex.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.inter(
          color: theme.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      );
    }

    final spans = <TextSpan>[];
    int current = 0;
    for (final match in matches) {
      if (match.start > current) {
        spans.add(TextSpan(text: text.substring(current, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontWeight: FontWeight.w700, 
          color: theme.textPrimary,
        ),
      ));
      current = match.end;
    }
    if (current < text.length) {
      spans.add(TextSpan(text: text.substring(current)));
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          color: theme.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }
}
