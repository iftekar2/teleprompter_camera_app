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

      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(height: 20),

              TextField(
                decoration: InputDecoration(
                  hintText: "Enter Title of Script",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 30),
              SizedBox(
                child: TextField(
                  maxLines: 16,
                  decoration: InputDecoration(
                    hintText: "Type or paste your script here...",
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                    ),

                    contentPadding: const EdgeInsets.only(
                      left: 24.0,
                      top: 12.0,
                      right: 16.0,
                      bottom: 16.0,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2.0,
                      ),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                  ),

                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
