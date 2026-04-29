class ReminderModel {
  final int reminderId;
  final String title;
  final String date;
  final String time;
  final String timezone;
  final String recurrence;
  final String? notes;
  final String? attachment;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderModel({
    required this.reminderId,
    required this.title,
    required this.date,
    required this.time,
    required this.timezone,
    required this.recurrence,
    this.notes,
    this.attachment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      reminderId: _parseInt(json['reminder_id']),
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      timezone: json['timezone'] ?? 'Africa/Cairo',
      recurrence: json['recurrence'] ?? 'مرة واحدة',
      notes: json['notes'],
      attachment: json['attachment'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminder_id': reminderId,
      'title': title,
      'date': date,
      'time': time,
      'timezone': timezone,
      'recurrence': recurrence,
      'notes': notes,
      'attachment': attachment,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

class RemindersResponse {
  final List<ReminderModel> reminders;
  final int activeCount;
  final int totalCount;

  RemindersResponse({
    required this.reminders,
    required this.activeCount,
    required this.totalCount,
  });

  factory RemindersResponse.fromJson(Map<String, dynamic> json) {
    return RemindersResponse(
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((e) => ReminderModel.fromJson(e))
              .toList() ??
          [],
      activeCount: json['active_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
    );
  }
}

