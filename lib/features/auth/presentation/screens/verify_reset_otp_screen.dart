import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:season_app/core/constants/app_assets.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/features/auth/providers.dart';
import 'package:season_app/shared/helpers/snackbar_helper.dart';
import 'package:season_app/shared/widgets/custom_button.dart';

class VerifyResetOtpScreen extends ConsumerStatefulWidget {
  const VerifyResetOtpScreen({super.key});

  @override
  ConsumerState<VerifyResetOtpScreen> createState() => _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends ConsumerState<VerifyResetOtpScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Defer timer start until after widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTimer();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer?.cancel();
    ref.read(otpTimerProvider.notifier).state = 120; // 2 minutes
    ref.read(otpTimerRunningProvider.notifier).state = true;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = ref.read(otpTimerProvider);
      if (current > 0) {
        ref.read(otpTimerProvider.notifier).state = current - 1;
      } else {
        ref.read(otpTimerRunningProvider.notifier).state = false;
        t.cancel();
      }
    });
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final pinController = ref.watch(pinControllerProvider);
    final email = ref.watch(forgotPasswordEmailProvider);
    final time = ref.watch(otpTimerProvider);
    final isRunning = ref.watch(otpTimerRunningProvider);
    final resetPasswordState = ref.watch(resetPasswordControllerProvider);

    // Listen to reset password state changes
    ref.listen(resetPasswordControllerProvider, (previous, next) {
      if (next.error != null) {
        SnackbarHelper.error(context, next.error.toString());
      } else if (next.message != null && next.isVerified) {
        SnackbarHelper.success(context, next.message.toString());
        context.push(Routes.resetPassword);
      } else if (next.message != null) {
        SnackbarHelper.success(context, next.message.toString());
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppAssets.seasonAuthImage, height: 80),
                const SizedBox(height: 10),
                Text(
                  tr.verifyMail,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Text(
                  "${tr.verifyMailBody} $email",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Pinput(
                    length: 4,
                    pinAnimationType: PinAnimationType.scale,
                    cursor: Container(
                      color: AppColors.primary,
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    defaultPinTheme: PinTheme(
                      width: 65,
                      height: 65,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        border: Border.all(
                            color: Color.fromRGBO(234, 239, 243, 1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: pinController,
                    onChanged: (val) {
                      ref.read(pinControllerProvider).text = val;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isRunning
                          ? "${tr.remaining} ${formatTime(time)} ${tr.seconds}"
                          : tr.codeNotSent,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                    const SizedBox(width: 5),
                    if (!isRunning)
                      TextButton(
                        onPressed: () async {
                          await ref.read(resetPasswordControllerProvider.notifier).resendResetOtp(email: email);
                          startTimer();
                        },
                        child: Text(
                          tr.resendCode,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: resetPasswordState.isLoading ? tr.loading : tr.verify,
                  color: AppColors.primary,
                  onPressed: (pinController.text.length != 4 || resetPasswordState.isLoading)
                      ? null
                      : () async {
                    await ref.read(resetPasswordControllerProvider.notifier).verifyResetOtp(
                      email: email,
                      otp: pinController.text,
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr.alreadyHaveAccount,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () {
                        context.go(Routes.login);
                      },
                      child: Text(
                        tr.login,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
