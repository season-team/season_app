import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_assets.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/core/utils/validators.dart';
import 'package:season_app/features/auth/providers.dart';
import 'package:season_app/shared/helpers/snackbar_helper.dart';
import 'package:season_app/shared/providers/locale_provider.dart';
import 'package:season_app/shared/widgets/custom_button.dart';
import 'package:season_app/shared/widgets/custom_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Clear any previous errors when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(resetPasswordControllerProvider.notifier).clearError();
      ref.read(resetPasswordControllerProvider.notifier).clearMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final newPasswordController = ref.watch(newPasswordControllerProvider);
    final confirmPasswordController = ref.watch(confirmResetPasswordControllerProvider);
    final resetPasswordState = ref.watch(resetPasswordControllerProvider);

    // Listen to reset password state changes
    ref.listen(resetPasswordControllerProvider, (previous, next) {
      if (next.error != null) {
        SnackbarHelper.error(context, next.error.toString());
      } else if (next.message != null && next.isPasswordReset) {
        SnackbarHelper.success(context, next.message.toString());
        context.go(Routes.login);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.seasonAuthImage, height: 80),
                  const SizedBox(height: 10),
                  Text(
                    tr.resetPassword,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr.enterNewPassword,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // New Password
                        CustomTextField(
                          hintText: tr.password,
                          obscureText: ref.watch(passwordVisibilityProvider),
                          controller: newPasswordController,
                          onChanged: (val) => ref.read(resetPasswordProvider.notifier).state = val,
                          validator: (value) => Validators.password(value, isArabic: isArabic),
                          suffixIcon: IconButton(
                            icon: Icon(
                              ref.watch(passwordVisibilityProvider)
                                  ? Icons.remove_red_eye
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              ref.read(passwordVisibilityProvider.notifier).state =
                              !ref.read(passwordVisibilityProvider.notifier).state;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Confirm New Password
                        CustomTextField(
                          hintText: tr.confirmPassword,
                          obscureText: ref.watch(confirmPasswordVisibilityProvider),
                          controller: confirmPasswordController,
                          onChanged: (val) => ref.read(confirmResetPasswordProvider.notifier).state = val,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr.confirmNewPasswordRequired;
                            }
                            if (value != ref.watch(resetPasswordProvider)) {
                              return tr.passwordsDoNotMatch;
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              ref.watch(confirmPasswordVisibilityProvider)
                                  ? Icons.remove_red_eye
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              ref.read(confirmPasswordVisibilityProvider.notifier).state =
                              !ref.read(confirmPasswordVisibilityProvider.notifier).state;
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        CustomButton(
                          isLoading: resetPasswordState.isLoading,
                          text: tr.resetPassword,
                          color: AppColors.primary,
                          onPressed: resetPasswordState.isLoading
                              ? null
                              : () async {
                            if (formKey.currentState!.validate()) {
                              await ref.read(resetPasswordControllerProvider.notifier).resetPassword(
                                email: ref.watch(forgotPasswordEmailProvider),
                                password: ref.watch(resetPasswordProvider),
                                passwordConfirmation: ref.watch(confirmResetPasswordProvider),
                              );
                              // The listener will handle the response
                            }
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
