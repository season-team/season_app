import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:season_app/features/auth/controllers/signup_controller.dart';
import 'package:season_app/features/auth/controllers/login_controller.dart';
import 'package:season_app/features/auth/controllers/otp_controller.dart';
import 'package:season_app/features/auth/controllers/forgot_password_controller.dart';
import 'package:season_app/features/auth/controllers/reset_password_controller.dart';
import 'package:season_app/features/auth/data/datasources/auth_datasource.dart';
import 'package:season_app/features/auth/data/repositories/auth_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';


// Inputs
final firstNameProvider = StateProvider<String>((ref) => '');
final lastNameProvider = StateProvider<String>((ref) => '');
final emailProvider = StateProvider<String>((ref) => '');
final phoneProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final confirmPasswordProvider = StateProvider<String>((ref) => '');

// Password visibility
final passwordVisibilityProvider = StateProvider<bool>((ref) => true);
final confirmPasswordVisibilityProvider = StateProvider<bool>((ref) => true);


// Inputs
final loginEmailProvider = StateProvider<String>((ref) => '');
final loginPasswordProvider = StateProvider<String>((ref) => '');

// Forgot Password Inputs
final forgotPasswordEmailProvider = StateProvider<String>((ref) => '');
final resetPasswordProvider = StateProvider<String>((ref) => '');
final confirmResetPasswordProvider = StateProvider<String>((ref) => '');


// providers.dart
final loginEmailControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final loginPasswordControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// Forgot Password Controllers
final forgotPasswordEmailControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final newPasswordControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final confirmResetPasswordControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});


// providers.dart
final firstNameControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final lastNameControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final emailControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final phoneControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final passwordControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final confirmPasswordControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});


// OTP
final pinControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// OTP countdown timer
final otpTimerProvider = StateProvider<int>((ref) => 120); // 2 minutes in seconds
final otpTimerRunningProvider = StateProvider<bool>((ref) => true);


/// Data Source Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio);
});

/// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  return AuthRepository(remote);
});

/// Signup Controller Provider
final signupControllerProvider =
StateNotifierProvider<SignupController, SignupState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return SignupController(repo);
});

/// Login Controller Provider
final loginControllerProvider =
StateNotifierProvider<LoginController, LoginState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return LoginController(repo);
});

/// OTP Controller Provider
final otpControllerProvider =
StateNotifierProvider<OtpController, OtpState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return OtpController(repo);
});

/// Forgot Password Controller Provider
final forgotPasswordControllerProvider =
StateNotifierProvider<ForgotPasswordController, ForgotPasswordState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return ForgotPasswordController(repo);
});

/// Reset Password Controller Provider
final resetPasswordControllerProvider =
StateNotifierProvider<ResetPasswordController, ResetPasswordState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return ResetPasswordController(repo);
});
