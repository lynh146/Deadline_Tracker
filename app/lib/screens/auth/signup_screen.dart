import 'package:flutter/material.dart';
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

  final _fnName = FocusNode();
  final _fnEmail = FocusNode();
  final _fnPass = FocusNode();
  final _fnConfirm = FocusNode();

  bool _touchedName = false;
  bool _touchedEmail = false;
  bool _touchedPass = false;
  bool _touchedConfirm = false;

  bool _agree = false;
  bool _loading = false;
  bool _showPassword = false;

  // ===== RULES =====
  bool _isGmail(String email) =>
      RegExp(r'^[^\s@]+@gmail\.com$').hasMatch(email.trim().toLowerCase());

  bool _isStrongPassword(String s) {
    return RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{6,}$',
    ).hasMatch(s);
  }

  String? _validateName(String v) {
    if (v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
    return null;
  }

  String? _validateEmail(String v) {
    final val = v.trim();
    if (val.isEmpty) return 'Vui lòng nhập email';
    if (!_isGmail(val)) return 'Email không đúng định dạng';
    return null;
  }

  String? _validatePass(String v) {
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (!_isStrongPassword(v)) {
      return 'Mật khẩu phải bao gồm: \n- Ít nhất 6 ký tự\n- Chữ hoa, chữ thường\n- Số\n- Ký tự đặc biệt';
    }
    return null;
  }

  String? _validateConfirm(String v) {
    if (v.isEmpty) return 'Vui lòng nhập lại mật khẩu';
    if (v != _pass.text) return 'Mật khẩu không khớp';
    return null;
  }

  bool get _canSubmit {
    return _validateName(_name.text) == null &&
        _validateEmail(_email.text) == null &&
        _validatePass(_pass.text) == null &&
        _validateConfirm(_confirmPass.text) == null &&
        _agree &&
        !_loading;
  }

  @override
  void initState() {
    super.initState();

    _fnName.addListener(() {
      if (_fnName.hasFocus && !_touchedName) {
        setState(() => _touchedName = true);
      }
    });

    _fnEmail.addListener(() {
      if (_fnEmail.hasFocus && !_touchedEmail) {
        setState(() => _touchedEmail = true);
      }
    });

    _fnPass.addListener(() {
      if (_fnPass.hasFocus && !_touchedPass) {
        setState(() => _touchedPass = true);
      }
    });

    _fnConfirm.addListener(() {
      if (_fnConfirm.hasFocus && !_touchedConfirm) {
        setState(() => _touchedConfirm = true);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _auth.signUpWithEmail(_email.text, _pass.text);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SignInScreen(showVerifyMessage: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Đăng ký thất bại' : msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    _fnName.dispose();
    _fnEmail.dispose();
    _fnPass.dispose();
    _fnConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameErr = _touchedName ? _validateName(_name.text) : null;
    final emailErr = _touchedEmail ? _validateEmail(_email.text) : null;
    final passErr = _touchedPass ? _validatePass(_pass.text) : null;
    final confirmErr = _touchedConfirm
        ? _validateConfirm(_confirmPass.text)
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
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

                  _textField(
                    controller: _name,
                    focusNode: _fnName,
                    hint: 'Họ và tên',
                    errorText: nameErr,
                  ),
                  const SizedBox(height: 12),

                  _textField(
                    controller: _email,
                    focusNode: _fnEmail,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    errorText: emailErr,
                  ),
                  const SizedBox(height: 12),

                  _passwordField(
                    controller: _pass,
                    focusNode: _fnPass,
                    hint: 'Mật khẩu',
                    errorText: passErr,
                  ),
                  const SizedBox(height: 12),

                  _passwordField(
                    controller: _confirmPass,
                    focusNode: _fnConfirm,
                    hint: 'Nhập lại mật khẩu',
                    errorText: confirmErr,
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
                      onPressed: _canSubmit ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canSubmit
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

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: _decoration(hint, errorText: errorText),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !_showPassword,
      onChanged: (_) => setState(() {}),
      decoration: _decoration(
        hint,
        errorText: errorText,
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

  InputDecoration _decoration(
    String hint, {
    Widget? suffix,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffix,
      errorText: errorText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText == null ? AppColors.border : Colors.red,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText == null ? AppColors.primary : Colors.red,
          width: 1.4,
        ),
      ),
    );
  }
}
