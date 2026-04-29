import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/groups/providers.dart';
import 'package:season_app/shared/widgets/custom_button.dart';
import 'package:season_app/shared/widgets/custom_text_field.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(groupsControllerProvider.notifier).joinGroup(
      _inviteCodeController.text.trim(),
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
          isRtl ? 'انضم لمجموعة' : 'Join Group',
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Illustration
              Container(
                padding: const EdgeInsets.all(32),
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
                  Icons.group_add_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                isRtl ? 'انضم إلى مجموعة' : 'Join a Group',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                isRtl
                    ? 'أدخل كود الدعوة للانضمام إلى المجموعة'
                    : 'Enter the invite code to join the group',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Invite Code Field
              CustomTextField(
                controller: _inviteCodeController,
                hintText: isRtl ? 'SEASON-XXXXX' : 'SEASON-XXXXX',
                prefixIcon: const Icon(Icons.vpn_key),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isRtl ? 'الرجاء إدخال كود الدعوة' : 'Please enter invite code';
                  }
                  if (!value.toUpperCase().startsWith('SEASON-')) {
                    return isRtl ? 'كود غير صالح' : 'Invalid code format';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isRtl
                            ? 'اطلب كود الدعوة من منشئ المجموعة'
                            : 'Ask the group owner for the invite code',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.info,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Join Button
              CustomButton(
                text: isRtl ? 'انضم الآن' : 'Join Now',
                onPressed: _joinGroup,
                isLoading: groupsState.isJoining,
                color: AppColors.primary,
              ),

              const SizedBox(height: 16),

              // Divider with text
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isRtl ? 'أو' : 'OR',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 16),

              // QR Scanner Button - Awesome Design
              Container(
                decoration: BoxDecoration(
           
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.secondary,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/groups/qr-scanner');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRtl ? 'مسح رمز QR' : 'Scan QR Code',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                         
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

