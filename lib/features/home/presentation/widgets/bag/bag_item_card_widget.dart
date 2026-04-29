import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/home/data/models/bag_item_in_bag_model.dart';

class BagItemCardWidget extends ConsumerStatefulWidget {
  final BagItemInBagModel item;
  final int bagId;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdate;

  const BagItemCardWidget({
    super.key,
    required this.item,
    required this.bagId,
    this.onDelete,
    this.onUpdate,
  });

  @override
  ConsumerState<BagItemCardWidget> createState() => _BagItemCardWidgetState();
}

class _BagItemCardWidgetState extends ConsumerState<BagItemCardWidget> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isEssential = item.essential ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Enable tap feedback
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading: Category Icon with gradient
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Middle: Name, Category, and badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Item name row with essential badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name.isNotEmpty ? item.name : (isRtl ? 'غرض بدون اسم' : 'Unnamed Item'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isEssential) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Info row: category, quantity, weight
                      Row(
                        children: [
                          // Category chip
                          if (item.category != null && item.category!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          
                          // Quantity chip
                          if (item.quantity > 1) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.layers_rounded, size: 11, color: AppColors.info),
                                  const SizedBox(width: 3),
                                  Text(
                                    '×${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          
                          // Weight
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.scale_rounded,
                                size: 12,
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.totalWeight.toStringAsFixed(2)} kg',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Trailing: Delete button
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null || category.isEmpty) return Icons.inventory_2_rounded;
    
    final lowerCategory = category.toLowerCase();
    
    if (lowerCategory.contains('ملابس') || lowerCategory.contains('cloth')) {
      return Icons.checkroom_rounded;
    } else if (lowerCategory.contains('إلكترون') || lowerCategory.contains('electron')) {
      return Icons.devices_rounded;
    } else if (lowerCategory.contains('أدوي') || lowerCategory.contains('medic')) {
      return Icons.medication_rounded;
    } else if (lowerCategory.contains('مستند') || lowerCategory.contains('document')) {
      return Icons.description_rounded;
    } else if (lowerCategory.contains('أحذي') || lowerCategory.contains('shoe')) {
      return Icons.hiking_rounded;
    } else if (lowerCategory.contains('نظاف') || lowerCategory.contains('hygiene')) {
      return Icons.sanitizer_rounded;
    } else if (lowerCategory.contains('طعام') || lowerCategory.contains('food')) {
      return Icons.restaurant_rounded;
    } else {
      return Icons.category_rounded;
    }
  }
}
