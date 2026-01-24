import 'package:app/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _oldPasswordController.addListener(() {
      if (_oldPasswordError != null) {
        setState(() => _oldPasswordError = null);
      }
    });
    _newPasswordController.addListener(() {
      if (_newPasswordError != null) {
        setState(() => _newPasswordError = null);
      }
    });
    _confirmPasswordController.addListener(() {
      if (_confirmPasswordError != null) {
        setState(() => _confirmPasswordError = null);
      }
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool hasError = false;

    // reset lỗi cũ
    _oldPasswordError = null;
    _newPasswordError = null;
    _confirmPasswordError = null;

    // validate tay
    if (oldPassword.isEmpty) {
      _oldPasswordError = 'Vui lòng nhập mật khẩu hiện tại.';
      hasError = true;
    }

    if (newPassword.isEmpty) {
      _newPasswordError = 'Vui lòng nhập mật khẩu mới.';
      hasError = true;
    } else if (newPassword.length < 6) {
      _newPasswordError = 'Mật khẩu phải có ít nhất 6 ký tự.';
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Vui lòng xác nhận mật khẩu mới.';
      hasError = true;
    } else if (newPassword != confirmPassword) {
      _confirmPasswordError = 'Mật khẩu không khớp.';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      _showSnackBar('Không thể xác thực người dùng.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _oldPasswordError = null;
        _newPasswordError = null;
      });

      if (e.code == 'weak-password') {
        setState(() {
          _newPasswordError = 'Mật khẩu phải có ít nhất 6 ký tự.';
        });
      } else {
        setState(() {
          _oldPasswordError = 'Mật khẩu hiện tại không đúng.';
        });
      }
    } catch (_) {
      _showSnackBar('Đã có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _PasswordField(
              controller: _oldPasswordController,
              labelText: 'Mật khẩu hiện tại',
              errorText: _oldPasswordError,
            ),
            const SizedBox(height: 16),
            _PasswordField(
              controller: _newPasswordController,
              labelText: 'Mật khẩu mới',
              errorText: _newPasswordError,
            ),
            const SizedBox(height: 16),
            _PasswordField(
              controller: _confirmPasswordController,
              labelText: 'Xác nhận mật khẩu mới',
              errorText: _confirmPasswordError,
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Lưu thay đổi',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.labelText,
    this.errorText,
  });

  final TextEditingController controller;
  final String labelText;
  final String? errorText;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;
    final Color errorColor = Colors.red.shade700;

    return TextField(
      controller: widget.controller,
      obscureText: _isObscured,
      decoration: InputDecoration(
        labelText: widget.labelText,
        errorText: widget.errorText,
        labelStyle: TextStyle(color: hasError ? errorColor : null),
        errorStyle: TextStyle(color: errorColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility_off : Icons.visibility,
            color: hasError ? errorColor : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        ),
      ),
    );
  }
}
