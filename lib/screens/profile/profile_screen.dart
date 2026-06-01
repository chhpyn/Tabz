import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';
import '../friends/friends_screen.dart';
import '../groups/groups_screen.dart';
import '../widgets/member_avatar.dart';
import 'edit_profile_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final auth = context.watch<AuthProvider>();
    
    if (auth.currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser!;
    final isDark = themeProvider.isDark;

    final friendsCount = context.watch<FriendsProvider>().friends.length;
    final groupsCount = context.watch<GroupsProvider>().groups.length;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.inter(
                    color: theme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Avatar Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.contrast,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: MemberAvatar.getConsistentAvatarColor(user.id),
                          shape: BoxShape.circle,
                          image: user.profileImageUrl != null
                              ? DecorationImage(
                                  image:
                                      user.profileImageUrl!.startsWith('http')
                                      ? NetworkImage(user.profileImageUrl!)
                                            as ImageProvider
                                      : FileImage(File(user.profileImageUrl!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user.profileImageUrl == null
                            ? Center(
                                child: Text(
                                  user.initials,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.displayUsername,
                              style: GoogleFonts.inter(
                                color: const Color.fromARGB(255, 174, 169, 255),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FriendsScreen(),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$friendsCount',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Friends',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupsScreen(),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$groupsCount',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Groups',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.background,
                            foregroundColor: theme.textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Edit Profile',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FriendsScreen(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appearance Section
            _SectionTitle(label: 'Appearance', theme: theme),
            const SizedBox(height: 12),
            // Quick toggle row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      color: isDark ? AppColors.primary : AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: GoogleFonts.inter(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          isDark
                              ? 'Easy on the eyes at night'
                              : 'Clean and bright interface',
                          style: GoogleFonts.inter(
                            color: theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (_) => themeProvider.toggle(),
                    activeThumbColor: AppColors.primary,
                    inactiveThumbColor: AppColors.warning,
                    inactiveTrackColor: AppColors.warning.withValues(
                      alpha: 0.3,
                    ),
                    trackOutlineColor:
                        WidgetStateProperty.all(Colors.transparent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Section
            _SectionTitle(label: 'Settings', theme: theme),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.notifications_active_rounded,
              label: 'Notifications',
              subtitle: 'Manage push and email alerts',
              theme: theme,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsItem(
              icon: Icons.security_rounded,
              label: 'Privacy & Security',
              subtitle: 'Manage your password and data',
              theme: theme,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacySettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account Section
            _SectionTitle(label: 'Account', theme: theme),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              label: 'About Tabz',
              subtitle: 'Version 1.0.0',
              theme: theme,
              onTap: () => _showAbout(context, theme),
            ),
            const SizedBox(height: 8),
            _SettingsItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              subtitle: 'Return to login screen',
              theme: theme,
              iconColor: AppColors.accent,
              labelColor: AppColors.accent,
              onTap: () => _showSignOutDialog(context, auth),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context, AppDynColors theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'About Tabz',
          style: GoogleFonts.inter(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tabz is a collaborative expense splitter that reads your receipts and divides the bill your way — equally, by item, or by percentage.',
          style: GoogleFonts.inter(color: theme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    final theme = AppDynColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Sign Out?',
          style: GoogleFonts.inter(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out? You\'ll need to sign in again to access your account.',
          style: GoogleFonts.inter(color: theme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              if (context.mounted) {
                context.read<FriendsProvider>().clearData();
                context.read<GroupsProvider>().clearData();
                context.read<ExpenseProvider>().clearData();
                context.read<NotificationProvider>().clearAll();
              }
              
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widgets
class _SectionTitle extends StatelessWidget {
  final String label;
  final AppDynColors theme;

  const _SectionTitle({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        color: theme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final AppDynColors theme;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.theme,
    this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.textSecondary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? theme.textSecondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: labelColor ?? theme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(color: theme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
