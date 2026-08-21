import 'package:flutter/material.dart';

import '../widgets/setting_item.dart';

import 'profile_setting.dart';
import 'security_setting.dart';
import 'home_management_setting.dart';
import 'notification_setting.dart';
import 'automation_setting.dart';
import 'appearance_setting.dart';
import 'about_setting.dart';

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

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage your Smart Home',

            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 28),

          // ========================================
          // ACCOUNT
          // ========================================

          _section(
            'Account',

            [
              SettingItem(
                icon: Icons.person_outline,
                title: 'Profile',

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProfileScreen(),
                    ),
                  );
                },
              ),

              SettingItem(
                icon: Icons.security_outlined,
                title: 'Security',

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SecurityScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ========================================
          // SMART HOME
          // ========================================

          _section(
            'Smart Home',

            [
              SettingItem(
                icon: Icons.home_outlined,
                title: 'Home Management',

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const HomeManagementScreen(),
                    ),
                  );
                },
              ),

              SettingItem(
                icon: Icons.notifications_none,
                title: 'Notifications',

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),

              SettingItem(
                icon: Icons.schedule_outlined,
                title: 'Automation',

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AutomationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ========================================
          // APPLICATION
          // ========================================

          _section(
            'Application',

            [
              SettingItem(
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AppearanceScreen(),
                    ),
                  );
                },
              ),

              SettingItem(
                icon: Icons.info_outline,
                title: 'About',

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ========================================
          // LOGOUT
          // ========================================

          OutlinedButton.icon(
            onPressed: () {
              _showLogoutDialog(context);
            },

            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),

            label: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
              ),
            ),

            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),

              side: const BorderSide(
                color: Colors.red,
              ),

              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'Smart Home v1.0.0',

              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SECTION
  // ========================================

  Widget _section(
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

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

            borderRadius:
                BorderRadius.circular(20),
          ),

          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // ========================================
  // LOGOUT DIALOG
  // ========================================

  void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),

          content: const Text(
            'Are you sure you want to logout?',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Logout successful',
                    ),
                  ),
                );
              },

              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );
  }
}