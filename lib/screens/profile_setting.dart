import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {

  final nameController =
      TextEditingController(
    text: 'Smart Home User',
  );

  final emailController =
      TextEditingController(
    text: 'user@smarthome.local',
  );

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();

    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Profile saved successfully',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [

          const Center(
            child: CircleAvatar(
              radius: 50,

              child: Icon(
                Icons.person,
                size: 55,
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: nameController,

            decoration: InputDecoration(
              prefixIcon:
                  const Icon(Icons.person_outline),

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: emailController,

            decoration: InputDecoration(
              prefixIcon:
                  const Icon(Icons.email_outlined),

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 52,

            child: FilledButton(
              onPressed: _saveProfile,

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