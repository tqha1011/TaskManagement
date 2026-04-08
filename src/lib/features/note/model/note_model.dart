class NoteModel {
  final String id;
  final String content;
  final bool pinned;
  final String? imagePath;

  NoteModel({
    required this.id,
    required this.content,
    this.pinned = false,
    this.imagePath,
  });
}
