import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/app_strings.dart'; 

class AdminService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // No BuildContext is available in a static service, so we read the
  // current locale directly from LocaleController instead of AppStrings.of(context).
  static AppStrings get _s => AppStrings(LocaleController.locale.value);

  /// Admin login
  /// Only accounts with a UID in the `admins` collection
  /// are allowed to sign in to the Admin Panel.
  static Future<String?> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;

      if (user == null) {
        return _s.authenticationFailed;
      }

      // Check whether the UID exists in the admins collection
      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      if (!adminDoc.exists) {
        await _auth.signOut();
        return _s.notAnAdministrator;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return _s.noAccountFoundEmail;

        case 'wrong-password':
          return _s.incorrectPassword;

        case 'invalid-email':
          return _s.invalidEmailAddress;

        case 'invalid-credential':
          return _s.incorrectEmailOrPassword;

        default:
          return e.message ?? _s.adminSignInFailed;
      }
    } catch (e) {
      return _s.errorOccurredWith(e.toString());
    }
  }

  /// Check whether the current user is an Admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }
    try {
      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      return adminDoc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Log out
  static Future<void> signOutAdmin() async {
    await _auth.signOut();
  }

  /// Check whether the user is already logged in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return _s.noAccountFoundEmail;

        case 'wrong-password':
          return _s.incorrectPassword;

        case 'invalid-email':
          return _s.invalidEmailAddress;

        default:
          return e.message;
      }
    }
  }
}