class ScriptModel {
  final String id;
  final String title;
  final String content;

  ScriptModel({
    required this.id,
    required this.title,
    required this.content,
  });

  ScriptModel copyWith({String? title, String? content}) {
    return ScriptModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}
