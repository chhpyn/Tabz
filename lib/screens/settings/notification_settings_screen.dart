import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool pushEnabled = true;
  bool emailEnabled = false;
  bool groupActivityEnabled = true;
  bool mentionsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionTitle('Delivery Methods', theme),
            const SizedBox(height: 12),
            _buildToggleItem(
              'Push Notifications',
              'Receive alerts on your device',
              pushEnabled,
              (v) => setState(() => pushEnabled = v),
              theme,
            ),
            const SizedBox(height: 8),
            _buildToggleItem(
              'Email Alerts',
              'Receive summaries via email',
              emailEnabled,
              (v) => setState(() => emailEnabled = v),
              theme,
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Alert Types', theme),
            const SizedBox(height: 12),
            _buildToggleItem(
              'Group Activity',
              'When new expenses are added to your groups',
              groupActivityEnabled,
              (v) => setState(() => groupActivityEnabled = v),
              theme,
            ),
            const SizedBox(height: 8),
            _buildToggleItem(
              'Mentions & Comments',
              'When someone tags or messages you',
              mentionsEnabled,
              (v) => setState(() => mentionsEnabled = v),
              theme,
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

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    AppDynColors theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: theme.textPrimary,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveThumbColor: theme.textMuted,
            inactiveTrackColor: theme.cardBorder,
            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
