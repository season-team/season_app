import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_assets.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/shared/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final translate = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Centered content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.seasonWelcomeImage,
                  height: 100,
                ),
                SizedBox(height: 20),
                Text(
                  'Season',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    translate.welcomeText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          // Button at the bottom
          Positioned(
            bottom: 20, 
            left: 20,
            right: 20,
            child: CustomButton(
              color: AppColors.textLight,
              textColor: AppColors.primary,
              width: MediaQuery.of(context).size.width * 0.8,
              text: translate.startNow,
              onPressed: () {
                context.go(Routes.login);
              },
            ),
          ),
        ],
      ),
    );
  }
}
