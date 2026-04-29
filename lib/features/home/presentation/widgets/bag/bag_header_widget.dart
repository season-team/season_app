import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/home/data/models/bag_type_model.dart';
import 'package:season_app/features/home/providers/bag_providers.dart';
import 'package:season_app/shared/widgets/custom_button.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

class BagHeaderWidget extends ConsumerWidget {
  final double currentWeight;
  final double maxWeight;
  final String? weightUnit;

  const BagHeaderWidget({
    super.key,
    required this.currentWeight,
    required this.maxWeight,
    this.weightUnit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final bagState = ref.watch(bagControllerProvider);
    final bagType = bagState.selectedBagType;
    final bagTitle = bagType?.name ?? loc.bagTitle;
    final bagSubtitle = bagType?.description?.isNotEmpty == true
        ? bagType!.description!
        : loc.bagSubtitle;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.luggage, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bagTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bagSubtitle,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          loc.bagTotalWeightLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          loc.bagWeight(
                            currentWeight.toStringAsFixed(1),
                            maxWeight.toStringAsFixed(0),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showEditMaxWeightDialog(
                            context,
                            ref,
                            maxWeight,
                            weightUnit ?? 'kg',
                            bagState.selectedBagType?.id,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!bagState.isLoading && bagState.bagTypes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int index = 0; index < bagState.bagTypes.length; index++) ...[
                      if (index > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _BagTypeChip(
                          bagType: bagState.bagTypes[index],
                          isSelected: bagState.selectedBagType?.id == bagState.bagTypes[index].id,
                          onTap: () => ref
                              .read(bagControllerProvider.notifier)
                              .selectBagType(bagState.bagTypes[index]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedString(String key, {bool isArabic = false}) {
    // Fallback strings until localization files regenerate
    final fallbacksEn = {
      'bagEditMaxWeight': 'Edit Max Weight',
      'bagMaxWeightLabel': 'Max Weight',
      'bagWeightUnitKg': 'kg',
      'bagMaxWeightInfo': 'Adjust the maximum weight limit for your bag. The weight is always measured in kilograms.',
      'bagMaxWeightUpdated': 'Max weight updated successfully',
      'save': 'Save',
    };
    final fallbacksAr = {
      'bagEditMaxWeight': 'تعديل الحد الأقصى للوزن',
      'bagMaxWeightLabel': 'الحد الأقصى للوزن',
      'bagWeightUnitKg': 'كجم',
      'bagMaxWeightInfo': 'اضبط الحد الأقصى للوزن لحقيبتك. يتم قياس الوزن دائماً بالكيلوجرام.',
      'bagMaxWeightUpdated': 'تم تحديث الحد الأقصى للوزن بنجاح',
      'save': 'حفظ',
    };
    return isArabic ? (fallbacksAr[key] ?? key) : (fallbacksEn[key] ?? key);
  }

  void _showEditMaxWeightDialog(
    BuildContext context,
    WidgetRef ref,
    double currentMaxWeight,
    String currentWeightUnit,
    int? bagTypeId,
  ) {
    if (bagTypeId == null) return;

    final loc = AppLocalizations.of(context);
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => _EditMaxWeightBottomSheet(
        currentMaxWeight: currentMaxWeight,
        bagTypeId: bagTypeId,
        isArabic: isArabic,
      ),
    );
  }
}

class _EditMaxWeightBottomSheet extends StatefulWidget {
  final double currentMaxWeight;
  final int bagTypeId;
  final bool isArabic;

  const _EditMaxWeightBottomSheet({
    required this.currentMaxWeight,
    required this.bagTypeId,
    required this.isArabic,
  });

  @override
  State<_EditMaxWeightBottomSheet> createState() => _EditMaxWeightBottomSheetState();
}

class _EditMaxWeightBottomSheetState extends State<_EditMaxWeightBottomSheet> {
  late double sliderValue;

  @override
  void initState() {
    super.initState();
    sliderValue = widget.currentMaxWeight.clamp(1.0, 100.0);
  }

  String _getLocalizedString(String key) {
    // Fallback strings until localization files regenerate
    final fallbacksEn = {
      'bagEditMaxWeight': 'Edit Max Weight',
      'bagMaxWeightLabel': 'Max Weight',
      'bagWeightUnitKg': 'kg',
      'bagMaxWeightInfo': 'Adjust the maximum weight limit for your bag. The weight is always measured in kilograms.',
      'bagMaxWeightUpdated': 'Max weight updated successfully',
      'save': 'Save',
    };
    final fallbacksAr = {
      'bagEditMaxWeight': 'تعديل الحد الأقصى للوزن',
      'bagMaxWeightLabel': 'الحد الأقصى للوزن',
      'bagWeightUnitKg': 'كجم',
      'bagMaxWeightInfo': 'اضبط الحد الأقصى للوزن لحقيبتك. يتم قياس الوزن دائماً بالكيلوجرام.',
      'bagMaxWeightUpdated': 'تم تحديث الحد الأقصى للوزن بنجاح',
      'save': 'حفظ',
    };
    return widget.isArabic ? (fallbacksAr[key] ?? key) : (fallbacksEn[key] ?? key);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.scale,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getLocalizedString('bagEditMaxWeight'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getLocalizedString('bagMaxWeightLabel'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  AppColors.secondary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${sliderValue.toStringAsFixed(1)} ${_getLocalizedString('bagWeightUnitKg')}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.secondary,
                          inactiveTrackColor: Colors.grey.shade300,
                          thumbColor: AppColors.secondary,
                          overlayColor: AppColors.secondary.withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 14,
                          ),
                          trackHeight: 6,
                          valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                          valueIndicatorColor: AppColors.secondary,
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                          showValueIndicator: ShowValueIndicator.always,
                        ),
                        child: Slider(
                          value: sliderValue,
                          min: 1.0,
                          max: 100.0,
                          divisions: 990,
                                label: '${sliderValue.toStringAsFixed(1)} ${_getLocalizedString('bagWeightUnitKg')}',
                          onChanged: (value) {
                            setState(() {
                              sliderValue = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '1 ${_getLocalizedString('bagWeightUnitKg')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                              '100 ${_getLocalizedString('bagWeightUnitKg')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            _getLocalizedString('bagMaxWeightInfo'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Text(
                          loc.cancel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Consumer(
                        builder: (context, ref, _) {
                          return CustomButton(
                            onPressed: () async {
                              // Get the scaffold messenger before closing
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              // Close bottom sheet immediately
                              Navigator.of(context).pop();
                              
                              // Make API call in background
                              try {
                                final success = await ref
                                    .read(bagControllerProvider.notifier)
                                    .updateMaxWeight(
                                      maxWeight: sliderValue,
                                      weightUnit: 'kg',
                                      bagTypeId: widget.bagTypeId,
                                    );

                                if (success) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(_getLocalizedString('bagMaxWeightUpdated')),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceAll('ApiException: ', ''),
                                    ),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                            text: _getLocalizedString('save'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BagTypeChip extends StatelessWidget {
  final BagTypeModel bagType;
  final bool isSelected;
  final VoidCallback onTap;

  const _BagTypeChip({
    required this.bagType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                bagType.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.95),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
