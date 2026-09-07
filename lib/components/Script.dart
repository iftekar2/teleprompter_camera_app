import 'package:flutter/material.dart';
import 'package:teleprompter_camera_app/components/CreateScript.dart';

class Script extends StatefulWidget {
  const Script({super.key});

  @override
  State<Script> createState() => _ScriptState();
}

class _ScriptState extends State<Script> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Script", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),

      body: Center(
        child: SizedBox(
          height: 60,
          width: 250,

          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Createscript()),
              );
            },

            child: const Text(
              '+ New Script',
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
