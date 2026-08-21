import 'package:flutter/material.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() =>
      _AppearanceScreenState();
}

class _AppearanceScreenState
    extends State<AppearanceScreen> {

  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appearance',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [

          Card(
            elevation: 0,

            child: Column(
              children: [

                SwitchListTile(
                  secondary: const Icon(
                    Icons.dark_mode_outlined,
                  ),

                  title: const Text(
                    'Dark Mode',
                  ),

                  subtitle: const Text(
                    'Use dark theme',
                  ),

                  value: darkMode,

                  onChanged: (value) {
                    setState(() {
                      darkMode = value;
                    });
                  },
                ),

                const Divider(),

                const ListTile(
                  leading: Icon(
                    Icons.language,
                  ),

                  title: Text(
                    'Language',
                  ),

                  subtitle: Text(
                    'English',
                  ),

                  trailing: Icon(
                    Icons.chevron_right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}