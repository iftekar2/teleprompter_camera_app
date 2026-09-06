import 'package:flutter/material.dart';
import 'package:teleprompter_camera_app/components/BottomNavigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(bottomNavigationBar: const BottomNavigation());
  }
}
