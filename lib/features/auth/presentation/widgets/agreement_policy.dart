import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/router/routes.dart';

class AgreementPolicy extends StatelessWidget {
  const AgreementPolicy({
    super.key,
    required this.isArabic,
  });

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: isArabic
                  ? 'بالمتابعة أنت توافق على '
                  : 'By continuing, you agree to the ',
              style: const TextStyle(
                fontFamily: 'Cairo',
              ),
            ),
            TextSpan(
              text: isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontFamily: 'Cairo',
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.push(
                    '${Routes.webview}?url=${Uri.encodeComponent('https://seasonksa.com/terms')}&title=${Uri.encodeComponent(isArabic ? 'الشروط والأحكام' : 'Terms & Conditions')}',
                  );
                },
            ),
            TextSpan(
              text: isArabic ? ' و ' : ' and ',
              style: const TextStyle(
                fontFamily: 'Cairo',
              ),
            ),
            TextSpan(
              text: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontFamily: 'Cairo',
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.push(
                    '${Routes.webview}?url=${Uri.encodeComponent('https://seasonksa.com/privacy')}&title=${Uri.encodeComponent(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy')}',
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}
