import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/reminders/data/models/reminder_model.dart';
import 'package:season_app/features/reminders/presentation/widgets/reminder_list_item.dart';
import 'package:season_app/features/reminders/providers.dart';
import 'package:season_app/features/home/presentation/widgets/bag/bag_widget_helpers.dart';

class BagRemindersSectionWidget extends ConsumerWidget {
  final VoidCallback onAddReminder;
  final void Function(ReminderModel) onEditReminder;
  final void Function(int) onDeleteReminder;

  const BagRemindersSectionWidget({
    super.key,
    required this.onAddReminder,
    required this.onEditReminder,
    required this.onDeleteReminder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(remindersProvider);

    // Filter out completed reminders
    final activeReminders = state.reminders
        .where((reminder) => reminder.status.toLowerCase() != 'completed')
        .toList();

    final List<Widget> content = [];

    final errorBanner = _buildErrorBanner(context, ref, state, loc);
    if (errorBanner != null) {
      content.add(errorBanner);
      content.add(const SizedBox(height: 12));
    }

    if (state.isLoading) {
      content.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (activeReminders.isEmpty) {
      content.add(
        Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.18),
            ),
            const SizedBox(height: 16),
            Text(
              loc.bagRemindersEmptyTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.bagRemindersEmptyDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    } else {
      for (var i = 0; i < activeReminders.length; i++) {
        final reminder = activeReminders[i];
        content.add(
          Padding(
            padding: EdgeInsets.only(bottom: i == activeReminders.length - 1 ? 0 : 12),
            child: ReminderListItem(
              reminder: reminder,
              onTap: () => onEditReminder(reminder),
              onDelete: () => onDeleteReminder(reminder.reminderId),
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BagWidgetHelpers.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.bagRemindersTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.bagRemindersActiveCount(state.activeCount),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onAddReminder,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  loc.bagAddReminderButton,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content,
        ],
      ),
    );
  }

  Widget? _buildErrorBanner(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
    AppLocalizations loc,
  ) {
    if (state.error == null) return null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.reminderLoadError,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(remindersProvider.notifier).loadReminders(),
            child: Text(loc.retry),
          ),
        ],
      ),
    );
  }
}
