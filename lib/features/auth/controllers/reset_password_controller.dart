import 'package:flutter_riverpod/legacy.dart';
import 'package:season_app/features/auth/data/repositories/auth_repository.dart';

class ResetPasswordState {
  final bool isLoading;
  final String? error;
  final String? message;
  final bool isVerified;
  final bool isPasswordReset;

  ResetPasswordState({
    this.isLoading = false,
    this.error,
    this.message,
    this.isVerified = false,
    this.isPasswordReset = false,
  });

  ResetPasswordState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    bool? isVerified,
    bool? isPasswordReset,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      message: message,
      isVerified: isVerified ?? this.isVerified,
      isPasswordReset: isPasswordReset ?? this.isPasswordReset,
    );
  }
}

class ResetPasswordController extends StateNotifier<ResetPasswordState> {
  final AuthRepository repository;

  ResetPasswordController(this.repository) : super(ResetPasswordState());

  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null);

    try {
      final message = await repository.verifyResetOtp(
        email: email,
        otp: otp,
      );

      state = state.copyWith(
        isLoading: false,
        message: message,
        isVerified: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resendResetOtp({
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null);

    try {
      final message = await repository.resendResetOtp(
        email: email,
      );

      state = state.copyWith(
        isLoading: false,
        message: message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null);

    try {
      final message = await repository.resetPassword(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      state = state.copyWith(
        isLoading: false,
        message: message,
        isPasswordReset: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }
}
