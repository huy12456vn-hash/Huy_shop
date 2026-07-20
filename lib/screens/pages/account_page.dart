import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_services.dart';

import 'home_page.dart';
import 'wishlist_page.dart';
import 'category_page.dart';
import '../auth/welcome_screen.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String initials = user?.email?.substring(0, 2).toUpperCase() ?? 'LV';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // AVATAR
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC5A059), width: 2),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF1A472A),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Salesperson',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              Text(
                user?.email ?? 'example@email.com',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // ===== ACCOUNT =====
              _buildSectionTitle('My Account'),
              _buildWhiteCard([
                _buildMenuItem(
                  context,
                  Icons.shopping_bag_outlined,
                  'My Orders',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomePage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.location_on_outlined,
                  'Delivery Address',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoryPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.person_outline,
                  'Personal Information',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistPage()),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // ===== SETTINGS =====
              _buildSectionTitle('Settings'),
              _buildWhiteCard([
                _buildMenuItem(
                  context,
                  Icons.settings_outlined,
                  'Account Settings',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomePage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.language,
                  'Language (English)',
                  () {
                    print("Change language");
                  },
                ),
              ]),

              const SizedBox(height: 40),

              // LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A472A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Log out',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC5A059),
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A472A)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
