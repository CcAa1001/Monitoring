import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/inventory_repository.dart';
import 'features/root/responsive_root_screen.dart';

class MonitoringApp extends StatefulWidget {
  const MonitoringApp({
    super.key,
    required this.repository,
  });

  final InventoryRepository repository;

  @override
  State<MonitoringApp> createState() => _MonitoringAppState();
}

class _MonitoringAppState extends State<MonitoringApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5B39EA),
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F1220) : const Color(0xFFF7F8FC),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.workSans(
          textStyle: base.textTheme.bodyMedium,
          color: isDark ? const Color(0xFFD6DBE8) : const Color(0xFF4F5565),
        ),
        bodySmall: GoogleFonts.workSans(
          textStyle: base.textTheme.bodySmall,
          color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF7E8698),
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF5B39EA),
        secondary: const Color(0xFF9B8CF9),
        surface: isDark ? const Color(0xFF171B2D) : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1D2433),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1D2433),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF171B2D) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF5B39EA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1C2238) : Colors.white,
        hintStyle: GoogleFonts.workSans(color: isDark ? const Color(0xFF8F98B2) : const Color(0xFFA3A9B8)),
        labelStyle: GoogleFonts.workSans(color: isDark ? const Color(0xFFB7C0D6) : const Color(0xFF6B7384)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Factory Monitoring',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: ResponsiveRootScreen(
        repository: widget.repository,
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
