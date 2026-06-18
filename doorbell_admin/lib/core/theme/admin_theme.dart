import 'package:flutter/material.dart';

/// Premium dark admin theme with green accent.
class AdminTheme {
  AdminTheme._();

  static const _primary = Color(0xFF34C759);
  static const _surface = Color(0xFF1E1E2E);
  static const _background = Color(0xFF11111B);
  static const _card = Color(0xFF252540);
  static const _border = Color(0xFF313152);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: _primary,
          secondary: const Color(0xFF00B894),
          surface: _surface,
          error: const Color(0xFFE74C3C),
        ),
        scaffoldBackgroundColor: _background,
        cardColor: _card,
        dividerColor: _border,
        appBarTheme: const AppBarTheme(
          backgroundColor: _surface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: _surface,
          selectedIconTheme: const IconThemeData(color: _primary),
          unselectedIconTheme: IconThemeData(color: Colors.white.withAlpha(120)),
          selectedLabelTextStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w600),
          unselectedLabelTextStyle: TextStyle(color: Colors.white.withAlpha(120)),
        ),
        cardTheme: CardThemeData(
          color: _card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border),
          ),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(_card),
          dataRowColor: WidgetStateProperty.all(Colors.transparent),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      );
}
