import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app/core/theme/app_colors.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  Future<void> _reloadUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    user = FirebaseAuth.instance.currentUser;
    setState(() {});
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || user == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref('avatars/${user!.uid}');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await user!.updatePhotoURL(url);
      await _reloadUser();
    } catch (e) {
      // Handle errors here
    } finally {
      if(mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              // Pop the dialog
              Navigator.of(ctx).pop(); 
              // Pop until the root of the app to go to the sign-in screen
              Navigator.of(context, rootNavigator: true)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              /// AVATAR
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : (user?.photoURL == null
                            ? const Icon(Icons.person, size: 42, color: Colors.white)
                            : null),
                  ),
                  GestureDetector(
                    onTap: _isUploading ? null : _changeAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// NAME
              Text(
                user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Chưa đặt tên',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 36),

              _menuItem(
                'Sửa trang cá nhân',
                () async {
                  final result = await Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  if (result == true) {
                    await _reloadUser();
                  }
                },
              ),

              const SizedBox(height: 16),

              _menuItem(
                'Đổi mật khẩu',
                () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 80),

              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _confirmSignOut(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(title, style: const TextStyle(color: AppColors.primary)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
