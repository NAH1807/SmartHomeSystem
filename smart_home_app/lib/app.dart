import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_home_app/providers/camera.dart';
import 'package:smart_home_app/repositories/camera.dart';
import 'package:smart_home_app/services/camera_recording.dart';

import 'screens/login.dart';
import 'services/api.dart';
import 'repositories/device.dart';
import 'providers/device.dart';
import 'providers/motion.dart';
import 'repositories/motion.dart';
import 'theme/app.dart';

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final cameraRecordingService = CameraRecordingService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        
        ChangeNotifierProvider<DeviceProvider>(
          create: (_) => DeviceProvider(
            repository: DeviceRepository(apiService: apiService),
          ), //..loadDevices(),
        ),

        ChangeNotifierProvider<MotionProvider>(
          create: (_) => MotionProvider(
            repository: MotionRepository(apiService: apiService),
          ),
        ),

        ChangeNotifierProvider<CameraProvider>(
          create: (_) => CameraProvider(
            cameraId: '',
            repository: CameraRepository(cameraRecordingService),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Home',
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
