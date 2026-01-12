import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../home/app_shell.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        //LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        //CHƯA LOGIN
        if (user == null) {
          return const _SplashUI();
        }

        //CHECK PROVIDER
        final providerIds = user.providerData.map((e) => e.providerId).toList();

        final isPasswordLogin = providerIds.contains('password');

        //CHƯA VERIFY (CHỈ EMAIL/PASSWORD)
        if (isPasswordLogin && !user.emailVerified) {
          auth.signOut();
          return const SignInScreen(showVerifyMessage: true);
        }

        return const AppShell();
      },
    );
  }
}

class _SplashUI extends StatelessWidget {
  const _SplashUI();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purpleStart, AppColors.purpleEnd],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Timely',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quản lý công việc của bạn',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: 180,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text('Đăng nhập'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: 180,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'Đăng ký',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
