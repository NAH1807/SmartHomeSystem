import 'package:flutter/material.dart';

class NotificationSettingsScreen
    extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {

  bool deviceAlert = true;
  bool securityAlert = true;
  bool automationAlert = true;
  bool aiSecurityAlert = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [

          SwitchListTile(
            title: const Text(
              'Device Alerts',
            ),

            subtitle: const Text(
              'Device state changes',
            ),

            value: deviceAlert,

            onChanged: (value) {
              setState(() {
                deviceAlert = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text(
              'Security Alerts',
            ),

            subtitle: const Text(
              'Security related notifications',
            ),

            value: securityAlert,

            onChanged: (value) {
              setState(() {
                securityAlert = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text(
              'Automation',
            ),

            subtitle: const Text(
              'Automation execution notifications',
            ),

            value: automationAlert,

            onChanged: (value) {
              setState(() {
                automationAlert = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text(
              'AI Security Alerts',
            ),

            subtitle: const Text(
              'Potential IoT attacks detected by AI',
            ),

            value: aiSecurityAlert,

            onChanged: (value) {
              setState(() {
                aiSecurityAlert = value;
              });
            },
          ),
        ],
      ),
    );
  }
}