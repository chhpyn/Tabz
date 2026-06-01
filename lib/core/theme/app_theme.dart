import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Brand colours (same in both themes)
class AppColors {
  static const Color primary = Color.fromARGB(255, 142, 201, 250);
  static const Color primaryDark = Color.fromARGB(255, 87, 177, 250);
  static const Color primaryLight = Color(0xFFABD7FB);
  static const Color accent = Color(0xFFF98C53);
  static const Color success = Color.fromARGB(255, 144, 173, 64);
  static const Color warning = Color.fromARGB(255, 246, 213, 108);
  static const Color error = Color.fromARGB(255, 201, 94, 36);

  static const List<Color> gradientPrimary = [
    Color.fromARGB(255, 87, 177, 250),
    Color(0xFFABD7FB),
  ];
  static const List<Color> gradientAccent = [
    Color.fromARGB(255, 201, 94, 36),
    Color(0xFFFCCEB4),
  ];
  static const List<Color> gradientSuccess = [
    Color.fromARGB(255, 144, 173, 64),
    Color(0xFFD2E0AA),
  ];

  static const List<Color> avatarColors = [
    Color(0xFFD2E0AA),
    Color(0xFFABD7FB),
    Color(0xFFFEE594),
    Color(0xFFFCCEB4),
  ];
}

// Dynamic colours (switch per theme)
class AppDynColors {
  final Color background;
  final Color surface;
  final Color card;
  final Color cardElevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final List<Color> gradientBackground;
  final Color successBg;
  final Color warningBg;
  final Color errorBg;
  final Color navBar;
  final Color contrast;

  const AppDynColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.cardElevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.gradientBackground,
    required this.successBg,
    required this.warningBg,
    required this.errorBg,
    required this.navBar,
    required this.contrast,
  });

  static AppDynColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const dark = AppDynColors(
    background: Color.fromARGB(255, 0, 0, 0),
    surface: Color.fromARGB(255, 0, 0, 0),
    card: Color.fromARGB(255, 15, 20, 24),
    cardElevated: Color.fromARGB(255, 17, 21, 24),
    cardBorder: Color.fromARGB(255, 22, 28, 32),
    textPrimary: Color(0xFFEAEAEA),
    textSecondary: Color(0xFF9E9EBE),
    textMuted: Color(0xFF6B6B8E),
    gradientBackground: [Color.fromARGB(255, 15, 12, 11), Color(0xFF000000)],
    successBg: Color.fromARGB(255, 37, 51, 0),
    warningBg: Color.fromARGB(255, 56, 40, 0),
    errorBg: Color.fromARGB(255, 59, 22, 0),
    navBar: Color.fromARGB(255, 7, 10, 12),
    contrast: Color.fromARGB(255, 17, 21, 24),
  );

  static const light = AppDynColors(
    background: Color(0xFFF9F2EF),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFF0F2F8),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF5A5A7A),
    textMuted: Color(0xFF9E9EB8),
    gradientBackground: [Color(0xFFFCCEB4), Color(0xFFFFFFFF)],
    successBg: Color(0xFFD2E0AA),
    warningBg: Color(0xFFFEE594),
    errorBg: Color(0xFFFCCEB4),
    navBar: Color(0xFFFFFFFF),
    contrast: Color(0xFF000000),
  );
}

// BuildContext shorthand 
extension AppColorsContext on BuildContext {
  AppDynColors get colors => AppDynColors.of(this);
}

// Theme builders 
class AppTheme {
  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final theme = isDark ? AppDynColors.dark : AppDynColors.light;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: theme.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: theme.textPrimary,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: theme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: GoogleFonts.inter(
          color: theme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineSmall: GoogleFonts.inter(
          color: theme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleLarge: GoogleFonts.inter(
          color: theme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.inter(
          color: theme.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(color: theme.textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: theme.textSecondary, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: theme.textMuted, fontSize: 12),
        labelLarge: GoogleFonts.inter(
          color: theme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: theme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: theme.textPrimary),
        actionsIconTheme: IconThemeData(color: theme.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: theme.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: theme.textMuted, fontSize: 14),
        prefixIconColor: theme.textSecondary,
        suffixIconColor: theme.textSecondary,
      ),
      cardTheme: CardThemeData(
        color: theme.card,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark ? BorderSide(color: theme.cardBorder) : BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerColor: theme.cardBorder,
      chipTheme: ChipThemeData(
        backgroundColor: theme.card,
        labelStyle: GoogleFonts.inter(color: theme.textSecondary, fontSize: 12),
        side: BorderSide(color: theme.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: theme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: theme.card,
        contentTextStyle: GoogleFonts.inter(color: theme.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: theme.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: theme.cardBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
