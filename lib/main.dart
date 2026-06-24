import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/config/api_config.dart';
import 'core/services/api_client.dart';
import 'core/services/storage_service.dart';
import 'core/services/tenant_service.dart';
import 'core/theme/app_theme.dart';
import 'documents/screens/document_detail_screen.dart';
import 'documents/screens/document_list_screen.dart';
import 'documents/screens/document_upload_screen.dart';
import 'documents/services/document_service.dart';
import 'documents/services/document_template_service.dart';
import 'notifications/screens/notifications_screen.dart';
import 'notifications/services/notification_service.dart';
import 'patients/services/patient_service.dart';
import 'patients/screens/patient_list_screen.dart';
import 'patients/screens/patient_form_screen.dart';
import 'security/screens/login_screen.dart';
import 'security/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize base configurations (uses .env prod URL in release mode)
  await ApiConfig.init();
  final storageService = await StorageService.getInstance();
  final apiClient = ApiClient(storageService);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(storageService),
        ),
        ChangeNotifierProvider<PatientService>(
          create: (_) => PatientService(apiClient),
        ),
        ChangeNotifierProvider<DocumentTemplateService>(
          create: (_) => DocumentTemplateService(apiClient),
        ),
        ChangeNotifierProvider<DocumentService>(
          create: (_) => DocumentService(apiClient),
        ),
        ChangeNotifierProvider<TenantService>(
          create: (_) => TenantService(apiClient),
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(apiClient),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestión Documental Clínica',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Dynamically use light/dark based on OS
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/documents': (context) => const DocumentListScreen(),
        '/document-detail': (context) => const DocumentDetailScreen(),
        '/document-upload': (context) => const DocumentUploadScreen(),
        '/patients': (context) => const PatientListScreen(),
        '/patient-form': (context) => const PatientFormScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Dynamic gateway that routes the user based on authentication status.
/// Displays a loading state while auto-login is being checked.
/// Also triggers tenant info fetch and notification initialization on successful authentication.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/iconSGDpng.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Comprobando sesión...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (authService.isAuthenticated) {
      // Fetch tenant info and initialize notifications once the user is authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tenantService = Provider.of<TenantService>(context, listen: false);
        if (tenantService.currentPlan == null) {
          tenantService.fetchTenantInfo();
        }

        final storageService = Provider.of<StorageService>(context, listen: false);
        final notificationService =
            Provider.of<NotificationService>(context, listen: false);
        notificationService.initialize(storageService);
      });
      return const DocumentListScreen();
    } else {
      return const LoginScreen();
    }
  }
}
