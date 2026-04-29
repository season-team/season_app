import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/features/home/providers/bag_providers.dart';
import 'package:season_app/shared/widgets/custom_toast.dart';

class CreateBagScreen extends ConsumerStatefulWidget {
  const CreateBagScreen({super.key});

  @override
  ConsumerState<CreateBagScreen> createState() => _CreateBagScreenState();
}

class _CreateBagScreenState extends ConsumerState<CreateBagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController(text: '4');
  final _maxWeightController = TextEditingController(text: '20');
  
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

    final pickedDate = await showDatePicker(
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

    if (pickedDate != null) {
      final selectedDateOnly = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      final currentTime = _selectedDate ?? now;
      
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentTime),
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

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            selectedDateOnly.year,
            selectedDateOnly.month,
            selectedDateOnly.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = DateTime(
            selectedDateOnly.year,
            selectedDateOnly.month,
            selectedDateOnly.day,
            currentTime.hour,
            currentTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createBag() async {
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
        isRtl ? 'يرجى اختيار تاريخ ووقت المغادرة' : 'Please select departure date & time',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bag = await ref.read(bagControllerProvider.notifier).createBag(
        name: _nameController.text.trim(),
        tripType: _selectedTripType!,
        duration: int.parse(_durationController.text),
        destination: _destinationController.text.trim(),
        departureDate: _selectedDate!,
        maxWeight: double.parse(_maxWeightController.text),
        status: 'draft',
      );

      if (!mounted) return;

      if (bag != null) {
        final isRtl = Localizations.localeOf(context).languageCode == 'ar';
        CustomToast.success(
          context,
          isRtl ? 'تم إنشاء الحقيبة بنجاح' : 'Bag created successfully',
        );
        
        // Navigate to the newly created bag
        if (mounted) {
          context.pop(); // Close create screen
          context.push('${Routes.bagDetails.replaceAll(':id', bag.bagId.toString())}');
        }
      } else {
        final isRtl = Localizations.localeOf(context).languageCode == 'ar';
        CustomToast.error(
          context,
          isRtl ? 'فشل إنشاء الحقيبة' : 'Failed to create bag',
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
        isRtl ? 'حدث خطأ' : 'An error occurred',
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isRtl ? 'إنشاء حقيبة جديدة' : 'Create New Bag',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.bagPrimaryButton.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.luggage,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isRtl ? 'ابدأ رحلتك بذكاء' : 'Start Your Journey Smart',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRtl 
                          ? 'أنشئ حقيبة جديدة وخطط لرحلتك بشكل مثالي'
                          : 'Create a new bag and plan your trip perfectly',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bag Name
              _buildSectionTitle(isRtl ? 'اسم الحقيبة' : 'Bag Name'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                hint: isRtl ? 'مثال: رحلة دبي' : 'e.g., Dubai Trip',
                icon: Icons.label_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRtl ? 'اسم الحقيبة مطلوب' : 'Bag name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Destination
              _buildSectionTitle(isRtl ? 'الوجهة' : 'Destination'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _destinationController,
                hint: isRtl ? 'مثال: دبي' : 'e.g., Dubai',
                icon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRtl ? 'الوجهة مطلوبة' : 'Destination is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Trip Type
              _buildSectionTitle(isRtl ? 'نوع الرحلة' : 'Trip Type'),
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  tripType['color'] as Color,
                                  (tripType['color'] as Color).withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.shade300,
                          width: isSelected ? 0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (tripType['color'] as Color).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tripType['icon'] as IconData,
                            size: 28,
                            color: isSelected
                                ? Colors.white
                                : (tripType['color'] as Color),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isRtl
                                ? tripType['name'] as String
                                : tripType['nameEn'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
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
              const SizedBox(height: 24),

              // Duration and Max Weight Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(isRtl ? 'المدة (أيام)' : 'Duration (days)'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _durationController,
                          hint: '4',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return isRtl ? 'المدة مطلوبة' : 'Duration is required';
                            }
                            final duration = int.tryParse(value);
                            if (duration == null || duration <= 0) {
                              return isRtl ? 'المدة يجب أن تكون رقم صحيح' : 'Duration must be a valid number';
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
                        _buildSectionTitle(isRtl ? 'الحد الأقصى (كجم)' : 'Max Weight (kg)'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _maxWeightController,
                          hint: '20',
                          icon: Icons.scale_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return isRtl ? 'الحد الأقصى مطلوب' : 'Max weight is required';
                            }
                            final weight = double.tryParse(value);
                            if (weight == null || weight <= 0) {
                              return isRtl ? 'الحد الأقصى يجب أن يكون رقم صحيح' : 'Max weight must be a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Departure Date and Time
              _buildSectionTitle(isRtl ? 'تاريخ ووقت المغادرة' : 'Departure Date & Time'),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('yyyy-MM-dd HH:mm', 'en').format(_selectedDate!)
                              : (isRtl ? 'اختر تاريخ ووقت المغادرة' : 'Select departure date & time'),
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate != null
                                ? AppColors.textPrimary
                                : Colors.grey.shade600,
                            fontWeight: _selectedDate != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBag,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
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
                            const Icon(Icons.add_circle_outline, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              isRtl ? 'إنشاء الحقيبة' : 'Create Bag',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
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
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

