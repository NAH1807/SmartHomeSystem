import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              Container(
                width: 100,
                height: 100,

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,

                  borderRadius:
                      BorderRadius.circular(25),
                ),

                child: const Icon(
                  Icons.home_work_outlined,

                  size: 55,

                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Smart Home',

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Smart Home Management System',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Version 1.0.0',
              ),

              const SizedBox(height: 20),

              const Text(
                'Flutter • Dart • MQTT • FastAPI',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                '© 2026 Smart Home Project',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}