import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'preference_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ============================
  /// REGISTER
  /// ============================
  static Future<String?> register(UserModel user) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      
      // Save user info to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'avatar': user.avatar,
        'gender': user.gender,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      if (e.code == 'weak-password') return 'Mật khẩu quá yếu.';
      if (e.code == 'email-already-in-use') return 'Email đã được sử dụng.';
      if (e.code == 'operation-not-allowed') return 'Bạn chưa bật phương thức đăng nhập bằng Email/Password trong Firebase Console.';
      return "Lỗi Auth (${e.code}): ${e.message}";
    } catch (e) {
      print("Lỗi hệ thống: $e");
      return "Lỗi hệ thống: $e";
    }
  }

  /// ============================
  /// LOGIN
  /// ============================
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Lưu lịch sử đăng nhập local
      await PreferenceService.addHistory(email);

      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email' || e.code == 'invalid-credential') return 'Sai tài khoản hoặc mật khẩu.';
      if (e.code == 'wrong-password') return 'Sai mật khẩu.';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// ============================
  /// USER HIỆN TẠI
  /// ============================
  static Future<UserModel?> currentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return UserModel(
            fullName: data['fullName'] ?? 'No Name',
            email: data['email'] ?? user.email ?? '',
            phone: data['phone'] ?? '',
            password: '', // We don't fetch password from DB
            avatar: data['avatar'] ?? 'https://i.pravatar.cc/300',
            gender: data['gender'] ?? 'Male',
          );
        }
      } catch (e) {
        print("Lỗi lấy dữ liệu user: $e");
      }
    }
    return null;
  }

  /// ============================
  /// KIỂM TRA ĐĂNG NHẬP
  /// ============================
  static bool isLogin() {
    return _auth.currentUser != null;
  }

  /// ============================
  /// LOGOUT
  /// ============================
  static Future<void> logout() async {
    await _auth.signOut();
    await PreferenceService.logout();
  }

  /// ============================
  /// LỊCH SỬ ĐĂNG NHẬP
  /// ============================
  static Future<List<String>> getHistory() async {
    return await PreferenceService.getHistory();
  }

  /// ============================
  /// KIỂM TRA EMAIL ĐÃ TỒN TẠI
  /// ============================
  static Future<bool> isExistEmail(String email) async {
    // FirebaseAuth sẽ tự báo lỗi nếu email trùng trong lúc register
    return false;
  }
}
