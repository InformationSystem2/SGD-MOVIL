// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/tenant_service.dart';
import '../../security/services/auth_service.dart';
import '../../help/widgets/help_sheet.dart';
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
    final tenantService = Provider.of<TenantService>(context);
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
                // Plan badge
                if (tenantService.currentPlan != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'Plan ${tenantService.currentPlan}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
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
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  icon: Icons.document_scanner_rounded,
                  title: 'Escanear Documento',
                  route: '/document-upload',
                  locked: !tenantService.canUseScan,
                  requiredPlan: 'PRO',
                ),
                const Divider(height: 32, indent: 8, endIndent: 8),
                _buildNavItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Ayuda',
                  route: '__help__',
                ),
                const SizedBox(height: 4),
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
    bool locked = false,
    String? requiredPlan,
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

    if (locked) {
      iconColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
      textColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    }

    return Material(
      color: tileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: 14,
                ),
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 10, color: AppTheme.warning),
                    const SizedBox(width: 2),
                    Text(
                      requiredPlan ?? 'PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        dense: true,
        onTap: () async {
          Navigator.of(context).pop(); // Close drawer

          if (locked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🔒 Esta función requiere el plan $requiredPlan o superior. Contacte a su administrador.',
                ),
                backgroundColor: AppTheme.warning,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }

          if (route == '__help__') {
            showHelpSheet(context);
            return;
          }

          if (isLogout) {
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
            return;
          }

          if (!isActive) {
            if (route == '/document-upload') {
              Navigator.of(context).pushNamed(route, arguments: {'scanOnly': true});
            } else {
              Navigator.of(context).pushReplacementNamed(route);
            }
          }
        },
      ),
    );
  }
}
