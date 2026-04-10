import 'package:flutter/material.dart';

import '../../data/inventory_repository.dart';
import '../../models/app_user.dart';
import '../desktop/desktop_login_screen.dart';
import '../desktop/desktop_shell_screen_v2.dart';
import '../mobile/mobile_login_screen.dart';
import '../mobile/mobile_monitoring_screen.dart';

class ResponsiveRootScreen extends StatefulWidget {
  const ResponsiveRootScreen({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final InventoryRepository repository;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<ResponsiveRootScreen> createState() => _ResponsiveRootScreenState();
}

class _ResponsiveRootScreenState extends State<ResponsiveRootScreen> {
  bool _desktopLoggedIn = false;
  bool _mobileLoggedIn = false;
  AppUser? _currentUser;
  AppUser? _mobileUser;

  void _login(AppUser user) {
    setState(() {
      _desktopLoggedIn = true;
      _currentUser = user;
    });
  }

  void _logout() {
    setState(() {
      _desktopLoggedIn = false;
      _currentUser = null;
    });
  }

  void _loginMobile(AppUser user) {
    setState(() {
      _mobileLoggedIn = true;
      _mobileUser = user;
    });
  }

  void _logoutMobile() {
    setState(() {
      _mobileLoggedIn = false;
      _mobileUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          if (!_desktopLoggedIn) {
            return DesktopLoginScreen(
              repository: widget.repository,
              onLogin: _login,
            );
          }

          return DesktopShellScreen(
            repository: widget.repository,
            themeMode: widget.themeMode,
            onToggleTheme: widget.onToggleTheme,
            currentUser: _currentUser!,
            onLogout: _logout,
          );
        }

        if (!_mobileLoggedIn) {
          return MobileLoginScreen(
            repository: widget.repository,
            onLogin: _loginMobile,
          );
        }

        return MobileMonitoringScreen(
          repository: widget.repository,
          themeMode: widget.themeMode,
          onToggleTheme: widget.onToggleTheme,
          currentUser: _mobileUser!,
          onLogout: _logoutMobile,
        );
      },
    );
  }
}
