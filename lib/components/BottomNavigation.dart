import 'package:flutter/material.dart';
import 'package:teleprompter_camera_app/components/Script.dart';
import 'package:teleprompter_camera_app/components/Record.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedPage = 0;

  final List<Widget> _pages = const [Record(), Script()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedPage, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedPage,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_camera_front_outlined, size: 35),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined, size: 35),
            label: 'Script',
          ),
        ],
      ),
    );
  }
}
