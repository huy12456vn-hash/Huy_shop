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
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: user.email,
            password: user.password,
          );
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'avatar': user.avatar,
        'gender': user.gender,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      if (e.code == 'weak-password') return 'Password is too weak.';
      if (e.code == 'email-already-in-use') return 'Email is already in use.';
      if (e.code == 'operation-not-allowed')
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      return "Auth error (${e.code}): ${e.message}";
    } catch (e) {
      print("System error: $e");
      return "System error: $e";
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

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-email' ||
          e.code == 'invalid-credential')
        return 'Incorrect email or password.';
      if (e.code == 'wrong-password') return 'Incorrect password.';
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
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
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
        print("Error fetching user data: $e");
      }
    }
    return null;
  }

  /// ============================
  /// CHECK LOGIN STATUS
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
  /// LOGIN HISTORY
  /// ============================
  static Future<List<String>> getHistory() async {
    return await PreferenceService.getHistory();
  }

  /// ============================
  /// CHECK IF EMAIL EXISTS
  /// ============================
  static Future<bool> isExistEmail(String email) async {
    // FirebaseAuth sẽ tự báo lỗi nếu email trùng trong lúc register
    return false;
  }

  /// ============================
  /// FORGOT PASSWORD
  /// ============================
  static Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')
        return 'No account was found for this email.';
      if (e.code == 'invalid-email') return 'Invalid email address.';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
