import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/home/data/models/bag_category_model.dart';
import 'package:season_app/features/home/providers/bag_providers.dart';

class BagItemSelection {
  final BagCategoryModel category;
  final String itemName;
  final double weight;
  final String weightUnit;
  final int quantity;
  final bool essential;

  BagItemSelection({
    required this.category,
    required this.itemName,
    required this.weight,
    required this.weightUnit,
    required this.quantity,
    required this.essential,
  });
}

class AddBagItemSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const AddBagItemSheet({
    super.key,
    required this.scrollController,
  });

  @override
  ConsumerState<AddBagItemSheet> createState() => _AddBagItemSheetState();
}

class _AddBagItemSheetState extends ConsumerState<AddBagItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _categoryFieldKey = GlobalKey<FormFieldState<BagCategoryModel>>();

  List<BagCategoryModel> _categories = [];
  BagCategoryModel? _selectedCategory;
  String _selectedWeightUnit = 'kg';
  int _quantity = 1;
  bool _isEssential = false;

  @override
  void initState() {
    super.initState();
    final bagState = ref.read(bagControllerProvider);
    _categories = _dedupeCategories(bagState.categories);

    final initialCategory = bagState.selectedCategory;
    if (initialCategory != null) {
      _selectedCategory =
          _findCategoryById(_categories, initialCategory.id) ??
              (_categories.isNotEmpty ? _categories.first : null);
    } else if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final category = _selectedCategory;
    final itemName = _itemNameController.text.trim();
    final weightText = _weightController.text.trim();
    
    if (category == null || itemName.isEmpty || weightText.isEmpty || _quantity <= 0) return;
    
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      return;
    }
    
    Navigator.of(context).pop(
      BagItemSelection(
        category: category,
        itemName: itemName,
        weight: weight,
        weightUnit: _selectedWeightUnit,
        quantity: _quantity,
        essential: _isEssential,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    final canSubmit = _selectedCategory != null && 
        _itemNameController.text.trim().isNotEmpty && 
        _weightController.text.trim().isNotEmpty && 
        _quantity > 0;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          Flexible(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        isRtl ? 'إضافة غرض جديد' : 'Add New Item',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          isRtl ? 'لا توجد فئات' : 'No categories available',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      // Item Name
                      Text(
                        isRtl ? 'اسم الغرض *' : 'Item Name *',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _itemNameController,
                        decoration: _inputDecoration(
                          hintText: isRtl ? 'مثال: شاحن هاتف' : 'e.g., Phone Charger',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isRtl ? 'يرجى إدخال اسم الغرض' : 'Please enter item name';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      
                      // Category Selection
                      Text(
                        isRtl ? 'الفئة *' : 'Category *',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<BagCategoryModel>(
                        key: _categoryFieldKey,
                        value: _selectedCategory,
                        decoration: _inputDecoration(),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _categoryIcon(category),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        category.getName(isRtl ? 'ar' : 'en'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        validator: (value) => value == null
                            ? (isRtl ? 'يرجى اختيار الفئة' : 'Please select a category')
                            : null,
                      ),
                      const SizedBox(height: 20),
                      
                      // Weight and Unit
                      Text(
                        isRtl ? 'الوزن *' : 'Weight *',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _weightController,
                              decoration: _inputDecoration(
                                hintText: '0.0',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return isRtl ? 'يرجى إدخال الوزن' : 'Enter weight';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null || weight <= 0) {
                                  return isRtl ? 'وزن غير صحيح' : 'Invalid weight';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedWeightUnit,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  border: InputBorder.none,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'kg',
                                    child: Text('kg'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'g',
                                    child: Text('g'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedWeightUnit = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Quantity
                      Text(
                        isRtl ? 'الكمية' : 'Quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _QuantitySelector(
                        quantity: _quantity,
                        onDecrement: _decrementQuantity,
                        onIncrement: _incrementQuantity,
                      ),
                      const SizedBox(height: 20),
                      
                      // Essential Toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
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
                                    isRtl ? 'تمييز كغرض لا يمكن السفر بدونه' : 'Mark as must-have item',
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
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: canSubmit ? _onSubmit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSubmit ? AppColors.primary : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isRtl ? 'إضافة الغرض' : 'Add Item',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  List<BagCategoryModel> _dedupeCategories(List<BagCategoryModel> categories) {
    final seen = <int>{};
    final unique = <BagCategoryModel>[];
    for (final category in categories) {
      if (seen.add(category.id)) {
        unique.add(category);
      }
    }
    return unique;
  }

  BagCategoryModel? _findCategoryById(
    List<BagCategoryModel> categories,
    int id,
  ) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Widget _categoryIcon(BagCategoryModel category) {
    // Parse icon color
    Color iconColor = AppColors.primary;
    if (category.iconColor != null && category.iconColor!.isNotEmpty) {
      try {
        final colorStr = category.iconColor!.replaceAll('#', '');
        iconColor = Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {}
    }

    if (category.icon != null && category.icon!.isNotEmpty) {
      // Check if it's a URL
      if (category.icon!.startsWith('http')) {
        return CircleAvatar(
          radius: 14,
          backgroundColor: iconColor.withOpacity(0.1),
          child: ClipOval(
            child: Image.network(
              category.icon!,
              width: 20,
              height: 20,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.category_outlined,
                size: 18,
                color: iconColor,
              ),
            ),
          ),
        );
      }
      
      // Map icon names to Flutter icons
      IconData iconData = Icons.category_outlined;
      switch (category.icon!.toLowerCase()) {
        case 'phone':
        case 'smartphone':
          iconData = Icons.phone_android;
          break;
        case 'laptop':
          iconData = Icons.laptop;
          break;
        case 'shirt':
        case 'clothing':
          iconData = Icons.checkroom;
          break;
        case 'shoe':
        case 'shoes':
          iconData = Icons.directions_walk;
          break;
        case 'medical':
        case 'medicine':
          iconData = Icons.medical_services;
          break;
        case 'document':
        case 'documents':
          iconData = Icons.description;
          break;
        case 'toiletries':
          iconData = Icons.shower;
          break;
        case 'food':
          iconData = Icons.fastfood;
          break;
        case 'camera':
          iconData = Icons.camera_alt;
          break;
      }
      
      return CircleAvatar(
        radius: 14,
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(
          iconData,
          size: 16,
          color: iconColor,
        ),
      );
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(
        Icons.category_outlined,
        size: 16,
        color: iconColor,
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDecrement,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 48,
                height: 48,
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
            width: 60,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.symmetric(
                vertical: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
            ),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onIncrement,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: 48,
                height: 48,
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
