class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? createdAt;
  final String? reportId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.reportId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString(),
      reportId: json['report_id']?.toString(),
    );
  }
}
