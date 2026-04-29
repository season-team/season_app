import 'package:flutter_riverpod/legacy.dart';
import 'package:season_app/features/auth/data/repositories/auth_repository.dart';

class OtpState {
  final bool isLoading;
  final String? error;
  final String? message;
  final bool isVerified;
  final int timer;

  OtpState({
    this.isLoading = false,
    this.error,
    this.message,
    this.isVerified = false,
    this.timer = 0,
  });

  OtpState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    bool? isVerified,
    int? timer,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      message: message,
      isVerified: isVerified ?? this.isVerified,
      timer: timer ?? this.timer,
    );
  }
}

class OtpController extends StateNotifier<OtpState> {
  final AuthRepository repository;

  OtpController(this.repository) : super(OtpState());

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null);

    try {
      final message = await repository.verifyOtp(
        email: email,
        otp: otp,
      );

      state = state.copyWith(
        isLoading: false, 
        message: message, 
        isVerified: true
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resendOtp({
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null);

    try {
      final message = await repository.resendOtp(
        email: email,
      );

      state = state.copyWith(
        isLoading: false, 
        message: message,
        timer: 300, // Reset timer to 5 minutes
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateTimer(int newTimer) {
    state = state.copyWith(timer: newTimer);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }
}
