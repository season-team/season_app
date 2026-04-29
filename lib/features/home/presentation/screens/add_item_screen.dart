import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/home/data/models/ai_category_model.dart';
import 'package:season_app/features/home/data/models/ai_item_model.dart';
import 'package:season_app/features/home/data/models/bag_detail_model.dart';
import 'package:season_app/features/home/data/models/selected_item_model.dart';
import 'package:season_app/features/home/providers/bag_providers.dart';
import 'package:season_app/shared/widgets/custom_toast.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final int bagId;

  const AddItemScreen({
    super.key,
    required this.bagId,
  });

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  int _currentStep = 0; // 0: Category, 1: Items

  // Step 0: Category Selection
  List<AICategoryModel> _aiCategories = [];
  AICategoryModel? _selectedCategory;
  bool _isLoadingCategories = false;

  // Step 1: Items Selection
  List<AIItemModel> _aiItems = [];
  Map<String, SelectedItemModel> _selectedItems = {}; // item name -> selected item
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadAICategories();
  }

  Future<void> _loadAICategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final repository = ref.read(bagRepositoryProvider);
      final categories = await repository.getAICategories();
      setState(() {
        _aiCategories = categories;
      });
    } catch (e) {
      if (mounted) {
        final isRtl = Localizations.localeOf(context).languageCode == 'ar';
        CustomToast.error(
          context,
          isRtl ? 'فشل تحميل الفئات' : 'Failed to load categories',
        );
      }
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadAIItems(String categoryName) async {
    // Set selected category and navigate immediately
    setState(() {
      _selectedCategory = _aiCategories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => _aiCategories.first,
      );
      _currentStep = 1; // Navigate immediately
      _isLoadingItems = true;
      _aiItems = []; // Clear previous items
    });

    // Load items in background
    try {
      final repository = ref.read(bagRepositoryProvider);
      final items = await repository.getAISuggestedItems(categoryName);
      if (mounted) {
        setState(() {
          _aiItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
        final isRtl = Localizations.localeOf(context).languageCode == 'ar';
        CustomToast.error(
          context,
          isRtl ? 'فشل تحميل العناصر' : 'Failed to load items',
        );
        // Go back to category selection on error
        setState(() {
          _currentStep = 0;
        });
      }
    }
  }

  void _selectCategory(AICategoryModel? category) {
    if (category == null) {
      // "Other" selected - navigate to custom item screen
      _navigateToCustomItem();
    } else {
      _loadAIItems(category.name);
    }
  }

  Future<void> _navigateToCustomItem() async {
    final result = await Navigator.of(context).push<SelectedItemModel>(
      MaterialPageRoute(
        builder: (context) => CustomItemScreen(
          bagId: widget.bagId,
          categoryName: _selectedCategory?.name,
        ),
      ),
    );

    if (result != null && mounted) {
      final itemsToAdd = <SelectedItemModel>[result];
      itemsToAdd.addAll(_selectedItems.values);
      final added = await _addItems(itemsToAdd);
      if (mounted) context.pop(added);
    }
  }

  void _toggleItem(AIItemModel item) {
    setState(() {
      if (_selectedItems.containsKey(item.name)) {
        _selectedItems.remove(item.name);
      } else {
        _selectedItems[item.name] = SelectedItemModel(
          name: item.name,
          weight: item.weight,
          quantity: 1,
          essential: false,
          categoryName: _selectedCategory?.name,
          isCustom: false,
        );
      }
    });
  }

  void _updateItemQuantity(String itemName, int quantity) {
    setState(() {
      final item = _selectedItems[itemName];
      if (item != null && quantity > 0) {
        _selectedItems[itemName] = item.copyWith(quantity: quantity);
      }
    });
  }

  void _toggleItemEssential(String itemName) {
    setState(() {
      final item = _selectedItems[itemName];
      if (item != null) {
        _selectedItems[itemName] = item.copyWith(essential: !item.essential);
      }
    });
  }

  /// Adds items via API, refreshes bag list in [bagControllerProvider], then returns
  /// whether at least one item was added (caller uses this for [context.pop]).
  Future<bool> _addItems(List<SelectedItemModel> items) async {
    if (items.isEmpty) return false;

    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final repository = ref.read(bagRepositoryProvider);

    final bagState = ref.read(bagControllerProvider);
    BagDetailModel? bagDetail;
    try {
      bagDetail = bagState.bagDetails.firstWhere(
        (detail) => detail.bagId == widget.bagId,
      );
    } catch (e) {
      bagDetail = bagState.getSelectedBagDetail();
      if (bagDetail == null && bagState.bagDetails.isNotEmpty) {
        bagDetail = bagState.bagDetails.first;
      }
    }

    if (bagDetail != null) {
      double totalItemsWeight = 0;
      for (final item in items) {
        totalItemsWeight += item.weight * item.quantity;
      }

      final newTotalWeight = bagDetail.currentWeight + totalItemsWeight;

      if (newTotalWeight > bagDetail.maxWeight) {
        final l10n = AppLocalizations.of(context);
        if (mounted) {
          CustomToast.error(
            context,
            l10n.weightExceededMessage(
              bagDetail.maxWeight.toStringAsFixed(1),
              bagDetail.currentWeight.toStringAsFixed(1),
              totalItemsWeight.toStringAsFixed(1),
            ),
          );
        }
        return false;
      }
    }

    int successCount = 0;
    int failCount = 0;

    for (final item in items) {
      try {
        await repository.addAIItemToBag(
          bagId: widget.bagId,
          itemName: item.name,
          weight: item.weight,
          essential: item.essential,
          quantity: item.quantity,
        );
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Failed to add item ${item.name}: $e');
      }
    }

    if (!mounted) return successCount > 0;

    if (successCount > 0) {
      await ref.read(bagControllerProvider.notifier).loadBagDetails();
    }

    if (!mounted) return successCount > 0;

    if (failCount == 0) {
      CustomToast.success(
        context,
        isRtl
            ? 'تم إضافة $successCount عنصر بنجاح'
            : 'Successfully added $successCount items',
      );
    } else {
      CustomToast.error(
        context,
        isRtl
            ? 'تم إضافة $successCount عنصر، فشل إضافة $failCount عنصر'
            : 'Added $successCount items, failed to add $failCount items',
      );
    }

    return successCount > 0;
  }

  Future<void> _addSelectedItems() async {
    if (_selectedItems.isEmpty) {
      final isRtl = Localizations.localeOf(context).languageCode == 'ar';
      CustomToast.error(
        context,
        isRtl ? 'الرجاء اختيار عنصر واحد على الأقل' : 'Please select at least one item',
      );
      return;
    }

    final added = await _addItems(_selectedItems.values.toList());
    if (mounted) context.pop(added);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isRtl ? 'إضافة عناصر' : 'Add Items'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(isRtl),
          
          // Content
          Expanded(
            child: _currentStep == 0
                ? _buildCategoryStep(isRtl)
                : _buildItemsStep(isRtl),
          ),

          // Bottom Actions
          if (_currentStep == 1) _buildBottomActions(isRtl),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isRtl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: EasyStepper(
        activeStep: _currentStep,
        lineLength: 70,
        stepShape: StepShape.rRectangle,
        stepBorderRadius: 15,
        borderThickness: 4,
        stepRadius: 25,
        finishedStepBorderColor: AppColors.primary,
        finishedStepTextColor: AppColors.primary,
        finishedStepBackgroundColor: AppColors.primary,
        activeStepIconColor: Colors.white,
        activeStepBackgroundColor: AppColors.primary,
        activeStepBorderColor: AppColors.primary,
        unreachedStepBackgroundColor: Colors.grey.shade200,
        unreachedStepBorderColor: Colors.grey.shade300,
        unreachedStepTextColor: Colors.grey.shade600,
        activeStepTextColor:AppColors.primary,
        lineColor: Colors.grey.shade400,
        lineSpace:5,
        lineType: LineType.dotted,
        showLoadingAnimation: false,
        steps: [
          EasyStep(
            icon: const Icon(Icons.category_outlined),
            title: isRtl ? 'الفئة' : 'Category',
            finishIcon: const Icon(Icons.check, color: Colors.white),
          ),
          EasyStep(
            icon: const Icon(Icons.inventory_2_outlined),
            title: isRtl ? 'العناصر' : 'Items',
            finishIcon: const Icon(Icons.check, color: Colors.white),
          ),
        ],
        onStepReached: (index) {
          // Allow going back to previous steps
          if (index < _currentStep) {
            setState(() {
              _currentStep = index;
              if (index == 0) {
                _selectedItems.clear();
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildCategoryStep(bool isRtl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRtl ? 'اختر الفئة' : 'Select Category',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRtl
                ? 'اختر الفئة المناسبة للعناصر التي تريد إضافتها'
                : 'Choose the appropriate category for items you want to add',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoadingCategories)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_aiCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(Icons.category_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      isRtl ? 'لا توجد فئات متاحة' : 'No categories available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ..._aiCategories.map((category) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCategoryCard(
                    name: category.name,
                    icon: Icons.category_outlined,
                    isOther: false,
                    isRtl: isRtl,
                  ),
                )),
                // "Other" option
                _buildCategoryCard(
                  name: isRtl ? 'أخرى' : 'Other',
                  icon: Icons.add_circle_outline,
                  isOther: true,
                  isRtl: isRtl,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String name,
    required IconData icon,
    required bool isOther,
    required bool isRtl,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isOther) {
            _navigateToCustomItem();
          } else {
            final category = _aiCategories.firstWhere(
              (c) => c.name == name,
            );
            _selectCategory(category);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:  AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color:  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:  AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOther
                          ? (isRtl ? 'أضف عنصر مخصص' : 'Add custom item')
                          : (isRtl ? 'عرض العناصر المقترحة' : 'View suggested items'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color:  AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsStep(bool isRtl) {
    return Column(
      children: [

        // Items List
        Expanded(
          child: _isLoadingItems
              ? const Center(child: CircularProgressIndicator())
              : _aiItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              isRtl
                                  ? 'لا توجد عناصر في هذه الفئة'
                                  : 'No items in this category',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _aiItems.length + 1, // +1 for "Other"
                      itemBuilder: (context, index) {
                        if (index == _aiItems.length) {
                          // "Other" option
                          return _buildOtherItemCard(isRtl);
                        }
                        final item = _aiItems[index];
                        final isSelected = _selectedItems.containsKey(item.name);
                        return _buildItemCard(item, isSelected, isRtl);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildOtherItemCard(bool isRtl) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: _navigateToCustomItem,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'أخرى' : 'Other',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRtl
                          ? 'أضف عنصر مخصص'
                          : 'Add custom item',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(AIItemModel item, bool isSelected, bool isRtl) {
    final selectedItem = _selectedItems[item.name];

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleItem(item),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? AppColors.primary : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.weight} kg',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                 if (isSelected && selectedItem != null) ...[
                  const SizedBox(width: 8),
               GestureDetector(
                    onTap: () => _toggleItemEssential(item.name),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedItem.essential
                            ? Colors.amber.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedItem.essential
                              ? Colors.amber
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedItem.essential
                                ? Icons.star
                                : Icons.star_border,
                            color: selectedItem.essential
                                ? Colors.amber.shade700
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRtl ? 'ضروري' : 'Essential',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selectedItem.essential
                                  ? Colors.amber.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
               
                      ],
                ],
              ),
            ),
          ),
          if (isSelected && selectedItem != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isRtl ? 'الكمية' : 'Quantity',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildQuantitySelector(
                        selectedItem.quantity,
                        (qty) => _updateItemQuantity(item.name, qty),
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

  Widget _buildQuantitySelector(int quantity, ValueChanged<int> onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  color: quantity > 1
                      ? AppColors.primary
                      : Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(quantity + 1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isRtl) {
    final selectedCount = _selectedItems.length;
    final totalWeight = _selectedItems.values.fold<double>(
      0,
      (sum, item) => sum + item.totalWeight,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedCount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$selectedCount ${isRtl ? 'عنصر' : 'items'} • ${totalWeight.toStringAsFixed(2)} kg',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                        _selectedItems.clear();
                      });
                    }, child: Text(!isRtl? "Back" : "الرجوع")),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: selectedCount > 0 ? _addSelectedItems : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCount > 0
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: selectedCount > 0 ? 4 : 0,
                      ),
                      child: Text(
                        isRtl
                            ? 'إضافة العناصر ($selectedCount)'
                            : 'Add Items ($selectedCount)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Item Screen
class CustomItemScreen extends ConsumerStatefulWidget {
  final int bagId;
  final String? categoryName;

  const CustomItemScreen({
    super.key,
    required this.bagId,
    this.categoryName,
  });

  @override
  ConsumerState<CustomItemScreen> createState() => _CustomItemScreenState();
}

class _CustomItemScreenState extends ConsumerState<CustomItemScreen> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  bool _isEssential = false;
  int _quantity = 1;
  
  // Weight estimation
  Timer? _debounceTimer;
  bool _isEstimatingWeight = false;
  bool _hasEstimatedWeight = false;
  bool _isSettingEstimatedWeight = false;

  @override
  void initState() {
    super.initState();
    _itemNameController.addListener(_onItemNameChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _itemNameController.removeListener(_onItemNameChanged);
    _itemNameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onItemNameChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer for debounce (1.5 seconds)
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      final itemName = _itemNameController.text.trim();
      if (itemName.isNotEmpty && _weightController.text.trim().isEmpty) {
        _estimateWeight();
      }
    });
  }

  Future<void> _estimateWeight() async {
    final itemName = _itemNameController.text.trim();
    if (itemName.isEmpty) return;

    setState(() {
      _isEstimatingWeight = true;
      _hasEstimatedWeight = false;
    });

    try {
      final repository = ref.read(bagRepositoryProvider);
      final result = await repository.estimateWeight(itemName);
      
      if (mounted) {
        final estimatedWeight = result['estimated_weight_kg'] as double?;
        if (estimatedWeight != null && estimatedWeight > 0) {
          setState(() {
            _isSettingEstimatedWeight = true;
            _weightController.text = estimatedWeight.toStringAsFixed(2);
            _hasEstimatedWeight = true;
            _isEstimatingWeight = false;
            _isSettingEstimatedWeight = false;
          });
        } else {
          setState(() {
            _isEstimatingWeight = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error estimating weight: $e');
      if (mounted) {
        setState(() {
          _isEstimatingWeight = false;
        });
        // Don't show error to user - they can still enter weight manually
      }
    }
  }

  void _addItem() {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context);
    
    if (_itemNameController.text.trim().isEmpty) {
      CustomToast.error(
        context,
        isRtl ? 'الرجاء إدخال اسم العنصر' : 'Please enter item name',
      );
      return;
    }

    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      CustomToast.error(
        context,
        isRtl ? 'الرجاء إدخال الوزن' : 'Please enter weight',
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      CustomToast.error(
        context,
        isRtl ? 'الرجاء إدخال وزن صحيح' : 'Please enter a valid weight',
      );
      return;
    }

    final bagState = ref.read(bagControllerProvider);
    BagDetailModel? bagDetail;
    try {
      bagDetail = bagState.bagDetails.firstWhere(
        (detail) => detail.bagId == widget.bagId,
      );
    } catch (e) {
      bagDetail = bagState.getSelectedBagDetail();
      if (bagDetail == null && bagState.bagDetails.isNotEmpty) {
        bagDetail = bagState.bagDetails.first;
      }
    }

    if (bagDetail != null) {
      final itemTotalWeight = weight * _quantity;
      final newTotalWeight = bagDetail.currentWeight + itemTotalWeight;
      
      if (newTotalWeight > bagDetail.maxWeight) {
        CustomToast.error(
          context,
          l10n.weightExceededMessage(
            bagDetail.maxWeight.toStringAsFixed(1),
            bagDetail.currentWeight.toStringAsFixed(1),
            itemTotalWeight.toStringAsFixed(1),
          ),
        );
        return;
      }
    }

    final item = SelectedItemModel(
      name: _itemNameController.text.trim(),
      weight: weight,
      quantity: _quantity,
      essential: _isEssential,
      categoryName: null,
      isCustom: true,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isRtl ? 'عنصر مخصص' : 'Custom Item'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRtl ? 'أضف عنصر مخصص' : 'Add Custom Item',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRtl
                  ? 'أدخل اسم العنصر والوزن'
                  : 'Enter item name and weight',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Item Name
            Text(
              isRtl ? 'اسم العنصر *' : 'Item Name *',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                hintText: isRtl ? 'مثال: شاحن الهاتف' : 'e.g., Phone Charger',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 24),

            // Weight Input
            Row(
              children: [
                Expanded(
                  child: Text(
                    isRtl ? 'الوزن (كجم) *' : 'Weight (kg) *',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_itemNameController.text.trim().isNotEmpty)
                  TextButton.icon(
                    onPressed: _isEstimatingWeight ? null : _estimateWeight,
                    icon: _isEstimatingWeight
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      isRtl ? 'تقدير الوزن' : 'Estimate',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                // Reset estimated weight flag if user manually changes weight
                if (_hasEstimatedWeight && !_isSettingEstimatedWeight) {
                  setState(() {
                    _hasEstimatedWeight = false;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: isRtl ? 'مثال: 0.5' : 'e.g., 0.5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: _isEstimatingWeight
                    ? const SizedBox(
                        width: 48,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : const Icon(Icons.scale_outlined),
                suffixIcon: _hasEstimatedWeight
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isRtl ? 'مقدر' : 'AI',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'kg',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Quantity
            Text(
              isRtl ? 'الكمية' : 'Quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildQuantitySelector(_quantity, (qty) {
              setState(() {
                _quantity = qty;
              });
            }),
            const SizedBox(height: 24),

            // Essential Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: _isEssential ? Colors.amber : Colors.grey.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'غرض ضروري' : 'Essential Item',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isRtl
                              ? 'تمييز كغرض لا يمكن السفر بدونه'
                              : 'Mark as must-have item',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEssential,
                    onChanged: (value) {
                      setState(() {
                        _isEssential = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  isRtl ? 'إضافة العنصر' : 'Add Item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(int quantity, ValueChanged<int> onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  color: quantity > 1
                      ? AppColors.primary
                      : Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(quantity + 1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
