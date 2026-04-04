import 'package:flutter/material.dart';
import 'package:sorade/core/brand_colors.dart';

ThemeData buildSoraDeTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandColors.primaryPink,
    onPrimary: BrandColors.darkBg,
    secondary: BrandColors.primaryGreen,
    onSecondary: BrandColors.cream,
    tertiary: BrandColors.accentGlow,
    onTertiary: BrandColors.darkBg,
    error: const Color(0xFFB3261E),
    onError: Colors.white,
    surface: BrandColors.softWhite,
    onSurface: BrandColors.primaryGreen,
    onSurfaceVariant: Color.lerp(BrandColors.primaryGreen, BrandColors.cream, 0.35)!,
    outline: BrandColors.primaryGreen.withValues(alpha: 0.28),
    outlineVariant: BrandColors.accentGlow.withValues(alpha: 0.65),
    shadow: BrandColors.darkBg.withValues(alpha: 0.18),
    scrim: BrandColors.darkBg.withValues(alpha: 0.45),
    inverseSurface: BrandColors.darkBg,
    onInverseSurface: BrandColors.cream,
    inversePrimary: BrandColors.accentGlow,
    surfaceTint: BrandColors.primaryPink,
    primaryContainer: BrandColors.accentGlow.withValues(alpha: 0.85),
    onPrimaryContainer: BrandColors.darkBg,
    secondaryContainer: BrandColors.primaryGreen.withValues(alpha: 0.12),
    onSecondaryContainer: BrandColors.primaryGreen,
    tertiaryContainer: BrandColors.accentGlow.withValues(alpha: 0.45),
    onTertiaryContainer: BrandColors.darkBg,
    surfaceContainerHighest: BrandColors.softWhite,
    surfaceContainerHigh: BrandColors.cream,
    surfaceContainer: BrandColors.softWhite,
    surfaceContainerLow: BrandColors.cream,
    surfaceContainerLowest: BrandColors.cream,
    surfaceDim: Color.lerp(BrandColors.cream, BrandColors.primaryGreen, 0.06)!,
    surfaceBright: BrandColors.softWhite,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: BrandColors.cream,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: BrandColors.cream,
      foregroundColor: BrandColors.primaryGreen,
      surfaceTintColor: BrandColors.primaryPink.withValues(alpha: 0.25),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: BrandColors.softWhite,
      surfaceTintColor: BrandColors.primaryPink.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: BrandColors.accentGlow.withValues(alpha: 0.45)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.primaryPink,
        foregroundColor: BrandColors.darkBg,
        disabledBackgroundColor: BrandColors.primaryPink.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.primaryGreen,
        foregroundColor: BrandColors.cream,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: BrandColors.primaryPink,
      foregroundColor: BrandColors.darkBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: BrandColors.softWhite,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BrandColors.darkBg,
      indicatorColor: BrandColors.primaryPink.withValues(alpha: 0.45),
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      height: 72,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: BrandColors.cream, size: 26);
        }
        return IconThemeData(
          color: BrandColors.softWhite.withValues(alpha: 0.55),
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final base = TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        );
        if (states.contains(WidgetState.selected)) {
          return base.copyWith(color: BrandColors.cream);
        }
        return base.copyWith(color: BrandColors.softWhite.withValues(alpha: 0.55));
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: BrandColors.softWhite,
      selectedColor: BrandColors.accentGlow.withValues(alpha: 0.7),
      labelStyle: TextStyle(color: BrandColors.primaryGreen, fontWeight: FontWeight.w600),
      secondaryLabelStyle: TextStyle(color: BrandColors.primaryGreen.withValues(alpha: 0.8)),
      side: BorderSide(color: BrandColors.primaryGreen.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: BrandColors.primaryGreen.withValues(alpha: 0.08),
      thickness: 1,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: BrandColors.softWhite,
      surfaceTintColor: BrandColors.primaryPink.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: BrandColors.softWhite,
      surfaceTintColor: BrandColors.primaryPink.withValues(alpha: 0.06),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );
}
