import 'package:flutter/material.dart';
import 'package:teleprompter_camera_app/models/script_model.dart';

class Createscript extends StatefulWidget {
  final ScriptModel? initialScript;
  final void Function(String title, String script)? onUseInRecording;

  const Createscript({super.key, this.initialScript, this.onUseInRecording});

  @override
  State<Createscript> createState() => _CreatescriptState();
}

class _CreatescriptState extends State<Createscript> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _scriptController = TextEditingController();

  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_validateForm);
    _scriptController.addListener(_validateForm);

    if (widget.initialScript != null) {
      _titleController.text = widget.initialScript!.title;
      _scriptController.text = widget.initialScript!.content;
      _validateForm();
    }
  }

  void _validateForm() {
    final isValid =
        _titleController.text.trim().isNotEmpty &&
        _scriptController.text.trim().isNotEmpty;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _isFormValid ? Colors.black : Colors.grey.shade400;

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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "Enter Title of Script",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                child: TextField(
                  controller: _scriptController,
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

                  style: const TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 60,
                child: OutlinedButton(
                  onPressed: _isFormValid
                      ? () {
                          widget.onUseInRecording?.call(
                            _titleController.text.trim(),
                            _scriptController.text.trim(),
                          );
                        }
                      : null,

                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.video_camera_front_outlined,
                          size: 28,
                          color: buttonColor,
                        ),

                        const SizedBox(width: 10),
                        Text(
                          "Use in recording",
                          style: TextStyle(fontSize: 20, color: buttonColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
