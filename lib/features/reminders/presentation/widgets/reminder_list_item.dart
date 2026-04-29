import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/reminders/data/models/reminder_model.dart';

class ReminderListItem extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(BuildContext context) {
    try {
      final date = DateTime.parse(reminder.date);
      return intl.DateFormat.yMMMMd(intl.Intl.getCurrentLocale()).format(date);
    } catch (_) {
      return reminder.date;
    }
  }

  String _formatTime(BuildContext context) {
    try {
      final parts = reminder.time.split(':');
      final dateTime = DateTime(
        0,
        1,
        1,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return intl.DateFormat.jm(intl.Intl.getCurrentLocale()).format(dateTime);
    } catch (_) {
      return reminder.time;
    }
  }

  String _recurrenceLabel(BuildContext context) {
    final recurrence = reminder.recurrence.toLowerCase();
    final loc = AppLocalizations.of(context);
    if (recurrence.contains('once') || recurrence.contains('مرة')) {
      return loc.reminderRecurrenceOnce;
    } else if (recurrence.contains('daily') || recurrence.contains('يومي')) {
      return loc.reminderRecurrenceDaily;
    } else if (recurrence.contains('week') || recurrence.contains('أسبوع')) {
      return loc.reminderRecurrenceWeekly;
    } else if (recurrence.contains('month') || recurrence.contains('شهر')) {
      return _monthlyLabel(context);
    }
    return reminder.recurrence;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = reminder.status == 'active';


    final hasAttachment = reminder.attachment != null && reminder.attachment!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
         
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
          
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _leadingVisual(hasAttachment: hasAttachment, isActive: isActive),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (reminder.notes != null &&
                              reminder.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              reminder.notes!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _statusBadge(context, isActive),
                        const SizedBox(height: 8),
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _bottomMeta(
                        icon: Icons.calendar_today,
                        text: _formatDate(context),
                      ),
                      _bottomMeta(
                        icon: Icons.access_time,
                        text: _formatTime(context),
                      ),
                      _bottomMeta(
                        icon: Icons.repeat,
                        text: _recurrenceLabel(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, bool isActive) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final label = isActive
        ? (localeCode == 'ar' ? 'نشط' : 'Active')
        : (localeCode == 'ar' ? 'متوقف' : 'Paused');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.12)
            : AppColors.textSecondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle_filled,
            size: 14,
            color: isActive ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomMeta({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _leadingVisual({required bool hasAttachment, required bool isActive}) {
    if (hasAttachment) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Image.network(
            reminder.attachment!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _leadingPlaceholder(isActive);
            },
          ),
        ),
      );
    }
    return _leadingPlaceholder(isActive);
  }

  Widget _leadingPlaceholder(bool isActive) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isActive ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.event_note,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }

  String _monthlyLabel(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return localeCode == 'ar' ? 'شهري' : 'Monthly';
  }
}

