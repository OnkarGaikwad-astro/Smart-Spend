import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color secondarySoft;
  final Color accent;
  final Color accentSoft;
  final Color danger;
  final Color dangerSoft;
  final Color success;
  final Color successSoft;
  final Color purple;
  final Color surface;
  final Color surface2;
  final Color borderSubtle;
  final Color textMain;
  final Color textMuted;

  const AppColors({
    required this.background,
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.secondarySoft,
    required this.accent,
    required this.accentSoft,
    required this.danger,
    required this.dangerSoft,
    required this.success,
    required this.successSoft,
    required this.purple,
    required this.surface,
    required this.surface2,
    required this.borderSubtle,
    required this.textMain,
    required this.textMuted,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? background,
    Color? primary,
    Color? primarySoft,
    Color? secondary,
    Color? secondarySoft,
    Color? accent,
    Color? accentSoft,
    Color? danger,
    Color? dangerSoft,
    Color? success,
    Color? successSoft,
    Color? purple,
    Color? surface,
    Color? surface2,
    Color? borderSubtle,
    Color? textMain,
    Color? textMuted,
  }) {
    return AppColors(
      background: background ?? this.background,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      purple: purple ?? this.purple,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textMain: textMain ?? this.textMain,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

class AppTheme {
  // Light Palette
  static const AppColors lightColors = AppColors(
    background: Color(0xFFF6F6E9), // Light Cream Base
    primary: Color(0xFF447A9C), // Dark Ocean Blue
    primarySoft: Color(0x26447A9C),
    secondary: Color(0xFF7DA2C8), // Steel Blue
    secondarySoft: Color(0x267DA2C8),
    accent: Color(0xFF8DBEDE), // Light Sky Blue
    accentSoft: Color(0x338DBEDE),
    danger: Color(0xFFEF4444),
    dangerSoft: Color(0x1AEF4444),
    success: Color(0xFF10B981),
    successSoft: Color(0x2610B981),
    purple: Color(0xFF7DA2C8),
    surface: Color(0xFFEAF1F7),
    surface2: Color(0xFFD7E5F1),
    borderSubtle: Color(0xFFC3D8EA),
    textMain: Color(0xFF2A4B61), // Deep Slate Blue
    textMuted: Color(0xFF5C7F9B), // Muted Slate
  );

  // Vibrant, High-Contrast Modern Dark Palette
  static const AppColors darkColors = AppColors(
    background: Color(0xFF0A0F1D), // Deep Cosmic Obsidian
    primary: Color(0xFF38BDF8), // Electric Vivid Sky Blue
    primarySoft: Color(0x2638BDF8),
    secondary: Color(0xFF818CF8), // Radiant Indigo
    secondarySoft: Color(0x26818CF8),
    accent: Color(0xFF2DD4BF), // Glowing Neon Mint
    accentSoft: Color(0x262DD4BF),
    danger: Color(0xFFF43F5E), // Vibrant Crimson Rose
    dangerSoft: Color(0x26F43F5E),
    success: Color(0xFF10B981), // Crisp Emerald Green
    successSoft: Color(0x2610B981),
    purple: Color(0xFFA855F7), // Electric Lilac
    surface: Color(0xFF11192C), // Deep Midnight Card Surface
    surface2: Color(0xFF1B253D), // Elevated Card / Chip
    borderSubtle: Color(0xFF283553), // Modern Hairline Border
    textMain: Color(0xFFF8FAFC), // Pure Crisp White
    textMuted: Color(0xFF94A3B8), // Sleek Slate 400
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? darkColors
            : lightColors);
  }

  /// Specialized brand font styling for 'SmartSpend' with Moirai One
  static TextStyle brandStyle({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w900,
    Color? color,
    double letterSpacing = -0.5,
  }) {
    return GoogleFonts.moiraiOne(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.josefinSansTextTheme();
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: GoogleFonts.josefinSans().fontFamily,
      scaffoldBackgroundColor: lightColors.background,
      primaryColor: lightColors.primary,
      colorScheme: ColorScheme.light(
        primary: lightColors.primary,
        secondary: lightColors.secondary,
        surface: lightColors.surface,
        error: lightColors.danger,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: lightColors.textMain,
        displayColor: lightColors.textMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.josefinSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: lightColors.textMain,
        ),
        iconTheme: IconThemeData(color: lightColors.textMain),
      ),
      cardTheme: CardThemeData(
        color: lightColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lightColors.borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColors.surface2.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: lightColors.textMuted),
        hintStyle: TextStyle(color: lightColors.textMuted.withValues(alpha: 0.7)),
      ),
      extensions: const [lightColors],
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.josefinSansTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.josefinSans().fontFamily,
      scaffoldBackgroundColor: darkColors.background,
      primaryColor: darkColors.primary,
      colorScheme: ColorScheme.dark(
        primary: darkColors.primary,
        secondary: darkColors.secondary,
        surface: darkColors.surface,
        error: darkColors.danger,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: darkColors.textMain,
        displayColor: darkColors.textMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.josefinSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkColors.textMain,
        ),
        iconTheme: IconThemeData(color: darkColors.textMain),
      ),
      cardTheme: CardThemeData(
        color: darkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkColors.borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColors.surface2.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: darkColors.textMuted),
        hintStyle: TextStyle(color: darkColors.textMuted.withValues(alpha: 0.7)),
      ),
      extensions: const [darkColors],
    );
  }
}
