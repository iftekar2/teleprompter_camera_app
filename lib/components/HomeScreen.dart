import 'package:flutter/material.dart';
import 'package:teleprompter_camera_app/components/CreateScript.dart';
import 'package:teleprompter_camera_app/components/Script.dart';
import 'package:teleprompter_camera_app/components/Record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPage = 0;
  String? _activeScriptTitle;
  String? _activeScriptContent;
  final GlobalKey<NavigatorState> _scriptNavigatorKey =
      GlobalKey<NavigatorState>();

  void _useScriptInRecording(String title, String script) {
    setState(() {
      _activeScriptTitle = title;
      _activeScriptContent = script;
      _selectedPage = 0;
    });
    _scriptNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void _onItemTapped(int index) {
    if (_selectedPage == 1 && index != 1) {
      _scriptNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    setState(() {
      _selectedPage = index;
    });
  }

  Route<dynamic> _scriptRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/create':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Createscript(
            onUseInRecording: _useScriptInRecording,
          ),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const Script(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedPage,
        children: [
          Record(
            title: _activeScriptTitle,
            script: _activeScriptContent,
          ),
          Navigator(
            key: _scriptNavigatorKey,
            initialRoute: '/',
            onGenerateRoute: _scriptRoute,
          ),
        ],
      ),

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
