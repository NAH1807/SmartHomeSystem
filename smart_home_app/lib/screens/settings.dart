import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/setting_item.dart';

import '../services/api.dart';
import 'login.dart';

// import 'profile_setting.dart';
// import 'security_setting.dart';
// import 'notification_setting.dart';
// import 'appearance_setting.dart';
// import 'about_setting.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          // ========================================
          // HEADER
          // ========================================

          const Text(
            'Settings',

            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage your Smart Home',

            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 28),

          // ========================================
          // ACCOUNT
          // ========================================
          _section('Account', [
            SettingItem(
              icon: Icons.person_outline,
              title: 'Profile',

              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) =>
              //           const ProfileScreen(),
              //     ),
              //   );
              // },
            ),

            SettingItem(
              icon: Icons.security_outlined,
              title: 'Security',

              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) =>
              //           const SecurityScreen(),
              //     ),
              //   );
              // },
            ),
          ]),

          const SizedBox(height: 22),

          // ========================================
          // SMART HOME
          // ========================================
          _section('Smart Home', [
            SettingItem(
              icon: Icons.notifications_none,
              title: 'Notifications',

              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) =>
              //           const NotificationSettingsScreen(),
              //     ),
              //   );
              // },
            ),
          ]),

          const SizedBox(height: 22),

          // ========================================
          // APPLICATION
          // ========================================
          _section('Application', [
            SettingItem(
              icon: Icons.dark_mode_outlined,
              title: 'Appearance',

              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) =>
              //           const AppearanceScreen(),
              //     ),
              //   );
              // },
            ),

            SettingItem(
              icon: Icons.language_outlined,
              title: 'Language',

              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) =>
              //           const LanguageScreen(),
              //     ),
              //   );
              // },
            ),

            SettingItem(
              icon: Icons.info_outline,
              title: 'About',

              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) =>
              //           const AboutScreen(),
              //     ),
              //   );
              // },
            ),
          ]),

          const SizedBox(height: 30),

          // ========================================
          // LOGOUT
          // ========================================
          OutlinedButton.icon(
            onPressed: () {
              _logout(context);
            },

            icon: const Icon(Icons.logout, color: Colors.red),

            label: const Text('Logout', style: TextStyle(color: Colors.red)),

            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),

              side: const BorderSide(color: Colors.red),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'Smart Home v1.0.0',

              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SECTION
  // ========================================

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(20),
          ),

          child: Column(children: children),
        ),
      ],
    );
  }

  // ========================================
  // LOGOUT DIALOG
  // ========================================

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Đóng dialog
                Navigator.pop(dialogContext);

                try {
                  // Xóa JWT token
                  await context.read<ApiService>().clearToken();

                  if (!context.mounted) return;

                  // Quay về LoginScreen và xóa lịch sử điều hướng
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (error) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
