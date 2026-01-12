import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();

  bool _agree = false;
  bool _loading = false;
  bool _showPassword = false;

  bool get _passwordMatch =>
      _pass.text.isNotEmpty &&
      _confirmPass.text.isNotEmpty &&
      _pass.text == _confirmPass.text;

  bool get _isValid =>
      _name.text.isNotEmpty &&
      _email.text.isNotEmpty &&
      _passwordMatch &&
      _agree &&
      !_loading;

  Future<void> _submit() async {
    setState(() => _loading = true);

    try {
      await _auth.signUpWithEmail(_email.text.trim(), _pass.text.trim());

      if (!mounted) return;

      // signup → signin + tb verify email
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SignInScreen(showVerifyMessage: true),
        ),
      );
    } catch (e) {
      String message = 'Đăng ký thất bại';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            message = 'Email này đã được đăng ký';
            break;
          case 'invalid-email':
            message = 'Email không hợp lệ';
            break;
          case 'weak-password':
            message = 'Mật khẩu phải có ít nhất 6 ký tự';
            break;
          default:
            message = e.message ?? message;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: e is FirebaseAuthException && e.code == 'email-already-in-use'
              ? SnackBarAction(
                  label: 'Đăng nhập',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  },
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          //HEADER
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purpleStart, AppColors.purpleEnd],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Đăng ký',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _input(_name, 'Họ và tên'),
                  const SizedBox(height: 12),
                  _input(_email, 'Email'),
                  const SizedBox(height: 12),

                  _passwordField(_pass, 'Mật khẩu'),
                  const SizedBox(height: 12),

                  _passwordField(_confirmPass, 'Nhập lại mật khẩu'),
                  if (_confirmPass.text.isNotEmpty && !_passwordMatch)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Mật khẩu không khớp',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: _agree,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _agree = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Tôi đồng ý với điều khoản sử dụng',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isValid ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isValid
                            ? AppColors.primary
                            : AppColors.disabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Đăng ký',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),

                  //LINK TO SIGN IN
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Bạn đã có tài khoản? ',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //HELPERS

  Widget _input(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      decoration: _decoration(hint),
    );
  }

  Widget _passwordField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      obscureText: !_showPassword,
      onChanged: (_) => setState(() {}),
      decoration: _decoration(
        hint,
        suffix: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}
