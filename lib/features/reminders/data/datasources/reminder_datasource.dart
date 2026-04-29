import 'dart:io';
import 'package:dio/dio.dart';
import 'package:season_app/core/constants/api_endpoints.dart';

class ReminderRemoteDataSource {
  final Dio dio;

  ReminderRemoteDataSource(this.dio);

  Future<Response> getReminders() async {
    final response = await dio.get(ApiEndpoints.reminders);
    return response;
  }

  Future<Response> getReminder(int reminderId) async {
    final path = ApiEndpoints.reminderById.replaceFirst('{id}', reminderId.toString());
    final response = await dio.get(path);
    return response;
  }

  Future<Response> createReminder({
    required String title,
    required String date,
    required String time,
    required String recurrence,
    String? notes,
    String? timezone,
    File? attachment,
  }) async {
    // Build form data
    final formData = FormData.fromMap({
      'title': title,
      'date': date,
      'time': time,
      'recurrence': recurrence,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (timezone != null) 'timezone': timezone,
    });

    // Add attachment file if provided
    if (attachment != null) {
      final fileName = attachment.path.split('/').last;
      formData.files.add(
        MapEntry(
          'attachment',
          await MultipartFile.fromFile(
            attachment.path,
            filename: fileName,
          ),
        ),
      );
    }

    final response = await dio.post(
      ApiEndpoints.reminders,
      data: formData,
      options: Options(
        headers: {
          Headers.acceptHeader: 'application/json',
          Headers.contentTypeHeader: 'multipart/form-data',
        },
      ),
    );

    return response;
  }

  Future<Response> updateReminder({
    required int reminderId,
    String? title,
    String? date,
    String? time,
    String? recurrence,
    String? notes,
    String? timezone,
    File? attachment,
  }) async {
    final path = ApiEndpoints.reminderById.replaceFirst('{id}', reminderId.toString());

    // Build form data
    final formData = FormData.fromMap({
      '_method': 'PUT',
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (recurrence != null) 'recurrence': recurrence,
      if (notes != null) 'notes': notes,
      if (timezone != null) 'timezone': timezone,
    });

    // Add attachment file if provided
    if (attachment != null) {
      final fileName = attachment.path.split('/').last;
      formData.files.add(
        MapEntry(
          'attachment',
          await MultipartFile.fromFile(
            attachment.path,
            filename: fileName,
          ),
        ),
      );
    }

    final response = await dio.post(
      path,
      data: formData,
      options: Options(
        headers: {
          Headers.acceptHeader: 'application/json',
          Headers.contentTypeHeader: 'multipart/form-data',
        },
      ),
    );

    return response;
  }

  Future<Response> deleteReminder(int reminderId) async {
    final path = ApiEndpoints.reminderById.replaceFirst('{id}', reminderId.toString());
    final response = await dio.delete(path);
    return response;
  }
}

