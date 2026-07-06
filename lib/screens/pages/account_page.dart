// account_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_services.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Hàm xử lý đăng xuất
  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Sử dụng tên viết tắt từ email hoặc mặc định
    final String initials = user?.email?.substring(0, 2).toUpperCase() ?? 'LV';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Màu kem sang trọng
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Ảnh đại diện
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC5A059),
                    width: 2,
                  ), // Viền vàng kim
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF1A472A), // Màu xanh rêu
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
              // Tên người dùng
              const Text(
                'Người bán hàng',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Serif',
                ),
              ),
              Text(
                user?.email ?? 'huy@gmail.com',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Nhóm mục tài khoản
              _buildSectionTitle('Tài khoản của tôi'),
              _buildWhiteCard([
                _buildMenuItem(Icons.shopping_bag_outlined, 'Đơn hàng của tôi'),
                _buildMenuItem(Icons.location_on_outlined, 'Địa chỉ giao hàng'),
                _buildMenuItem(Icons.person_outline, 'Thông tin cá nhân'),
                _buildMenuItem(Icons.payment, 'Phương thức thanh toán'),
              ]),

              const SizedBox(height: 20),

              // Nhóm cài đặt
              _buildSectionTitle('Cài đặt'),
              _buildWhiteCard([
                _buildMenuItem(Icons.settings_outlined, 'Cài đặt tài khoản'),
                _buildMenuItem(Icons.language, 'Ngôn ngữ (Tiếng Việt)'),
              ]),

              const SizedBox(height: 40),

              // Nút Đăng xuất
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A472A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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

  // Widget tiêu đề nhóm
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

  // Widget thẻ trắng bo góc
  Widget _buildWhiteCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Widget item menu
  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A472A), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () {},
    );
  }
}
