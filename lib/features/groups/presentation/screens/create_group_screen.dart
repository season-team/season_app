import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/groups/providers.dart';
import 'package:season_app/shared/widgets/custom_button.dart';
import 'package:season_app/shared/widgets/custom_text_field.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _safetyRadius = 100;
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(groupsControllerProvider.notifier).createGroup(
      name: _nameController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      safetyRadius: _safetyRadius,
      notificationsEnabled: _notificationsEnabled,
    );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsControllerProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isRtl ? 'إنشاء مجموعة جديدة' : 'Create New Group',
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                        Icons.group_add,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        isRtl
                            ? 'أنشئ مجموعة لتتبع أصدقائك وعائلتك'
                            : 'Create a group to track your friends and family',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Name Field
              Text(
                isRtl ? 'اسم المجموعة *' : 'Group Name *',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                hintText: isRtl ? 'مثال: رحلة دبي - العائلة' : 'Ex: Dubai Trip - Family',
                prefixIcon: const Icon(Icons.label_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isRtl ? 'الرجاء إدخال اسم المجموعة' : 'Please enter group name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description Field
              Text(
                isRtl ? 'الوصف (اختياري)' : 'Description (Optional)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                hintText: isRtl ? 'أضف وصفاً للمجموعة' : 'Add a description',
                prefixIcon: const Icon(Icons.description_outlined),
              ),

              const SizedBox(height: 24),

              // Safety Radius Slider
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.radio_button_unchecked, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          isRtl ? 'نطاق الأمان' : 'Safety Radius',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_safetyRadius ${isRtl ? "متر" : "meters"}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.secondary,
                        inactiveTrackColor: Colors.grey.shade300,
                        thumbColor: AppColors.secondary,
                        overlayColor: AppColors.secondary.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _safetyRadius.toDouble(),
                        min: 30,
                        max: 1000,
                        divisions: 97,
                        onChanged: (value) {
                          setState(() {
                            _safetyRadius = value.toInt();
                          });
                        },
                      ),
                    ),
                    Text(
                      isRtl
                          ? 'المسافة المسموح بها قبل إرسال تنبيه'
                          : 'Distance allowed before sending alert',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Notifications Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRtl ? 'تفعيل الإشعارات' : 'Enable Notifications',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            isRtl
                                ? 'احصل على تنبيهات فورية'
                                : 'Get instant alerts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Create Button
              CustomButton(
                text: isRtl ? 'إنشاء المجموعة' : 'Create Group',
                onPressed: _createGroup,
                isLoading: groupsState.isCreating,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

