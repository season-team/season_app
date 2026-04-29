import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:season_app/features/reminders/data/datasources/reminder_datasource.dart';
import 'package:season_app/features/reminders/data/repositories/reminder_repository.dart';
import 'package:season_app/features/reminders/data/models/reminder_model.dart';
import 'package:season_app/shared/providers/app_providers.dart';

// Reminder Repository Provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = ReminderRemoteDataSource(dio);
  return ReminderRepository(dataSource);
});

// Reminders State
class RemindersState {
  final List<ReminderModel> reminders;
  final int activeCount;
  final bool isLoading;
  final String? error;

  RemindersState({
    required this.reminders,
    required this.activeCount,
    this.isLoading = false,
    this.error,
  });

  RemindersState copyWith({
    List<ReminderModel>? reminders,
    int? activeCount,
    bool? isLoading,
    String? error,
  }) {
    return RemindersState(
      reminders: reminders ?? this.reminders,
      activeCount: activeCount ?? this.activeCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Reminders Notifier
class RemindersNotifier extends Notifier<RemindersState> {
  late ReminderRepository _repository;

  @override
  RemindersState build() {
    try {
      _repository = ref.read(reminderRepositoryProvider);
      // Load reminders after initialization, but don't fail if it errors
      Future.microtask(() {
        try {
          loadReminders();
        } catch (e) {
          // Silently handle initialization errors
          state = state.copyWith(
            isLoading: false,
            error: e.toString(),
          );
        }
      });
    } catch (e) {
      // If provider initialization fails, return error state
      return RemindersState(
        reminders: [],
        activeCount: 0,
        isLoading: false,
        error: e.toString(),
      );
    }
    return RemindersState(reminders: [], activeCount: 0);
  }

  Future<void> loadReminders() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      debugPrint('🔍 Loading reminders...');
      final response = await _repository.getReminders();
      debugPrint('✅ Reminders loaded: ${response.reminders.length} reminders, activeCount: ${response.activeCount}');
      state = state.copyWith(
        reminders: response.reminders,
        activeCount: response.activeCount,
        isLoading: false,
      );
      debugPrint('✅ State updated successfully');
    } catch (e, stackTrace) {
      // Handle errors gracefully
      debugPrint('❌ Error loading reminders: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        reminders: state.reminders, // Keep existing reminders if any
        activeCount: state.activeCount,
      );
    }
  }

  Future<bool> createReminder({
    required String title,
    required String date,
    required String time,
    required String recurrence,
    String? notes,
    String? timezone,
    dynamic attachment,
  }) async {
    try {
      await _repository.createReminder(
        title: title,
        date: date,
        time: time,
        recurrence: recurrence,
        notes: notes,
        timezone: timezone,
        attachment: attachment,
      );
      await loadReminders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateReminder({
    required int reminderId,
    String? title,
    String? date,
    String? time,
    String? recurrence,
    String? notes,
    String? timezone,
    dynamic attachment,
  }) async {
    try {
      await _repository.updateReminder(
        reminderId: reminderId,
        title: title,
        date: date,
        time: time,
        recurrence: recurrence,
        notes: notes,
        timezone: timezone,
        attachment: attachment,
      );
      await loadReminders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteReminder(int reminderId) async {
    try {
      await _repository.deleteReminder(reminderId);
      await loadReminders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// Reminders Provider
final remindersProvider =
    NotifierProvider<RemindersNotifier, RemindersState>(() {
  return RemindersNotifier();
});

