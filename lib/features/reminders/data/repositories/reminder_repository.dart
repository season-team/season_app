import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:season_app/features/reminders/data/datasources/reminder_datasource.dart';
import 'package:season_app/features/reminders/data/models/reminder_model.dart';

class ReminderRepository {
  final ReminderRemoteDataSource _dataSource;

  ReminderRepository(this._dataSource);

  Future<RemindersResponse> getReminders() async {
    try {
      final response = await _dataSource.getReminders();
      debugPrint('🔍 ReminderRepository - Response data: ${response.data}');
      debugPrint('🔍 ReminderRepository - Success: ${response.data['success']}');
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        debugPrint('🔍 ReminderRepository - Data: $data');
        final remindersResponse = RemindersResponse.fromJson(data);
        debugPrint('✅ ReminderRepository - Parsed ${remindersResponse.reminders.length} reminders');
        return remindersResponse;
      }
      throw Exception(response.data['message'] ?? 'Failed to get reminders');
    } catch (e, stackTrace) {
      debugPrint('❌ ReminderRepository error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<ReminderModel> getReminder(int reminderId) async {
    try {
      final response = await _dataSource.getReminder(reminderId);
      if (response.data['success'] == true) {
        return ReminderModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get reminder');
    } catch (e) {
      rethrow;
    }
  }

  Future<ReminderModel> createReminder({
    required String title,
    required String date,
    required String time,
    required String recurrence,
    String? notes,
    String? timezone,
    File? attachment,
  }) async {
    try {
      final response = await _dataSource.createReminder(
        title: title,
        date: date,
        time: time,
        recurrence: recurrence,
        notes: notes,
        timezone: timezone,
        attachment: attachment,
      );
      if (response.data['success'] == true) {
        return ReminderModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create reminder');
    } catch (e) {
      rethrow;
    }
  }

  Future<ReminderModel> updateReminder({
    required int reminderId,
    String? title,
    String? date,
    String? time,
    String? recurrence,
    String? notes,
    String? timezone,
    File? attachment,
  }) async {
    try {
      final response = await _dataSource.updateReminder(
        reminderId: reminderId,
        title: title,
        date: date,
        time: time,
        recurrence: recurrence,
        notes: notes,
        timezone: timezone,
        attachment: attachment,
      );
      if (response.data['success'] == true) {
        return ReminderModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update reminder');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReminder(int reminderId) async {
    try {
      final response = await _dataSource.deleteReminder(reminderId);
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete reminder');
      }
    } catch (e) {
      rethrow;
    }
  }
}

