import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/mainpage.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'services/auth_services.dart';
import 'services/preference_service.dart';
import 'services/admin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isReady = false;
  bool _showHome = false;
  Widget _homeScreen = const WelcomePage();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final rememberLogin = await PreferenceService.isLogin();
    final isLoggedIn = AuthService.isLogin();

    if (!mounted) return;

    if (rememberLogin && isLoggedIn) {
      final isAdmin = await AdminService.isCurrentUserAdmin();
      if (!mounted) return;
      setState(() {
        _showHome = true;
        _homeScreen = isAdmin ? const AdminPanelScreen() : const MainPage();
        _isReady = true;
      });
      return;
    }

    setState(() {
      _showHome = false;
      _homeScreen = const WelcomePage();
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(home: _showHome ? _homeScreen : const WelcomePage());
  }
}