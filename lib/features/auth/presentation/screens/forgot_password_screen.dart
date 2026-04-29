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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Clear any previous errors when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forgotPasswordControllerProvider.notifier).clearError();
      ref.read(forgotPasswordControllerProvider.notifier).clearMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final emailController = ref.watch(forgotPasswordEmailControllerProvider);
    final forgotPasswordState = ref.watch(forgotPasswordControllerProvider);

    // Listen to forgot password state changes
    ref.listen(forgotPasswordControllerProvider, (previous, next) {
      if (next.error != null) {
        SnackbarHelper.error(context, next.error.toString());
      } else if (next.message != null) {
        SnackbarHelper.success(context, next.message.toString());
        context.push(Routes.verifyResetOtp);
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
                    tr.forgetPassword,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr.enterEmailToReceiveResetCode,
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
                        // Email
                        CustomTextField(
                          hintText: tr.email,
                          keyboardType: TextInputType.emailAddress,
                          controller: emailController,
                          onChanged: (val) => ref.read(forgotPasswordEmailProvider.notifier).state = val,
                          validator: (value) => Validators.email(value, isArabic: isArabic),
                        ),
                        const SizedBox(height: 30),
                        CustomButton(
                          isLoading: forgotPasswordState.isLoading,
                          text: tr.sendResetCode,
                          color: AppColors.primary,
                          onPressed: forgotPasswordState.isLoading
                              ? null
                              : () async {
                            if (formKey.currentState!.validate()) {
                              await ref.read(forgotPasswordControllerProvider.notifier).sendResetOtp(
                                email: ref.watch(forgotPasswordEmailProvider),
                              );
                              // The listener will handle the response
                            }
                          },
                        ),
                        const SizedBox(height: 30),
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
