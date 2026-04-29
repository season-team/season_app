import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/home/providers/bag_providers.dart';
import 'package:season_app/features/home/presentation/widgets/bag/bag_item_card_widget.dart';
import 'package:season_app/features/home/presentation/widgets/bag/bag_widget_helpers.dart';

class BagStatusCardWidget extends ConsumerWidget {
  final VoidCallback onAddItem;
  final void Function(int itemId)? onDeleteItem;

  const BagStatusCardWidget({
    super.key,
    required this.onAddItem,
    this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final bagState = ref.watch(bagControllerProvider);
    final bagDetail = bagState.getSelectedBagDetail();
    final items = bagDetail?.items ?? [];
    final isEmpty = bagDetail?.isEmpty ?? true;
    final bagType = bagState.selectedBagType;
    final bagTitle = bagType?.name ?? loc.bagTitle;
    return Container(
      decoration: BagWidgetHelpers.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.luggage_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                   bagTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!isEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton(
                onPressed: onAddItem,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  loc.bagAddItemButton,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            Column(
              children: [
                Icon(
                  Icons.luggage_outlined,
                  size: 64,
                  color: AppColors.primary.withOpacity(0.18),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.bagEmptyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.bagEmptyDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else ...[
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
                child: BagItemCardWidget(
                  item: item,
                  bagId: bagDetail?.bagId ?? 0,
                  onDelete: onDeleteItem != null
                      ? () => onDeleteItem!(item.itemId ?? 0)
                      : null,
                  onUpdate: () {
                    // Refresh bag details when item is updated
                    ref.read(bagControllerProvider.notifier).loadBagDetails();
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
