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
    const primary = Color(0xFF5B39EA);
    final pageBg = isDark ? const Color(0xFF0B1020) : const Color(0xFFF6F8FC);
    final surface = isDark ? const Color(0xFF141A2B) : Colors.white;
    final elevatedSurface = isDark ? const Color(0xFF1B2236) : const Color(0xFFFBFCFF);
    final outline = isDark ? const Color(0xFF28314B) : const Color(0xFFE4EAF4);
    final onSurface = isDark ? const Color(0xFFF3F6FF) : const Color(0xFF1D2433);
    final onSurfaceSoft = isDark ? const Color(0xFFA5B0C8) : const Color(0xFF697389);
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: pageBg,
      canvasColor: surface,
      dividerColor: outline,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          textStyle: base.textTheme.titleLarge,
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.poppins(
          textStyle: base.textTheme.titleMedium,
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: GoogleFonts.workSans(
          textStyle: base.textTheme.bodyMedium,
          color: onSurfaceSoft,
        ),
        bodySmall: GoogleFonts.workSans(
          textStyle: base.textTheme.bodySmall,
          color: isDark ? const Color(0xFF8E99B5) : const Color(0xFF7E8698),
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: const Color(0xFF9B8CF9),
        surface: surface,
        onSurface: onSurface,
        outline: outline,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurfaceSoft,
          hoverColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF5B39EA).withValues(alpha: 0.06),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedSurface,
        hintStyle: GoogleFonts.workSans(color: isDark ? const Color(0xFF8F98B2) : const Color(0xFFA3A9B8)),
        labelStyle: GoogleFonts.workSans(color: onSurfaceSoft),
        helperStyle: GoogleFonts.workSans(color: onSurfaceSoft),
        floatingLabelStyle: GoogleFonts.workSans(color: isDark ? const Color(0xFFD8DEEF) : primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outline),
        ),
        titleTextStyle: GoogleFonts.poppins(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.workSans(
          color: onSurfaceSoft,
          height: 1.5,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: outline),
        ),
        textStyle: GoogleFonts.workSans(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A2235) : const Color(0xFF1F2533),
        contentTextStyle: GoogleFonts.workSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          isDark ? const Color(0xFF1A2235) : const Color(0xFFF5F7FC),
        ),
        dataRowColor: WidgetStatePropertyAll(
          isDark ? const Color(0xFF141A2B) : Colors.white,
        ),
        headingTextStyle: GoogleFonts.poppins(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        dataTextStyle: GoogleFonts.workSans(
          color: onSurfaceSoft,
          fontWeight: FontWeight.w600,
        ),
        dividerThickness: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.24),
        selectionHandleColor: primary,
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
