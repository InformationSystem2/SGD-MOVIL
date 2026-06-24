class NotificationModel {
  final String id;
  final String channel;
  final String type;
  final String title;
  final String message;
  final String? documentId;
  final String? reviewTaskId;
  final String? workflowId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.channel,
    required this.type,
    required this.title,
    required this.message,
    this.documentId,
    this.reviewTaskId,
    this.workflowId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      channel: json['channel'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      documentId: json['documentId'] as String?,
      reviewTaskId: json['reviewTaskId'] as String?,
      workflowId: json['workflowId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel': channel,
      'type': type,
      'title': title,
      'message': message,
      'documentId': documentId,
      'reviewTaskId': reviewTaskId,
      'workflowId': workflowId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? channel,
    String? type,
    String? title,
    String? message,
    String? documentId,
    String? reviewTaskId,
    String? workflowId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      channel: channel ?? this.channel,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      documentId: documentId ?? this.documentId,
      reviewTaskId: reviewTaskId ?? this.reviewTaskId,
      workflowId: workflowId ?? this.workflowId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
