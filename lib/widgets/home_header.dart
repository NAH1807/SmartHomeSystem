import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: const Color(0xFFE8E9FF),
            borderRadius: BorderRadius.circular(16),
          ),

          child: const Icon(
            Icons.home_rounded,
            color: Color(0xFF4F46E5),
            size: 26,
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good evening 👋',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              SizedBox(height: 2),

              Text(
                'Hào',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
          ),
        ),

        const CircleAvatar(
          radius: 21,
          backgroundColor: Color(0xFFE5E7EB),

          child: Icon(
            Icons.person_outline,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}