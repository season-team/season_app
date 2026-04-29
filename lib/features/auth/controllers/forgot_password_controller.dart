import 'package:flutter_riverpod/legacy.dart';
import 'package:season_app/features/auth/data/repositories/auth_repository.dart';

class ForgotPasswordState {
  final bool isLoading;
  final String? error;
  final String? message;
  final bool isEmailSent;

  ForgotPasswordState({
    this.isLoading = false,
    this.error,
    this.message,
    this.isEmailSent = false,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    bool? isEmailSent,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      message: message,
      isEmailSent: isEmailSent ?? this.isEmailSent,
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  final AuthRepository repository;

  ForgotPasswordController(this.repository) : super(ForgotPasswordState());

  Future<void> sendResetOtp({
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null);

    try {
      final message = await repository.forgotPassword(
        email: email,
      );

      state = state.copyWith(
        isLoading: false,
        message: message,
        isEmailSent: true,
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
