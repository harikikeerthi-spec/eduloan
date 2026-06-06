import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Handles Google Sign-In and returns the Firebase User
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Authentication flow using the singleton
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // 2. Obtain the auth details — NOTE: must await in google_sign_in v7
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception("Failed to retrieve ID Token from Google Sign In.");
      }

      // 3. Try to get the access token (optional — Firebase often only needs idToken)
      String? accessToken;
      try {
        final GoogleSignInClientAuthorization? authz =
            await googleUser.authorizationClient
                .authorizationForScopes(['email', 'profile']);
        accessToken = authz?.accessToken;
      } catch (e) {
        debugPrint('Warning: Could not fetch access token (non-fatal): $e');
      }

      // 4. Create Firebase credential and sign in
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
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error during Sign-Out: $e');
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;
}
