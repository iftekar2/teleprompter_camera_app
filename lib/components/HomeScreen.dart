import 'package:flutter/material.dart';
import 'package:teleprompter_camera_app/components/Script.dart';
import 'package:teleprompter_camera_app/components/Record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPage = 0;

  final List<Widget> _pages = const [Record(), Script()];

  //final List<String> _titles = const ['Record', 'Scripts'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedPage, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
        ),

        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.white,
          currentIndex: _selectedPage,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade400,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_camera_front_outlined, size: 28),
              activeIcon: Icon(Icons.video_camera_front, size: 28),
              label: 'Record',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined, size: 28),
              activeIcon: Icon(Icons.description, size: 28),
              label: 'Script',
            ),
          ],
        ),
      ),
    );
  }
}
