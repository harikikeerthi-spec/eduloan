import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Using the singleton instance for version 7.2.0
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Handles Google Sign-In and returns the Firebase User
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Authentication flow
      // In version 7.2.0, the method is 'authenticate()'
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      
      // 2. Obtain the access token via authorizeScopes
      // We need these scopes for the access token
      final List<String> scopes = ['email', 'profile'];
      final GoogleSignInClientAuthorization authz = await googleUser.authorizationClient.authorizeScopes(scopes);
      
      // 3. Obtain the idToken from authentication
      final auth = googleUser.authentication;
      final GoogleSignInAuthentication googleAuth = auth is Future ? await auth : auth;

      // 4. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: googleAuth.idToken,
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
