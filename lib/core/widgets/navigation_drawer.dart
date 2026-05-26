// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../security/services/auth_service.dart';
import '../theme/app_theme.dart';

class NavigationDrawerWidget extends StatelessWidget {
  final String activeRoute;

  const NavigationDrawerWidget({
    super.key,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [AppTheme.primaryDark, AppTheme.bgSurfaceDark] 
                    : [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      'assets/iconSGDpng.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SGD CLÍNICO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestión Documental Médica',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const Divider(height: 24, color: Colors.white24),
                // Current User Info
                Row(
                  children: [
                    const Icon(Icons.account_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authService.currentUser ?? 'Usuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Drawer Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.people_outline_rounded,
                  title: 'Pacientes',
                  route: '/patients',
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Documentos',
                  route: '/documents',
                ),
                const Divider(height: 32, indent: 8, endIndent: 8),
                _buildNavItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Cerrar Sesión',
                  route: '/logout',
                  isLogout: true,
                ),
              ],
            ),
          ),
          
          // Drawer Footer Version Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Versión 1.0.0',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isLogout = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = activeRoute == route;

    Color tileColor = Colors.transparent;
    Color iconColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    Color textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    FontWeight fontWeight = FontWeight.w500;

    if (isActive) {
      tileColor = isDark ? AppTheme.primary.withOpacity(0.12) : AppTheme.primary50;
      iconColor = AppTheme.primary;
      textColor = AppTheme.primary;
      fontWeight = FontWeight.bold;
    }

    if (isLogout) {
      iconColor = AppTheme.error;
      textColor = AppTheme.error;
    }

    return Material(
      color: tileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
            fontSize: 14,
          ),
        ),
        dense: true,
        onTap: () async {
          // Close drawer
          Navigator.of(context).pop();

          if (isLogout) {
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
            return;
          }

          if (!isActive) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
    );
  }
}
