import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/mainpage.dart';
import 'services/admin_service.dart';
import 'services/auth_services.dart';
import 'services/preference_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  await Hive.openBox<dynamic>('cartBox');

  final CartProvider cartProvider = CartProvider();
  await cartProvider.loadCart();

  runApp(
    ChangeNotifierProvider<CartProvider>.value(
      value: cartProvider,
      child: const MainApp(),
    ),
  );
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
    final bool rememberLogin = await PreferenceService.isLogin();
    final bool isLoggedIn = AuthService.isLogin();

    if (!mounted) {
      return;
    }

    if (rememberLogin && isLoggedIn) {
      final bool isAdmin = await AdminService.isCurrentUserAdmin();

      if (!mounted) {
        return;
      }

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
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _showHome ? _homeScreen : const WelcomePage(),
    );
  }
}
