import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/face_detection_provider.dart';
import 'presentation/screens/face_detector_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FaceDetectionProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const FaceDetectorScreen(),
      ),
    );
  }
}
