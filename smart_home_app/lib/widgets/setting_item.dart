import 'package:flutter/material.dart';

class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const SettingItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF4F46E5),
      ),

      title: Text(title),

      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),

      onTap: onTap,
    );
  }
}