import 'package:flutter/material.dart';

import '../widgets/setting_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding:
            const EdgeInsets.all(20),

        children: [
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

          _section(
            'Account',
            [
              const SettingItem(
                icon: Icons.person_outline,
                title: 'Profile',
              ),

              const SettingItem(
                icon: Icons.security_outlined,
                title: 'Security',
              ),
            ],
          ),

          const SizedBox(height: 22),

          _section(
            'Smart Home',
            [
              const SettingItem(
                icon: Icons.home_outlined,
                title: 'Home Management',
              ),

              const SettingItem(
                icon:
                    Icons.notifications_none,
                title: 'Notifications',
              ),

              const SettingItem(
                icon:
                    Icons.schedule_outlined,
                title: 'Automation',
              ),
            ],
          ),

          const SizedBox(height: 22),

          _section(
            'Application',
            [
              const SettingItem(
                icon:
                    Icons.dark_mode_outlined,
                title: 'Appearance',
              ),

              const SettingItem(
                icon: Icons.info_outline,
                title: 'About',
              ),
            ],
          ),
        ],
      ),
    );
  }

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
          decoration:
              BoxDecoration(
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
}