import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // EMAIL SIGN UP
  Future<void> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (!cred.user!.emailVerified) {
      await cred.user!.sendEmailVerification();
    }

    // logout để verify trước khi login
    await _auth.signOut();
  }

  // EMAIL SIGN IN
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // GOOGLE
  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
  }

  // FACEBOOK
  Future<void> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return;

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.token,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  // quên mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
