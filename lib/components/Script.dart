import 'package:flutter/material.dart';

class ScriptItem {
  ScriptItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  final String id;
  String title;
  String content;
  final DateTime createdAt;
}

class _ScriptFormResult {
  const _ScriptFormResult({required this.title, required this.content});

  final String title;
  final String content;
}

class _ScriptFormDialog extends StatefulWidget {
  const _ScriptFormDialog({this.script});

  final ScriptItem? script;

  @override
  State<_ScriptFormDialog> createState() => _ScriptFormDialogState();
}

class _ScriptFormDialogState extends State<_ScriptFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.script?.title ?? '');
    _contentController = TextEditingController(
      text: widget.script?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final content = _contentController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Script'
        : _titleController.text.trim();

    Navigator.of(
      context,
    ).pop(_ScriptFormResult(title: title, content: content));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.script != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Script' : 'New Script'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Script title',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your script';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Enter or paste your script here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class Script extends StatefulWidget {
  const Script({super.key});

  @override
  State<Script> createState() => _ScriptState();
}

class _ScriptState extends State<Script> {
  final List<ScriptItem> _scripts = [];

  Future<void> _showScriptDialog({ScriptItem? script}) async {
    final result = await showDialog<_ScriptFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ScriptFormDialog(script: script),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (script == null) {
        _scripts.insert(
          0,
          ScriptItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: result.title,
            content: result.content,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        script.title = result.title;
        script.content = result.content;
      }
    });
  }

  void _confirmDelete(ScriptItem script) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Script'),
          content: Text('Are you sure you want to delete "${script.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _scripts.removeWhere((item) => item.id == script.id);
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Script',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showScriptDialog(),
                child: const Text(
                  '+ New Script',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _scripts.isEmpty
                ? const Center(
                    child: Text(
                      'No scripts yet.\nTap "+ New Script" to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _scripts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final script = _scripts[index];
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      script.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        _showScriptDialog(script: script),
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete',
                                    color: Colors.red,
                                    onPressed: () => _confirmDelete(script),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              Text(
                                script.content,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
