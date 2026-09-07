import 'package:flutter/material.dart';
import 'package:teleprompter_camera_app/components/HomeScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Teleprompter App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}
