import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/member_avatar.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final groupsProvider = context.watch<GroupsProvider>();
    final groups = groupsProvider.groups;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.background,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Groups',
              style: GoogleFonts.inter(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            elevation: 0,
          ),
          if (groups.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(theme: theme),
            )
          else
            // Groups List
            SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final group = groups[index];
                      final members = groupsProvider.getMembersOfGroup(
                        group.id,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GroupDetailScreen(groupId: group.id),
                            ),
                          ),
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
                                // Group Name & Emoji
                                Row(
                                  children: [
                                    Text(
                                      group.emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.name,
                                            style: GoogleFonts.inter(
                                              color: theme.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: theme.textMuted,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Members
                                Row(
                                  children: [
                                    Text(
                                      '${members.length} member${members.length != 1 ? 's' : ''}',
                                      style: GoogleFonts.inter(
                                        color: theme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: members.asMap().entries.map((
                                            entry,
                                          ) {
                                            final memberIndex = entry.key;
                                            final member = entry.value;
                                            final isOverflow =
                                                memberIndex >= 3 &&
                                                members.length > 3;

                                            if (isOverflow && memberIndex > 2) {
                                              return const SizedBox.shrink();
                                            }

                                            return Padding(
                                              padding: EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child:
                                                  memberIndex == 2 &&
                                                      members.length > 3
                                                  ? Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors.primary
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '+${members.length - 2}',
                                                          style:
                                                              GoogleFonts.inter(
                                                                color: AppColors
                                                                    .primary,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    )
                                                  : MemberAvatar(
                                                      user: member,
                                                      radius: 14,
                                                    ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: groups.length),
                  ),
                ),
              ],
            ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  final AppDynColors theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: theme.textMuted),
          const SizedBox(height: 16),
          Text(
            'No Groups Yet',
            style: GoogleFonts.inter(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or join a group to get started',
            style: GoogleFonts.inter(color: theme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
