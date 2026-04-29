import 'package:flutter/material.dart';
import 'package:season_app/core/constants/app_colors.dart';

class UserInfo {
  final int id;
  final String name;
  final String? avatar;
  final String role;
  final bool isOnline;

  const UserInfo({
    required this.id,
    required this.name,
    this.avatar,
    this.role = 'user',
    this.isOnline = false,
  });
}

class RemoveUserDialog extends StatelessWidget {
  final UserInfo user;
  final VoidCallback onConfirm;
  final bool isRtl;
  final String? title;
  final String? warningMessage;

  const RemoveUserDialog({
    super.key,
    required this.user,
    required this.onConfirm,
    this.isRtl = false,
    this.title,
    this.warningMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_remove,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title ?? (isRtl ? 'إزالة مستخدم' : 'Remove User'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // User info - compact
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: user.avatar != null 
                            ? NetworkImage(user.avatar!)
                            : null,
                        child: user.avatar == null
                            ? Text(
                                user.name.isNotEmpty 
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      
                      // User details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getRoleDisplayName(user.role, isRtl),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Role indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRoleEmoji(user.role),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Warning message - compact
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warningMessage ?? (isRtl 
                                ? 'سيتم إزالة المستخدم نهائياً'
                                : 'User will be permanently removed'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Action buttons - compact
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isRtl ? 'إلغاء' : 'Cancel',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Remove button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isRtl ? 'إزالة' : 'Remove',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role, bool isRtl) {
    switch (role.toLowerCase()) {
      case 'owner':
        return isRtl ? 'مالك' : 'Owner';
      case 'admin':
        return isRtl ? 'مدير' : 'Admin';
      case 'moderator':
        return isRtl ? 'مشرف' : 'Moderator';
      case 'member':
        return isRtl ? 'عضو' : 'Member';
      default:
        return isRtl ? 'مستخدم' : 'User';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return AppColors.primary;
      case 'admin':
        return Colors.orange;
      case 'moderator':
        return Colors.blue;
      case 'member':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getRoleEmoji(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return '👑';
      case 'admin':
        return '🛡️';
      case 'moderator':
        return '🔧';
      case 'member':
        return '👤';
      default:
        return '👤';
    }
  }

  /// Show the remove user dialog
  static Future<void> show({
    required BuildContext context,
    required UserInfo user,
    required VoidCallback onConfirm,
    bool isRtl = false,
    String? title,
    String? warningMessage,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => RemoveUserDialog(
        user: user,
        onConfirm: onConfirm,
        isRtl: isRtl,
        title: title,
        warningMessage: warningMessage,
      ),
    );
  }
}
