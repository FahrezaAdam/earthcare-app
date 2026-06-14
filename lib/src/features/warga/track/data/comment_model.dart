class CommentModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final String userName;
  final String? userAvatar;
  final String userRole;

  CommentModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userName,
    this.userAvatar,
    required this.userRole,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return CommentModel(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      userName: user['name'] as String? ?? 'Pengguna Anonim',
      userAvatar: user['avatar_url'] as String?,
      userRole: user['role'] as String? ?? 'warga',
    );
  }
}
