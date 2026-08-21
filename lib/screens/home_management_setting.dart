import 'package:flutter/material.dart';

class HomeManagementScreen extends StatefulWidget {
  const HomeManagementScreen({super.key});

  @override
  State<HomeManagementScreen> createState() =>
      _HomeManagementScreenState();
}

class _HomeManagementScreenState
    extends State<HomeManagementScreen> {

  final TextEditingController homeNameController =
      TextEditingController(
    text: 'My Smart Home',
  );

  @override
  void dispose() {
    homeNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home Management',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [

          const Text(
            'Home Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: homeNameController,

            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.home_outlined,
              ),

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Card(
            elevation: 0,

            child: Column(
              children: [

                ListTile(
                  leading: const Icon(
                    Icons.meeting_room_outlined,
                  ),

                  title: const Text(
                    'Rooms',
                  ),

                  trailing: const Text(
                    '4',
                  ),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(
                    Icons.devices_other_outlined,
                  ),

                  title: const Text(
                    'Devices',
                  ),

                  trailing: const Text(
                    '10',
                  ),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(
                    Icons.router_outlined,
                  ),

                  title: const Text(
                    'Gateway',
                  ),

                  trailing: const Text(
                    'Offline',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 52,

            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Home settings saved',
                    ),
                  ),
                );
              },

              child: const Text(
                'Save Changes',
              ),
            ),
          ),
        ],
      ),
    );
  }
}