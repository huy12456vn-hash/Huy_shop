import 'package:flutter/material.dart';
import '../../services/auth_services.dart';
import '../../l10n/app_strings.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  Future<void> _resetPassword() async {
  final t = AppStrings.of(context);

  if (_emailController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.pleaseEnterEmail)));
    return;
  }

  setState(() => _isLoading = true);

  String? result = await AuthService.sendPasswordResetEmail(
    _emailController.text.trim(),
  );

  setState(() => _isLoading = false);

  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.resetLinkSent),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result), backgroundColor: Colors.red),
    );
  }
}

  @override
  void dispose() {
    _emailController.dispose();
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
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F5F0),
          elevation: 0,
          centerTitle: true,
          title: Text(t.forgotPasswordTitle, style: const TextStyle(color: Colors.black)),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.resetYourPassword,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                t.resetPasswordSubtitle,
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: t.emailHint,
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A472A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          t.sendResetLink,
                          style: const TextStyle(color: Colors.white, letterSpacing: 1),
                        ),
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
