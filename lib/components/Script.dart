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
      // appBar: AppBar(
      //   title: const Text(
      //     'Script',
      //     style: TextStyle(fontWeight: FontWeight.w600),
      //   ),
      //   backgroundColor: Colors.white,
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          //   child: SizedBox(
          //     height: 60,
          //     child: OutlinedButton(
          //       onPressed: onNewScript,
          //       child: const Text(
          //         '+ New Script',
          //         style: TextStyle(color: Colors.black, fontSize: 18),
          //       ),
          //     ),
          //   ),
          // ),
          Expanded(
            child: scripts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 50, right: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 200,
                          width: 200,

                          child: Image.asset(
                            'lib/components/image/empty-folder-image.png',
                          ),
                        ),

                        Text(
                          'No scripts yet',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 10),
                        Text(
                          "You don't have a script yet. Create one to get started!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                        ),

                        SizedBox(height: 15),
                        SizedBox(
                          height: 55,
                          width: 200,
                          child: TextButton(
                            onPressed: onNewScript,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                232,
                                242,
                                250,
                              ),

                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),

                            child: Text(
                              "+  Create Script",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 115, 255),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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
