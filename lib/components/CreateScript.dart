import 'package:flutter/material.dart';

class Createscript extends StatelessWidget {
  const Createscript({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 120,
        leading: InkWell(
          onTap: () => Navigator.maybePop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 20),
              Icon(Icons.arrow_back, color: Colors.black),
              SizedBox(width: 4),
              Text(
                'Scripts',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),

      body: Center(child: Text("You can create a new Script here")),
    );
  }
}
