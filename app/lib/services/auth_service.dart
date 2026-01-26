import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  bool _isGmail(String email) {
    final e = email.trim().toLowerCase();
    return RegExp(r'^[^\s@]+@gmail\.com$').hasMatch(e);
  }

  //check pass
  bool _isStrongPassword(String s) {
    return RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{6,}$',
    ).hasMatch(s);
  }

  // EMAIL SIGN UP
  Future<void> signUpWithEmail(String email, String password) async {
    final e = email.trim();
    final p = password;

    if (e.isEmpty) throw 'Vui lòng nhập email';
    if (!_isGmail(e)) throw 'Email không đúng định dạng';

    if (p.isEmpty) throw 'Vui lòng nhập mật khẩu';
    if (!_isStrongPassword(p)) {
      throw 'Mật khẩu >= 6 ký tự, gồm: HOA + thường + số + ký tự đặc biệt';
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: e,
        password: p,
      );

      if (cred.user != null && !cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
      }

      await _auth.signOut();
    } on FirebaseAuthException catch (ex) {
      switch (ex.code) {
        case 'email-already-in-use':
          throw 'Email này đã được đăng ký';
        case 'invalid-email':
          throw 'Email không đúng định dạng';
        case 'weak-password':
          throw 'Mật khẩu quá yếu';
        case 'operation-not-allowed':
          throw 'Email/Password chưa được bật trên Firebase';
        case 'network-request-failed':
          throw 'Lỗi mạng. Vui lòng kiểm tra Internet';
        default:
          throw ex.message ?? 'Đăng ký thất bại';
      }
    } catch (_) {
      throw 'Đăng ký thất bại';
    }
  }

  // EMAIL SIGN IN
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (_) {
      throw 'Đã xảy ra lỗi. Vui lòng thử lại';
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không đúng định dạng';
      case 'user-not-found':
        return 'Email chưa được đăng ký';
      case 'wrong-password':
        return 'Mật khẩu không chính xác';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Thao tác quá nhiều lần, vui lòng thử lại sau';
      case 'network-request-failed':
        return 'Lỗi mạng. Vui lòng kiểm tra Internet';
      default:
        return 'Đăng nhập thất bại. Vui lòng kiểm tra lại';
    }
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

  // QUÊN MẬT KHẨU
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw 'Email không đúng định dạng';
        case 'user-not-found':
          throw 'Email chưa được đăng ký';
        case 'too-many-requests':
          throw 'Thao tác quá nhiều lần, vui lòng thử lại sau';
        case 'network-request-failed':
          throw 'Lỗi mạng. Vui lòng kiểm tra Internet';
        default:
          throw e.message ?? 'Không gửi được email đặt lại mật khẩu';
      }
    } catch (_) {
      throw 'Không gửi được email đặt lại mật khẩu';
    }
  }
}
