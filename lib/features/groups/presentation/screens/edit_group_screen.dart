import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/groups/providers.dart';
import 'package:season_app/shared/widgets/custom_button.dart';
import 'package:season_app/shared/widgets/custom_text_field.dart';

class EditGroupScreen extends ConsumerStatefulWidget {
  final int groupId;
  
  const EditGroupScreen({super.key, required this.groupId});

  @override
  ConsumerState<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends ConsumerState<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int _safetyRadius = 100;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current group data
    Future.microtask(() {
      final group = ref.read(groupsControllerProvider).selectedGroup;
      if (group != null) {
        _nameController = TextEditingController(text: group.name);
        _descriptionController = TextEditingController(text: group.description ?? '');
        _safetyRadius = group.safetyRadius < 30 ? 30 : group.safetyRadius;
        _notificationsEnabled = group.notificationsEnabled;
        setState(() {});
      }
    });
    
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(groupsControllerProvider.notifier).updateGroup(
      groupId: widget.groupId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      safetyRadius: _safetyRadius,
      notificationsEnabled: _notificationsEnabled,
    );

    if (success && mounted) {
      context.pop();
      // Reload group details
      ref.read(groupsControllerProvider.notifier).loadGroupDetails(widget.groupId);
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
          isRtl ? 'تعديل المجموعة' : 'Edit Group',
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
              // Header icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Group Name
              Text(
                isRtl ? 'اسم المجموعة' : 'Group Name',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                hintText: isRtl ? 'مثال: رحلة دبي - العائلة' : 'Example: Dubai Trip - Family',
                prefixIcon: const Icon(Icons.group),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isRtl ? 'الرجاء إدخال اسم المجموعة' : 'Please enter group name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                isRtl ? 'الوصف (اختياري)' : 'Description (Optional)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(hintText: isRtl ? 'أضف وصفاً للمجموعة' : 'Add group description', controller: _descriptionController, prefixIcon: const Icon(Icons.description_outlined),),
              const SizedBox(height: 20),

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

              // Notifications toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRtl ? 'تفعيل الإشعارات' : 'Enable Notifications',
                            style: const TextStyle(
                              fontSize: 15,
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

              // Update Button
              CustomButton(
                text: isRtl ? 'حفظ التغييرات' : 'Save Changes',
                onPressed: _updateGroup,
                isLoading: groupsState.isLoading,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

