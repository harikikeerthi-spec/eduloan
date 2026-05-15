import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Using the singleton instance for version 7.2.0
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  /// Handles Google Sign-In and returns the Firebase User
  Future<User?> signInWithGoogle() async {
    try {
      // Ensure we start from a clean state to avoid "Account reauth failed" errors.
      // We wrap this in a try-catch to avoid crashing if no user is currently signed in.
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Note: Silent signOut failed (normal if no user was active): $e');
      }

      // 1. Trigger the Google Authentication flow
      // scopeHint requests permissions during the initial account selection.
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
      
      // 2. Obtain the idToken from authentication
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception("Failed to retrieve ID Token from Google Sign In.");
      }

      // 3. Try to get the access token, but don't fail if we can't
      // Firebase Auth often only strictly needs the idToken.
      String? accessToken;
      try {
        final GoogleSignInClientAuthorization? authz = await googleUser.authorizationClient.authorizationForScopes(['email', 'profile']);
        accessToken = authz?.accessToken;
      } catch (e) {
        debugPrint('Warning: Could not fetch access token: $e');
      }

      // 4. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // 5. Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      rethrow; 
    }
  }

  /// Handles Logout
  Future<void> signOut() async {
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
