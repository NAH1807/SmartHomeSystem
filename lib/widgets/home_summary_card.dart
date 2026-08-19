import 'package:flutter/material.dart';

class HomeSummaryCard extends StatelessWidget {
  const HomeSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(28),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.home_rounded,
                color: Colors.white,
              ),

              SizedBox(width: 8),

              Text(
                'My Smart Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              _summaryItem(
                Icons.devices_other,
                '24',
                'Devices',
              ),

              const SizedBox(width: 30),

              _summaryItem(
                Icons.wifi,
                '18',
                'Online',
              ),

              const SizedBox(width: 30),

              _summaryItem(
                Icons.error_outline,
                '0',
                'Alerts',
              ),
            ],
          ),

          const SizedBox(height: 22),

          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),

          const SizedBox(height: 18),

          const Row(
            children: [
              Expanded(
                child: _EnvironmentItem(
                  icon: Icons.thermostat_outlined,
                  value: '28°C',
                  label: 'Temperature',
                ),
              ),

              Expanded(
                child: _EnvironmentItem(
                  icon: Icons.water_drop_outlined,
                  value: '65%',
                  label: 'Humidity',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _summaryItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 22,
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnvironmentItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _EnvironmentItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 25,
        ),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}