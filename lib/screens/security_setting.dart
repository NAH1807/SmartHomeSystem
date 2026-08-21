import 'package:flutter/material.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() =>
      _SecurityScreenState();
}

class _SecurityScreenState
    extends State<SecurityScreen> {

  bool biometric = false;
  bool loginNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
            ),

            child: Column(
              children: [

                SwitchListTile(
                  secondary: const Icon(
                    Icons.fingerprint,
                  ),

                  title: const Text(
                    'Biometric Authentication',
                  ),

                  subtitle: const Text(
                    'Use fingerprint or Face ID',
                  ),

                  value: biometric,

                  onChanged: (value) {
                    setState(() {
                      biometric = value;
                    });
                  },
                ),

                const Divider(),

                SwitchListTile(
                  secondary: const Icon(
                    Icons.login,
                  ),

                  title: const Text(
                    'Login Notifications',
                  ),

                  subtitle: const Text(
                    'Notify me when a new login occurs',
                  ),

                  value: loginNotification,

                  onChanged: (value) {
                    setState(() {
                      loginNotification = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(
              Icons.lock_outline,
            ),

            title: const Text(
              'Change Password',
            ),

            trailing: const Icon(
              Icons.chevron_right,
            ),

            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Password management will be connected to Backend later.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}