import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_services.dart';
import '../../l10n/app_strings.dart';
import '../auth/welcome_screen.dart';
import 'order_history_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static const String _languageKey = 'account_language';

  String _fullName = '';
  String _phoneNumber = '';
  String _deliveryAddress = '';
  String _currentLanguage = 'English';
  bool _isLoadingProfile = true;

  User? get _user => _firebaseAuth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _fullName =
          preferences.getString('account_full_name') ??
          _user?.displayName ??
          '';

      _phoneNumber = preferences.getString('account_phone_number') ?? '';

      _deliveryAddress =
          preferences.getString('account_delivery_address') ?? '';

      _currentLanguage = preferences.getString(_languageKey) ?? 'English';
      _isLoadingProfile = false;
    });

    LocaleController.setLanguage(_currentLanguage);
  }

  Future<void> _saveProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString('account_full_name', fullName.trim());

    await preferences.setString('account_phone_number', phoneNumber.trim());

    await _user?.updateDisplayName(fullName.trim());
    await _user?.reload();

    if (!mounted) {
      return;
    }

    setState(() {
      _fullName = fullName.trim();
      _phoneNumber = phoneNumber.trim();
    });

    _showMessage(AppStrings.of(context).personalInfoUpdated);
  }

  Future<void> _saveDeliveryAddress(String address) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString('account_delivery_address', address.trim());

    if (!mounted) {
      return;
    }

    setState(() {
      _deliveryAddress = address.trim();
    });

    _showMessage(AppStrings.of(context).deliveryAddressSaved);
  }

  Future<void> _logout() async {
    final t = AppStrings.of(context);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.logoutTitle),
          content: Text(t.logoutConfirm),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: Text(t.logout),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await AuthService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  Future<void> _openPersonalInformation() async {
    final nameController = TextEditingController(text: _fullName);

    final phoneController = TextEditingController(text: _phoneNumber);

    final formKey = GlobalKey<FormState>();

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Update your name and phone number.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';

                      if (phone.isEmpty) {
                        return 'Please enter your phone number.';
                      }

                      if (phone.length < 9) {
                        return 'Please enter a valid phone number.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _user?.email ?? '',
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) {
                          return;
                        }

                        Navigator.pop(sheetContext, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Save changes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldSave == true) {
      await _saveProfile(
        fullName: nameController.text,
        phoneNumber: phoneController.text,
      );
    }

    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _openDeliveryAddress() async {
    final addressController = TextEditingController(text: _deliveryAddress);

    final formKey = GlobalKey<FormState>();

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Delivery Address',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter the address where you want to receive your order.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: addressController,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 58),
                        child: Icon(Icons.location_on_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your delivery address.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) {
                          return;
                        }

                        Navigator.pop(sheetContext, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Save address',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldSave == true) {
      await _saveDeliveryAddress(addressController.text);
    }

    addressController.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _user?.email;

    if (email == null || email.isEmpty) {
      _showMessage('No email address was found.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change password'),
          content: Text('A password reset link will be sent to:\n\n$email'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send email'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);

      _showMessage('Password reset email sent successfully.');
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Unable to send password reset email.');
    }
  }

  Future<void> _openAccountSettings() async {
    final t = AppStrings.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.accountSettings,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF2F2F2),
                    child: Icon(Icons.lock_reset, color: Colors.black87),
                  ),
                  title: Text(
                    t.changePassword,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(t.changePasswordSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _sendPasswordResetEmail();
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF2F2F2),
                    child: Icon(Icons.email_outlined, color: Colors.black87),
                  ),
                  title: Text(
                    t.accountEmail,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_user?.email ?? t.noEmail),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveLanguage(String language) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, language);
    LocaleController.setLanguage(language);
  }

  Future<void> _openLanguage() async {
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'English',
                groupValue: _currentLanguage,
                title: const Text('English'),
                subtitle: const Text('Current language'),
                onChanged: (value) {
                  Navigator.pop(dialogContext, value);
                },
              ),
              RadioListTile<String>(
                value: 'Tiếng Việt',
                groupValue: _currentLanguage,
                title: const Text('Tiếng Việt'),
                subtitle: const Text('Chuyển sang giao diện tiếng Việt'),
                onChanged: (value) {
                  Navigator.pop(dialogContext, value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    if (selectedLanguage == null || selectedLanguage == _currentLanguage) {
      return;
    }

    await _saveLanguage(selectedLanguage);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentLanguage = selectedLanguage;
    });

    _showMessage('${AppStrings.of(context).languageChangedTo} $selectedLanguage.');
  }

  void _openHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'For support, please contact our customer service team.\n\n'
            'Email: support@guccishop.com\n'
            'Working hours: 8:00 AM - 5:00 PM',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _getInitials() {
    final source = _fullName.trim().isNotEmpty
        ? _fullName.trim()
        : (_user?.email?.split('@').first ?? 'GU');

    final words = source
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();

    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }

    if (source.length >= 2) {
      return source.substring(0, 2).toUpperCase();
    }

    return source.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final t = AppStrings(locale);
        final email = _user?.email ?? t.noEmail;
        final accountName = _fullName.trim().isEmpty ? 'Gucci Account' : _fullName;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: _isLoadingProfile
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
                    child: Column(
                      children: [
                        _buildProfileHeader(
                          initials: _getInitials(),
                          accountName: accountName,
                          email: email,
                          t: t,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(t.myAccount),
                        const SizedBox(height: 10),
                        _buildMenuCard(
                          children: [
                            _buildMenuItem(
                              icon: Icons.receipt_long_outlined,
                              title: t.myOrders,
                              subtitle: t.myOrdersSubtitle,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OrderHistoryPage(),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.location_on_outlined,
                              title: t.deliveryAddress,
                              subtitle: _deliveryAddress.isEmpty
                                  ? t.addDeliveryAddress
                                  : _deliveryAddress,
                              onTap: _openDeliveryAddress,
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              title: t.personalInfo,
                              subtitle: t.personalInfoSubtitle,
                              onTap: _openPersonalInformation,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(t.settings),
                        const SizedBox(height: 10),
                        _buildMenuCard(
                          children: [
                            _buildMenuItem(
                              icon: Icons.settings_outlined,
                              title: t.accountSettings,
                              subtitle: t.accountSettingsSubtitle,
                              onTap: _openAccountSettings,
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.language,
                              title: t.language,
                              subtitle: _currentLanguage,
                              onTap: _openLanguage,
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              title: t.helpSupport,
                              subtitle: t.helpSupportSubtitle,
                              onTap: _openHelp,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, size: 20),
                            label: Text(
                              t.logout,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader({
    required String initials,
    required String accountName,
    required String email,
    required AppStrings t,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE9E9E9),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.black,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            accountName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (_phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              _phoneNumber,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 17,
                  color: Colors.black87,
                ),
                const SizedBox(width: 6),
                Text(
                  t.signedIn,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 22, color: Colors.black87),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 70,
      endIndent: 16,
      color: Color(0xFFEEEEEE),
    );
  }
}