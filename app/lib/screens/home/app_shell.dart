import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('APP CHÍNH'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth
                  .signOut(); // logout -> quay về SignIn nhờ Splash stream
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(child: Text('Đăng nhập thành công')),
    );
  }
}
