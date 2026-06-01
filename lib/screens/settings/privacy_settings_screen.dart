import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/top_banner.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);

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
          'Privacy & Security',
          style: GoogleFonts.inter(
            color: theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionTitle('Security', theme),
            const SizedBox(height: 12),
            _buildActionItem(
              Icons.password_rounded,
              'Change Password',
              'Update your account password',
              theme,
              onTap: () => _showTopMessage(context, 'Password settings coming soon!'),
            ),
            const SizedBox(height: 8),
            _buildActionItem(
              Icons.fingerprint_rounded,
              'Biometric Login',
              'Use FaceID or TouchID',
              theme,
              onTap: () => _showTopMessage(context, 'Biometrics setup coming soon!'),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Data & Privacy', theme),
            const SizedBox(height: 12),
            _buildActionItem(
              Icons.history_rounded,
              'Clear History',
              'Remove local search and app data',
              theme,
              onTap: () => _showTopMessage(context, 'History cleared!'),
            ),
            const SizedBox(height: 8),
            _buildActionItem(
              Icons.delete_forever_rounded,
              'Delete Account',
              'Permanently remove your account and data',
              theme,
              isDestructive: true,
              onTap: () => _showTopMessage(context, 'Account deletion flow coming soon!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppDynColors theme) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        color: theme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle,
    AppDynColors theme, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final titleColor = isDestructive ? AppColors.accent : theme.textPrimary;
    final iconColor = isDestructive ? AppColors.accent : AppColors.primary;
    final bgColor = isDestructive 
        ? AppColors.accent.withValues(alpha: 0.1) 
        : AppColors.primary.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: theme.textSecondary,
                      fontSize: 13,
                    ),
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
      ),
    );
  }

  void _showTopMessage(BuildContext context, String message) {
    TopBanner.show(context, message, backgroundColor: AppColors.primary);
  }
}
