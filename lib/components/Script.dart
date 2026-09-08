import 'package:flutter/material.dart';
import 'package:teleprompter_camera_app/models/script_model.dart';

class Script extends StatelessWidget {
  final List<ScriptModel> scripts;
  final VoidCallback onNewScript;
  final void Function(ScriptModel script) onEdit;
  final void Function(String id) onDelete;

  const Script({
    super.key,
    required this.scripts,
    required this.onNewScript,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context, ScriptModel script) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete script?'),
        content: Text('Delete "${script.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDelete(script.id);
    }
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SizedBox(
              height: 60,
              child: OutlinedButton(
                onPressed: onNewScript,
                child: const Text(
                  '+ New Script',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
          ),

          Expanded(
            child: scripts.isEmpty
                ? Center(
                    child: Text(
                      'No scripts yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: scripts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final script = scripts[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: InkWell(
                          onTap: () => onEdit(script),
                          borderRadius: BorderRadius.circular(24),

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),

                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromARGB(255, 129, 129, 129),
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        script.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),

                                      const SizedBox(height: 4),
                                      Text(
                                        script.content,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Right Action: Trash Icon
                                IconButton(
                                  onPressed: () =>
                                      _confirmDelete(context, script),
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.black,
                                  tooltip: 'Delete',
                                  iconSize: 30,
                                ),
                              ],
                            ),
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
