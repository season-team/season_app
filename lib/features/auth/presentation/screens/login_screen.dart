import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_assets.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/core/services/notification_service.dart';
import 'package:season_app/core/services/social_login_service.dart';
import 'package:season_app/core/utils/validators.dart';
import 'package:season_app/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:season_app/features/auth/providers.dart';
import 'package:season_app/features/groups/providers.dart';
import 'package:season_app/shared/helpers/snackbar_helper.dart';
import 'package:season_app/shared/providers/locale_provider.dart';
import 'package:season_app/shared/widgets/custom_button.dart';
import 'package:season_app/shared/widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    
    // Clear any previous errors when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginControllerProvider.notifier).clearError();
      ref.read(loginControllerProvider.notifier).clearMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    log(ref.watch(localeProvider).languageCode);
    final formKey = GlobalKey<FormState>();
    final emailController = ref.watch(loginEmailControllerProvider);
    final passwordController = ref.watch(loginPasswordControllerProvider);
    final loginState = ref.watch(loginControllerProvider);
    
    // Listen to login state changes
    ref.listen(loginControllerProvider, (previous, next) async {
      if (next.error != null) {
        SnackbarHelper.error(context, next.error.toString().replaceAll('Exception: ', ''));
      } else if (next.message != null && next.isLoggedIn) {
        SnackbarHelper.success(context, next.message.toString());
        
        // Clear any existing groups data for the new user
        ref.read(groupsControllerProvider.notifier).clearAllData();
        
        // Subscribe to notification topics after successful login
        try {
          await NotificationService().subscribeToAllUsers();
        } catch (e) {
          debugPrint('Error subscribing to topics: $e');
        }
        
        if (context.mounted) {
          context.go(Routes.home);
        }
      } else if (next.message != null && !next.isLoggedIn) {
        // Social login might require OTP verification
        SnackbarHelper.info(context, next.message.toString());
        if (context.mounted && next.message!.toLowerCase().contains('otp')) {
          context.push(Routes.verifyOtp);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.seasonAuthImage, height: 80),
                  const SizedBox(height: 10),
                  Text(
                    tr.login,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr.welcomeLogin,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                          textDirection: TextDirection.ltr,
                          controller: emailController,
                          onChanged: (val) => ref.read(loginEmailProvider.notifier).state = val,
                          validator: (value) => Validators.email(value, isArabic: isArabic),
                        ),
                        const SizedBox(height: 10),
                        // Password
                      
                        CustomTextField(
                          hintText: tr.password,
                          obscureText: ref.watch(passwordVisibilityProvider),
                          textDirection: TextDirection.ltr,
                          controller: passwordController,
                          onChanged: (val) => ref.read(loginPasswordProvider.notifier).state = val,
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
                        const SizedBox(height: 5),
                        InkWell(
                          onTap: () {
                            context.push(Routes.forgotPassword);
                          },
                          child: Text(
                            tr.forgetPassword,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          isLoading: loginState.isLoading,
                          text: tr.login,
                          color: AppColors.primary,
                          onPressed: loginState.isLoading ? null : () async {
                            if (formKey.currentState!.validate()) {
                              // Get FCM token
                              final fcmToken = await NotificationService().getSavedFCMToken() ?? 
                                  NotificationService().fcmToken;
                              
                              await ref.read(loginControllerProvider.notifier).login(
                                email: ref.watch(loginEmailProvider),
                                password: ref.watch(loginPasswordProvider),
                                notificationToken: fcmToken,
                              );
                              // The listener will handle navigation
                            }
                          },
                        ),
                        SocialLoginButtons(
                          onGooglePressed: () async {
                            try {
                              // Get FCM token
                              final fcmToken = await NotificationService().getSavedFCMToken() ?? 
                                  NotificationService().fcmToken;
                              
                              // Sign in with Google
                              final googleData = await SocialLoginService.signInWithGoogle();
                              
                              // Call backend login/register
                              if (googleData['idToken'] != null && googleData['accessToken'] != null) {
                                await ref.read(loginControllerProvider.notifier).loginWithGoogle(
                                  idToken: googleData['idToken']!,
                                  accessToken: googleData['accessToken']!,
                                  notificationToken: fcmToken,
                                );
                              } else {
                                SnackbarHelper.error(context, 'Failed to get Google credentials');
                              }
                            } catch (e) {
                              final errorMessage = e.toString();
                              // On login screen, if user not found, suggest registration
                              if (errorMessage.contains('404:') || 
                                  errorMessage.toLowerCase().contains('not found') || 
                                  errorMessage.toLowerCase().contains('not registered')) {
                                SnackbarHelper.error(
                                  context, 
                                  Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'المستخدم غير موجود. يرجى التسجيل أولاً'
                                      : 'User not found. Please register first'
                                );
                              } else {
                                SnackbarHelper.error(context, errorMessage.replaceAll('Exception: ', ''));
                              }
                            }
                          },
                          onApplePressed: () async {
                            try {
                              // Get FCM token
                              final fcmToken = await NotificationService().getSavedFCMToken() ?? 
                                  NotificationService().fcmToken;
                              
                              // Sign in with Apple
                              final appleData = await SocialLoginService.signInWithApple();
                              
                              // Call backend login
                              if (appleData['idToken'] != null) {
                                await ref.read(loginControllerProvider.notifier).loginWithApple(
                                  idToken: appleData['idToken']!,
                                  authorizationCode: appleData['authorizationCode'],
                                  notificationToken: fcmToken,
                                );
                              } else {
                                SnackbarHelper.error(context, 'Failed to get Apple credentials');
                              }
                            } catch (e) {
                              final errorMessage = e.toString();
                              // On login screen, if user not found, suggest registration
                              if (errorMessage.contains('404:') || 
                                  errorMessage.toLowerCase().contains('not found') || 
                                  errorMessage.toLowerCase().contains('not registered')) {
                                SnackbarHelper.error(
                                  context, 
                                  Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'المستخدم غير موجود. يرجى التسجيل أولاً'
                                      : 'User not found. Please register first'
                                );
                              } else {
                                SnackbarHelper.error(context, errorMessage.replaceAll('Exception: ', ''));
                              }
                            }
                          },
                          isLoading: loginState.isLoading,
                        ),
                        const SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tr.dontHaveAccount,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            InkWell(
                              onTap: () {
                                context.go(Routes.signUp);
                              },
                              child: Text(
                                tr.signUp,
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


