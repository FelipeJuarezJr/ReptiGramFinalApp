import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
    ],
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // Try silent sign-in first
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser == null) {
          // On web, the button should be rendered in the widget tree (see below)
          // and signIn() should only be called after user interaction.
          return null;
        }
      } else {
        // On mobile, show the sign-in dialog
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }
} 