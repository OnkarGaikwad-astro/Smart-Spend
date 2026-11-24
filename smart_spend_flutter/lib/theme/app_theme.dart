import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemePalette {
  final String key;
  final String name;
  final Color primaryColor;
  final String description;

  const ThemePalette({
    required this.key,
    required this.name,
    required this.primaryColor,
    required this.description,
  });
}

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
  static const List<ThemePalette> availablePalettes = [
    ThemePalette(
      key: 'ocean',
      name: 'Ocean Slate',
      primaryColor: Color(0xFF447A9C),
      description: 'Default calm Atlantic slate blue and sky glass',
    ),
    ThemePalette(
      key: 'emerald',
      name: 'Emerald Mint',
      primaryColor: Color(0xFF0D9488),
      description: 'Prosperity & wealth growth with fresh teal mint',
    ),
    ThemePalette(
      key: 'violet',
      name: 'Cyber Violet',
      primaryColor: Color(0xFF7C3AED),
      description: 'Modern Web3 & AI aesthetic with rich royal violet',
    ),
    ThemePalette(
      key: 'amber',
      name: 'Sunset Amber',
      primaryColor: Color(0xFFD97706),
      description: 'Warm luxury gold with radiant brass accents',
    ),
    ThemePalette(
      key: 'crimson',
      name: 'Rose Crimson',
      primaryColor: Color(0xFFE11D48),
      description: 'High energy, vibrant raspberry & rose highlights',
    ),
    ThemePalette(
      key: 'midnight',
      name: 'Obsidian Minimal',
      primaryColor: Color(0xFF475569),
      description: 'Monochrome architectural slate with zero distraction',
    ),
  ];

  static AppColors getLightColors(String paletteKey) {
    switch (paletteKey) {
      case 'emerald':
        return const AppColors(
          background: Color(0xFFF0F6F4),
          primary: Color(0xFF0D9488),
          primarySoft: Color(0x260D9488),
          secondary: Color(0xFF14B8A6),
          secondarySoft: Color(0x2614B8A6),
          accent: Color(0xFF2DD4BF),
          accentSoft: Color(0x332DD4BF),
          danger: Color(0xFFEF4444),
          dangerSoft: Color(0x1AEF4444),
          success: Color(0xFF10B981),
          successSoft: Color(0x2610B981),
          purple: Color(0xFF14B8A6),
          surface: Color(0xFFD4EBE7),
          surface2: Color(0xFFBFDFD9),
          borderSubtle: Color(0xFFB5D8D1),
          textMain: Color(0xFF134E4A),
          textMuted: Color(0xFF3F7A75),
        );
      case 'violet':
        return const AppColors(
          background: Color(0xFFF5F3FF),
          primary: Color(0xFF7C3AED),
          primarySoft: Color(0x267C3AED),
          secondary: Color(0xFF8B5CF6),
          secondarySoft: Color(0x268B5CF6),
          accent: Color(0xFFA78BFA),
          accentSoft: Color(0x33A78BFA),
          danger: Color(0xFFEF4444),
          dangerSoft: Color(0x1AEF4444),
          success: Color(0xFF10B981),
          successSoft: Color(0x2610B981),
          purple: Color(0xFF8B5CF6),
          surface: Color(0xFFE5DEFB),
          surface2: Color(0xFFD7CCF8),
          borderSubtle: Color(0xFFC7B8F2),
          textMain: Color(0xFF4C1D95),
          textMuted: Color(0xFF6D28D9),
        );
      case 'amber':
        return const AppColors(
          background: Color(0xFFFFFBEB),
          primary: Color(0xFFD97706),
          primarySoft: Color(0x26D97706),
          secondary: Color(0xFFF59E0B),
          secondarySoft: Color(0x26F59E0B),
          accent: Color(0xFFFBBF24),
          accentSoft: Color(0x33FBBF24),
          danger: Color(0xFFEF4444),
          dangerSoft: Color(0x1AEF4444),
          success: Color(0xFF10B981),
          successSoft: Color(0x2610B981),
          purple: Color(0xFFF59E0B),
          surface: Color(0xFFFDE8C7),
          surface2: Color(0xFFF8DCAC),
          borderSubtle: Color(0xFFEDCCA1),
          textMain: Color(0xFF78350F),
          textMuted: Color(0xFF92400E),
        );
      case 'crimson':
        return const AppColors(
          background: Color(0xFFFFF1F2),
          primary: Color(0xFFE11D48),
          primarySoft: Color(0x26E11D48),
          secondary: Color(0xFFF43F5E),
          secondarySoft: Color(0x26F43F5E),
          accent: Color(0xFFFB7185),
          accentSoft: Color(0x33FB7185),
          danger: Color(0xFFEF4444),
          dangerSoft: Color(0x1AEF4444),
          success: Color(0xFF10B981),
          successSoft: Color(0x2610B981),
          purple: Color(0xFFF43F5E),
          surface: Color(0xFFFDD5DA),
          surface2: Color(0xFFFAC4CC),
          borderSubtle: Color(0xFFF3B4BE),
          textMain: Color(0xFF881337),
          textMuted: Color(0xFF9F1239),
        );
      case 'midnight':
        return const AppColors(
          background: Color(0xFFF8FAFC),
          primary: Color(0xFF334155),
          primarySoft: Color(0x26334155),
          secondary: Color(0xFF475569),
          secondarySoft: Color(0x26475569),
          accent: Color(0xFF64748B),
          accentSoft: Color(0x3364748B),
          danger: Color(0xFFEF4444),
          dangerSoft: Color(0x1AEF4444),
          success: Color(0xFF10B981),
          successSoft: Color(0x2610B981),
          purple: Color(0xFF475569),
          surface: Color(0xFFE2E8F0),
          surface2: Color(0xFFCBD5E1),
          borderSubtle: Color(0xFF94A3B8),
          textMain: Color(0xFF0F172A),
          textMuted: Color(0xFF334155),
        );
      case 'ocean':
      default:
        return const AppColors(
          background: Color(0xFFF0F3EC),
          primary: Color(0xFF447A9C),
          primarySoft: Color(0x26447A9C),
          secondary: Color(0xFF7DA2C8),
          secondarySoft: Color(0x267DA2C8),
          accent: Color(0xFF8DBEDE),
          accentSoft: Color(0x338DBEDE),
          danger: Color(0xFFEF4444),
          dangerSoft: Color(0x1AEF4444),
          success: Color(0xFF10B981),
          successSoft: Color(0x2610B981),
          purple: Color(0xFF7DA2C8),
          surface: Color(0xFFD2E1E9),
          surface2: Color(0xFFC0D3DF),
          borderSubtle: Color(0xFFBCCDD8),
          textMain: Color(0xFF2A4B61),
          textMuted: Color(0xFF5C7F9B),
        );
    }
  }

  static AppColors getDarkColors(String paletteKey) {
    switch (paletteKey) {
      case 'emerald':
        return const AppColors(
          background: Color(0xFF070F0D),
          primary: Color(0xFF10B981),
          primarySoft: Color(0x2810B981),
          secondary: Color(0xFF34D399),
          secondarySoft: Color(0x2834D399),
          accent: Color(0xFF6EE7B7),
          accentSoft: Color(0x286EE7B7),
          danger: Color(0xFFF43F5E),
          dangerSoft: Color(0x24F43F5E),
          success: Color(0xFF10B981),
          successSoft: Color(0x2810B981),
          purple: Color(0xFF34D399),
          surface: Color(0xFF0F1C18),
          surface2: Color(0xFF172B25),
          borderSubtle: Color(0x3334D399),
          textMain: Color(0xFFECFDF5),
          textMuted: Color(0xFF86EFAC),
        );
      case 'violet':
        return const AppColors(
          background: Color(0xFF0B0914),
          primary: Color(0xFF8B5CF6),
          primarySoft: Color(0x288B5CF6),
          secondary: Color(0xFFA78BFA),
          secondarySoft: Color(0x28A78BFA),
          accent: Color(0xFFC4B5FD),
          accentSoft: Color(0x28C4B5FD),
          danger: Color(0xFFF43F5E),
          dangerSoft: Color(0x24F43F5E),
          success: Color(0xFF10B981),
          successSoft: Color(0x2810B981),
          purple: Color(0xFF8B5CF6),
          surface: Color(0xFF151126),
          surface2: Color(0xFF211B3B),
          borderSubtle: Color(0x33A78BFA),
          textMain: Color(0xFFF5F3FF),
          textMuted: Color(0xFFC4B5FD),
        );
      case 'amber':
        return const AppColors(
          background: Color(0xFF120E06),
          primary: Color(0xFFF59E0B),
          primarySoft: Color(0x28F59E0B),
          secondary: Color(0xFFFBBF24),
          secondarySoft: Color(0x28FBBF24),
          accent: Color(0xFFFDE68A),
          accentSoft: Color(0x28FDE68A),
          danger: Color(0xFFF43F5E),
          dangerSoft: Color(0x24F43F5E),
          success: Color(0xFF10B981),
          successSoft: Color(0x2810B981),
          purple: Color(0xFFF59E0B),
          surface: Color(0xFF1C160B),
          surface2: Color(0xFF2A2112),
          borderSubtle: Color(0x33FBBF24),
          textMain: Color(0xFFFFFBEB),
          textMuted: Color(0xFFFDE68A),
        );
      case 'crimson':
        return const AppColors(
          background: Color(0xFF12080B),
          primary: Color(0xFFF43F5E),
          primarySoft: Color(0x28F43F5E),
          secondary: Color(0xFFFB7185),
          secondarySoft: Color(0x28FB7185),
          accent: Color(0xFFFDA4AF),
          accentSoft: Color(0x28FDA4AF),
          danger: Color(0xFFF43F5E),
          dangerSoft: Color(0x24F43F5E),
          success: Color(0xFF10B981),
          successSoft: Color(0x2810B981),
          purple: Color(0xFFFB7185),
          surface: Color(0xFF1D0E13),
          surface2: Color(0xFF2C161D),
          borderSubtle: Color(0x33FB7185),
          textMain: Color(0xFFFFF1F2),
          textMuted: Color(0xFFFDA4AF),
        );
      case 'midnight':
        return const AppColors(
          background: Color(0xFF090B0E),
          primary: Color(0xFF94A3B8),
          primarySoft: Color(0x2894A3B8),
          secondary: Color(0xFFCBD5E1),
          secondarySoft: Color(0x28CBD5E1),
          accent: Color(0xFFE2E8F0),
          accentSoft: Color(0x28E2E8F0),
          danger: Color(0xFFF43F5E),
          dangerSoft: Color(0x24F43F5E),
          success: Color(0xFF10B981),
          successSoft: Color(0x2810B981),
          purple: Color(0xFF94A3B8),
          surface: Color(0xFF12151B),
          surface2: Color(0xFF1B2028),
          borderSubtle: Color(0x2994A3B8),
          textMain: Color(0xFFF8FAFC),
          textMuted: Color(0xFF94A3B8),
        );
      case 'ocean':
      default:
        return const AppColors(
          background: Color(0xFF090D12),
          primary: Color(0xFF5B9EE1),
          primarySoft: Color(0x285B9EE1),
          secondary: Color(0xFF38BDF8),
          secondarySoft: Color(0x2838BDF8),
          accent: Color(0xFF7DD3FC),
          accentSoft: Color(0x287DD3FC),
          danger: Color(0xFFF43F5E),
          dangerSoft: Color(0x24F43F5E),
          success: Color(0xFF10B981),
          successSoft: Color(0x2810B981),
          purple: Color(0xFF818CF8),
          surface: Color(0xFF121822),
          surface2: Color(0xFF1A2332),
          borderSubtle: Color(0x335B9EE1),
          textMain: Color(0xFFF1F5F9),
          textMuted: Color(0xFF94A3B8),
        );
    }
  }

  static AppColors get lightColors => getLightColors('ocean');
  static AppColors get darkColors => getDarkColors('ocean');

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

  static ThemeData getTheme(Brightness brightness, [String paletteKey = 'ocean']) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? getDarkColors(paletteKey) : getLightColors(paletteKey);
    final baseTextTheme = isDark
        ? GoogleFonts.josefinSansTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.josefinSansTextTheme();

    return ThemeData(
      brightness: brightness,
      fontFamily: GoogleFonts.josefinSans().fontFamily,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: colors.primary,
              secondary: colors.secondary,
              surface: colors.surface,
              error: colors.danger,
            )
          : ColorScheme.light(
              primary: colors.primary,
              secondary: colors.secondary,
              surface: colors.surface,
              error: colors.danger,
            ),
      textTheme: baseTextTheme.apply(
        bodyColor: colors.textMain,
        displayColor: colors.textMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? colors.background
            : colors.surface.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.josefinSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textMain,
        ),
        iconTheme: IconThemeData(color: colors.textMain),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colors.borderSubtle,
            width: isDark ? 0.8 : 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.borderSubtle,
            width: isDark ? 0.8 : 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.borderSubtle,
            width: isDark ? 0.8 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.primary.withValues(alpha: isDark ? 0.6 : 1.0),
            width: isDark ? 1.5 : 2.0,
          ),
        ),
        labelStyle: TextStyle(color: colors.textMuted),
        hintStyle:
            TextStyle(color: colors.textMuted.withValues(alpha: 0.6)),
      ),
      extensions: [colors],
    );
  }

  static ThemeData get lightTheme => getTheme(Brightness.light, 'ocean');
  static ThemeData get darkTheme => getTheme(Brightness.dark, 'ocean');
}
