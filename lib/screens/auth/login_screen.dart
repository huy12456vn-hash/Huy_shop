import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';

import 'forgot_password_screen.dart';

import '../../services/preference_service.dart';
import '../../services/admin_service.dart';
import '../../l10n/app_strings.dart';

import '../mainpage.dart';
import '../admin/admin_panel_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _isLoading = false;

  bool _obscurePassword = true;

  bool _rememberMe = false;

  Future<void> _login() async {
    final t = AppStrings.of(context);

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage(t.enterEmailPassword);

      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final error = await AdminService.signIn(
        email: email,
        password: password,
      );

      if (error != null) {
        if (!mounted) return;
        _showMessage(error);
        return;
      }

      await PreferenceService.setLogin(_rememberMe);

      final isAdmin = await AdminService.isCurrentUserAdmin();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin ? const AdminPanelScreen() : const MainPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final t = AppStrings.of(context);
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = t.userNotFound;

          break;

        case 'wrong-password':
          message = t.wrongPassword;

          break;

        case 'invalid-email':
          message = t.invalidEmail;

          break;

        case 'invalid-credential':
          message = t.invalidCredential;

          break;

        default:
          message = "${t.loginFailed}: ${e.message}";
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showMessage("${AppStrings.of(context).errorOccurred}: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final t = AppStrings(locale);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F5F0),

          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 320,

                  width: double.infinity,

                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://images.unsplash.com/photo-1542291026-7eec264c27ff",
                      ),

                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),

                  child: Column(
                    children: [
                      const Text(
                        "GUCCI",

                        style: TextStyle(
                          fontSize: 42,

                          fontWeight: FontWeight.bold,

                          letterSpacing: 8,

                          color: Color(0xFF1A472A),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        t.welcomeBack,

                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        t.signInSubtitle,

                        textAlign: TextAlign.center,

                        style: const TextStyle(color: Colors.black54),
                      ),

                      const SizedBox(height: 35),

                      TextField(
                        controller: _emailController,

                        keyboardType: TextInputType.emailAddress,

                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),

                          hintText: t.emailHint,

                          filled: true,

                          fillColor: Colors.white,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: _passwordController,

                        obscureText: _obscurePassword,

                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),

                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),

                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),

                          hintText: t.passwordHint,

                          filled: true,

                          fillColor: Colors.white,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,

                            activeColor: const Color(0xFF1A472A),

                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                          ),

                          Text(
                            t.rememberMe,

                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            t.forgotPassword,
                            style: const TextStyle(color: Color(0xFF1A472A)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,

                        height: 58,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A472A),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),

                          onPressed: _isLoading ? null : _login,

                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,

                                  height: 22,

                                  child: CircularProgressIndicator(
                                    color: Colors.white,

                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  t.loginButton,

                                  style: const TextStyle(
                                    color: Colors.white,

                                    fontSize: 18,

                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          const Expanded(child: Divider()),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),

                            child: Text(t.orDivider),
                          ),

                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,

                        height: 55,

                        child: OutlinedButton.icon(
                          onPressed: () {},

                          icon: const Icon(
                            Icons.g_mobiledata,

                            size: 30,
                            color: Colors.red,
                          ),

                          label: Text(
                            t.continueWithGoogle,

                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,

                        height: 55,

                        child: OutlinedButton.icon(
                          onPressed: () {},

                          icon: const Icon(Icons.apple, color: Colors.black),

                          label: Text(
                            t.continueWithApple,

                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text(t.noAccountYet),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },

                            child: Text(
                              t.registerLink,

                              style: const TextStyle(
                                color: Color(0xFF1A472A),

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}