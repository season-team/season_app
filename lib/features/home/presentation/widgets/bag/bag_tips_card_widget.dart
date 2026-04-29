import 'package:flutter/material.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/home/presentation/widgets/bag/bag_widget_helpers.dart';

class BagTipsCardWidget extends StatelessWidget {
  const BagTipsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final tips = [
      loc.bagTip1,
      loc.bagTip2,
      loc.bagTip3,
      loc.bagTip4,
    ];

    return Container(
      decoration: BagWidgetHelpers.cardDecoration(
        backgroundColor: AppColors.bagTipsBackground,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.bagTipsText,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                loc.bagTipsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bagTipsText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tip in tips) _TipItem(text: tip),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.bagTipsText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.bagTipsText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
