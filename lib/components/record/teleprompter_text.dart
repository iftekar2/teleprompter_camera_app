import 'package:flutter/material.dart';

class TeleprompterText extends StatelessWidget {
  final ScrollController scrollController;
  final String script;
  final double fontSize;

  const TeleprompterText({
    super.key,
    required this.scrollController,
    required this.script,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 40,
        ),
        child: Text(
          script,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            height: 1.6,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 8,
                color: Colors.black,
              ),
              Shadow(
                offset: Offset(0, 0),
                blurRadius: 4,
                color: Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
