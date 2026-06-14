class ReportModel {
  final String id;
  final String ticketId;
  final String title;
  final String category;
  final String location;
  final String time;
  final String
  status; // 'received', 'verified', 'assigned', 'in_progress', 'resolved'
  final bool isCompleted;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final String? userId;
  final String? description;
  final String? reporterName;
  final String? reporterAvatar;
  final String? reporterPhone;
  final String? assignedOfficerId;
  final int commentCount;

  ReportModel({
    required this.id,
    required this.ticketId,
    required this.title,
    required this.category,
    required this.location,
    required this.time,
    required this.status,
    required this.isCompleted,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.userId,
    this.description,
    this.reporterName,
    this.reporterAvatar,
    this.reporterPhone,
    this.assignedOfficerId,
    this.commentCount = 0,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Map status from API to isCompleted
    final apiStatus = json['status']?.toString().toLowerCase() ?? 'received';
    final completed = apiStatus == 'resolved';
    
    int count = 0;
    if (json['report_comments'] is List && (json['report_comments'] as List).isNotEmpty) {
      count = json['report_comments'][0]['count'] as int? ?? 0;
    } else if (json['commentCount'] != null) {
      count = json['commentCount'] as int;
    }

    return ReportModel(
      id: json['id']?.toString() ?? '',
      ticketId:
          json['report_code']?.toString() ??
          json['ticketId']?.toString() ??
          'REP-0000',
      title: json['title']?.toString() ?? 'Laporan',
      category: json['category']?.toString() ?? 'Lainnya',
      location:
          json['address']?.toString() ??
          json['location']?.toString() ??
          'Tidak diketahui',
      time: json['created_at'] != null
          ? _formatDate(json['created_at'])
          : (json['time']?.toString() ?? 'Baru saja'),
      status: apiStatus,
      isCompleted: json['isCompleted'] ?? completed,
      imageUrl:
          json['photo_url']?.toString() ??
          json['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1611284446314-60a58ac0deb9?q=80&w=600&auto=format&fit=crop',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      description: json['description']?.toString(),
      reporterName: json['reporter_name']?.toString() ?? json['users']?['name']?.toString() ?? json['user']?['name']?.toString() ?? json['profiles']?['full_name']?.toString() ?? 'Warga Anonim',
      reporterAvatar: json['users']?['avatar_url']?.toString(),
      reporterPhone: json['users']?['phone']?.toString(),
      assignedOfficerId: json['assigned_officer_id']?.toString(),
      commentCount: count,
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Baru saja';
    }
  }
}

class HeatmapData {
  final double latitude;
  final double longitude;
  final String category;

  HeatmapData({
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category']?.toString() ?? '',
    );
  }
}
