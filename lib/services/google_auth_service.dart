import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // google_sign_in v6 uses GoogleSignIn() constructor, not singleton
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '496981213875-7imkhflkb3b805bo6fga84hqpe7dapcr.apps.googleusercontent.com',
  );

  /// Handles Google Sign-In and returns the Firebase User
  Future<User?> signInWithGoogle() async {
    try {
      // Force account picker to appear every time by clearing any cached session
      await _googleSignIn.signOut().catchError((_) {});
      await _googleSignIn.disconnect().catchError((_) {});

      // 1. Trigger the Google Authentication flow — always shows account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in dialog, googleUser is null
      if (googleUser == null) {
        debugPrint('Google Sign-In was cancelled by user');
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Failed to retrieve ID Token from Google Sign In.');
      }

      // 3. Create Firebase credential and sign in
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Handles Logout
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Error during Google disconnect: $e');
    }
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error during Sign-Out: $e');
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;
}
