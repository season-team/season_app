import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/features/home/data/models/bag_detail_model.dart';
import 'package:season_app/features/home/providers/bag_providers.dart';
import 'package:season_app/shared/widgets/custom_toast.dart';

class EditBagScreen extends ConsumerStatefulWidget {
  final BagDetailModel bag;

  const EditBagScreen({
    super.key,
    required this.bag,
  });

  @override
  ConsumerState<EditBagScreen> createState() => _EditBagScreenState();
}

class _EditBagScreenState extends ConsumerState<EditBagScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _destinationController;
  late TextEditingController _durationController;
  late TextEditingController _maxWeightController;
  
  DateTime? _selectedDate;
  String? _selectedTripType;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _tripTypes = [
    {'name': 'سياحة', 'nameEn': 'Tourism', 'icon': Icons.flight, 'color': const Color(0xFF6366F1)},
    {'name': 'عمل', 'nameEn': 'Business', 'icon': Icons.business, 'color': const Color(0xFF3B82F6)},
    {'name': 'علاج', 'nameEn': 'Medical', 'icon': Icons.medical_services, 'color': const Color(0xFFEF4444)},
    {'name': 'عائلية', 'nameEn': 'Family', 'icon': Icons.family_restroom, 'color': const Color(0xFFEC4899)},
    {'name': 'الجيم', 'nameEn': 'Gym', 'icon': Icons.fitness_center, 'color': const Color(0xFF10B981)},
    {'name': 'أخرى', 'nameEn': 'Other', 'icon': Icons.more_horiz, 'color': const Color(0xFF6B7280)},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bag.bagName);
    _destinationController = TextEditingController(text: widget.bag.destination ?? '');
    _durationController = TextEditingController(text: widget.bag.duration?.toString() ?? '4');
    _maxWeightController = TextEditingController(text: widget.bag.maxWeight.toStringAsFixed(1));
    _selectedDate = widget.bag.departureDate;
    _selectedTripType = widget.bag.tripType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _durationController.dispose();
    _maxWeightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365 * 2));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: isRtl ? const Locale('ar') : const Locale('en'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateBag() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTripType == null) {
      final isRtl = Localizations.localeOf(context).languageCode == 'ar';
      CustomToast.error(
        context,
        isRtl ? 'يرجى اختيار نوع الرحلة' : 'Please select a trip type',
      );
      return;
    }

    if (_selectedDate == null) {
      final isRtl = Localizations.localeOf(context).languageCode == 'ar';
      CustomToast.error(
        context,
        isRtl ? 'يرجى اختيار تاريخ المغادرة' : 'Please select departure date',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(bagControllerProvider.notifier).updateBag(
            bagId: widget.bag.bagId,
            name: _nameController.text.trim(),
            destination: _destinationController.text.trim(),
            duration: int.tryParse(_durationController.text),
            maxWeight: double.tryParse(_maxWeightController.text),
            tripType: _selectedTripType,
            departureDate: _selectedDate,
          );

      if (!mounted) return;

      final isRtl = Localizations.localeOf(context).languageCode == 'ar';

      if (success) {
        CustomToast.success(
          context,
          isRtl ? 'تم تحديث الحقيبة بنجاح' : 'Bag updated successfully',
        );
        context.pop(true); // Return true to indicate success
      } else {
        CustomToast.error(
          context,
          isRtl ? 'فشل تحديث الحقيبة' : 'Failed to update bag',
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomToast.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      final isRtl = Localizations.localeOf(context).languageCode == 'ar';
      CustomToast.error(
        context,
        isRtl ? 'حدث خطأ أثناء تحديث الحقيبة' : 'Error updating bag',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isRtl ? 'تعديل الحقيبة' : 'Edit Bag',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRtl ? 'تعديل تفاصيل الحقيبة' : 'Edit Bag Details',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isRtl ? 'قم بتحديث معلومات حقيبتك' : 'Update your bag information',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bag Name
                  Text(
                    isRtl ? 'اسم الحقيبة' : 'Bag Name',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: isRtl ? 'اسم الحقيبة' : 'Bag name',
                      prefixIcon: const Icon(Icons.luggage_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isRtl ? 'يرجى إدخال اسم الحقيبة' : 'Please enter bag name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Destination
                  Text(
                    isRtl ? 'الوجهة' : 'Destination',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      hintText: isRtl ? 'الوجهة' : 'Destination',
                      prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isRtl ? 'يرجى إدخال الوجهة' : 'Please enter destination';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Trip Type
                  Text(
                    isRtl ? 'نوع الرحلة' : 'Trip Type',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _tripTypes.length,
                    itemBuilder: (context, index) {
                      final tripType = _tripTypes[index];
                      final isSelected = _selectedTripType == tripType['name'];
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTripType = tripType['name'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (tripType['color'] as Color).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? tripType['color'] as Color
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tripType['icon'] as IconData,
                                size: 24,
                                color: isSelected
                                    ? tripType['color'] as Color
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isRtl
                                    ? tripType['name'] as String
                                    : tripType['nameEn'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? tripType['color'] as Color
                                      : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Duration and Max Weight
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRtl ? 'المدة (أيام)' : 'Duration (days)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: isRtl ? 'المدة' : 'Duration',
                                prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return isRtl ? 'مطلوب' : 'Required';
                                }
                                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                  return isRtl ? 'رقم غير صحيح' : 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRtl ? 'الحد الأقصى (كجم)' : 'Max Weight (kg)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _maxWeightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: isRtl ? 'الوزن' : 'Weight',
                                prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return isRtl ? 'مطلوب' : 'Required';
                                }
                                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                  return isRtl ? 'رقم غير صحيح' : 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Departure Date
                  Text(
                    isRtl ? 'تاريخ المغادرة' : 'Departure Date',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? DateFormat('yyyy-MM-dd', 'en').format(_selectedDate!)
                                  : (isRtl ? 'اختر تاريخ المغادرة' : 'Select departure date'),
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateBag,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isRtl ? 'حفظ التغييرات' : 'Save Changes',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

