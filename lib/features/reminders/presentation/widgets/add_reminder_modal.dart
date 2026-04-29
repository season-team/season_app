import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:season_app/core/utils/timezone_helper.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/reminders/data/models/reminder_model.dart';
import 'package:season_app/features/reminders/providers.dart';
import 'package:season_app/shared/helpers/image_picker_helper.dart';

class AddReminderModal extends ConsumerStatefulWidget {
  final ReminderModel? reminder;

  const AddReminderModal({super.key, this.reminder});

  @override
  ConsumerState<AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends ConsumerState<AddReminderModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedRecurrence = 'once';
  File? _selectedImage;
  String? _existingAttachmentUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromReminder();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrateFromReminder() {
    final reminder = widget.reminder;
    if (reminder == null) return;

    _titleController.text = reminder.title;
    _notesController.text = reminder.notes ?? '';
    _selectedRecurrence = _normalizeRecurrence(reminder.recurrence);
    _existingAttachmentUrl = reminder.attachment;

    try {
      _selectedDate = DateTime.parse(reminder.date);
    } catch (_) {
      _selectedDate = null;
    }

    try {
      final parts = reminder.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      _selectedTime = null;
    }
  }

  Future<void> _selectDate() async {
    final locale = Localizations.localeOf(context);
    
    // When editing, allow past dates. When creating new, only allow future dates.
    final isEditing = widget.reminder != null;
    final initialDate = _selectedDate ?? DateTime.now();
    
    // Set firstDate: allow past dates when editing, otherwise only future dates
    final firstDate = isEditing 
        ? DateTime.now().subtract(const Duration(days: 365 * 2)) // Allow 2 years in the past when editing
        : DateTime.now(); // Only future dates for new reminders
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: locale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickImage(AppLocalizations loc) async {
    await ImagePickerHelper.showPickerDialog(
      context,
      (file) => setState(() {
        _selectedImage = file;
        _existingAttachmentUrl = null;
      }),
      loc,
    );
  }

  Map<String, String> _recurrenceOptions(AppLocalizations loc) => {
        'once': loc.reminderRecurrenceOnce,
        'daily': loc.reminderRecurrenceDaily,
        'weekly': loc.reminderRecurrenceWeekly,
        'monthly': _monthlyLabel(),
      };

  String _monthlyLabel() {
    final locale = intl.Intl.getCurrentLocale();
    if (locale.startsWith('ar')) {
      return 'شهري';
    }
    return 'Monthly';
  }

  String _normalizeRecurrence(String? value) {
    if (value == null) return 'once';
    final normalized = value.toLowerCase();
    if (normalized.contains('once') || normalized.contains('مرة')) return 'once';
    if (normalized.contains('daily') || normalized.contains('يومي')) return 'daily';
    if (normalized.contains('week') || normalized.contains('أسبوع')) return 'weekly';
    if (normalized.contains('month') || normalized.contains('شهر')) return 'monthly';
    if (normalized.contains('custom') || normalized.contains('مخصص')) return 'once';
    return 'once';
  }

  String _formatDate(DateTime date, AppLocalizations loc) {
    final localeName = intl.Intl.getCurrentLocale();
    return intl.DateFormat.yMMMMd(localeName).format(date);
  }

  String _formatTime(TimeOfDay time, AppLocalizations loc) {
    final dateTime = DateTime(0, 1, 1, time.hour, time.minute);
    final localeName = intl.Intl.getCurrentLocale();
    return intl.DateFormat.jm(localeName).format(dateTime);
  }

  Future<String> _getUserTimezone() async {
    return await TimezoneHelper.getDeviceTimezone();
  }

  Future<void> _saveReminder(AppLocalizations loc) async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_selectedDate == null) {
      messenger.showSnackBar(SnackBar(content: Text(loc.reminderDateValidation)));
      return;
    }

    if (_selectedTime == null) {
      messenger.showSnackBar(SnackBar(content: Text(loc.reminderTimeValidation)));
      return;
    }

    setState(() => _isLoading = true);

    final dateStr = intl.DateFormat('yyyy-MM-dd', 'en').format(_selectedDate!);
    final timeStr =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    // Get user's actual timezone
    final userTimezone = await _getUserTimezone();

    bool success;
    if (widget.reminder != null) {
      success = await ref.read(remindersProvider.notifier).updateReminder(
            reminderId: widget.reminder!.reminderId,
            title: _titleController.text,
            date: dateStr,
            time: timeStr,
            recurrence: _selectedRecurrence,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            timezone: userTimezone,
            attachment: _selectedImage,
          );
    } else {
      success = await ref.read(remindersProvider.notifier).createReminder(
            title: _titleController.text,
            date: dateStr,
            time: timeStr,
            recurrence: _selectedRecurrence,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            timezone: userTimezone,
            attachment: _selectedImage,
          );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.reminder != null
              ? loc.reminderUpdateSuccess
              : loc.reminderCreateSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.reminderSaveError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final recurrenceOptions = _recurrenceOptions(loc);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final selectedDateText = _selectedDate != null
        ? _formatDate(_selectedDate!, loc)
        : loc.reminderDatePlaceholder;
    final selectedTimeText = _selectedTime != null
        ? _formatTime(_selectedTime!, loc)
        : loc.reminderTimePlaceholder;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(loc),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel(loc.reminderTitleLabel),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: _inputDecoration(loc.reminderTitlePlaceholder),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return loc.reminderTitleValidation;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionLabel(loc.reminderDateLabel),
                                    const SizedBox(height: 8),
                                    _buildSelectionTile(
                                      text: selectedDateText,
                                      icon: Icons.calendar_today,
                                      isPlaceholder: _selectedDate == null,
                                      onTap: _selectDate,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionLabel(loc.reminderTimeLabel),
                                    const SizedBox(height: 8),
                                    _buildSelectionTile(
                                      text: selectedTimeText,
                                      icon: Icons.access_time,
                                      isPlaceholder: _selectedTime == null,
                                      onTap: _selectTime,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSectionLabel(loc.reminderRecurrenceLabel),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedRecurrence,
                              decoration: const InputDecoration(
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              items: recurrenceOptions.entries
                                  .map(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedRecurrence = value);
                                }
                              },
                              icon: const Icon(Icons.arrow_drop_down),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSectionLabel(loc.reminderNotesLabel),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: _inputDecoration(loc.reminderNotesPlaceholder),
                          ),
                          const SizedBox(height: 20),
                          _buildSectionLabel(loc.reminderAttachmentLabel),
                          const SizedBox(height: 8),
                          _buildAttachmentField(loc),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _saveReminder(loc),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.bagPrimaryButton,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      widget.reminder != null
                                          ? loc.reminderUpdateButton
                                          : loc.reminderAddButton,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reminder != null
                      ? loc.reminderEditTitle
                      : loc.reminderAddTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.reminderSubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  Widget _buildSelectionTile({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool isPlaceholder = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isPlaceholder
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(icon, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentField(AppLocalizations loc) {
    return InkWell(
      onTap: () => _pickImage(loc),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _selectedImage != null
            ? _buildAttachmentPreview(
                Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : (_existingAttachmentUrl != null
                ? _buildAttachmentPreview(
                    Image.network(
                      _existingAttachmentUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _placeholderAttachment(loc);
                      },
                    ),
                  )
                : _placeholderAttachment(loc)),
      ),
    );
  }

  Widget _buildAttachmentPreview(Widget image) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.expand(child: image),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _existingAttachmentUrl = null;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderAttachment(AppLocalizations loc) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            loc.reminderAttachmentAdd,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

