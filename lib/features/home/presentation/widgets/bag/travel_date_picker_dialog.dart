import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:season_app/core/constants/app_colors.dart';

class TravelDatePickerDialog extends StatefulWidget {
  final String? initialDate;
  final String? initialTime;
  final bool isRtl;

  const TravelDatePickerDialog({
    super.key,
    this.initialDate,
    this.initialTime,
    required this.isRtl,
  });

  @override
  State<TravelDatePickerDialog> createState() => _TravelDatePickerDialogState();

  static Future<Map<String, String>?> show(
    BuildContext context, {
    String? initialDate,
    String? initialTime,
  }) async {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => TravelDatePickerDialog(
        initialDate: initialDate,
        initialTime: initialTime,
        isRtl: isRtl,
      ),
    );
  }
}

class _TravelDatePickerDialogState extends State<TravelDatePickerDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  // Use English locale to ensure English numerals in date format
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd', 'en');

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = DateTime.tryParse(widget.initialDate!);
    }
    if (widget.initialTime != null) {
      final timeParts = widget.initialTime!.split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 0,
          minute: int.tryParse(timeParts[1]) ?? 0,
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _confirm() {
    if (_selectedDate != null && _selectedTime != null) {
      // Format date as yyyy-MM-dd with English numerals (manual formatting to ensure English)
      final date = _selectedDate!;
      final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Format time as HH:mm (24-hour format)
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      
      Navigator.pop(context, {
        'date': dateStr,
        'time': timeStr,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.isRtl;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.flight_takeoff,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isRtl ? 'تحديد موعد السفر' : 'Set Travel Date',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isRtl
                ? 'اختر تاريخ ووقت السفر'
                : 'Select travel date and time',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Date Picker
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'التاريخ' : 'Date',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate != null
                              ? _dateFormat.format(_selectedDate!)
                              : (isRtl ? 'اختر التاريخ' : 'Select date'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Time Picker
          InkWell(
            onTap: _selectTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'الوقت' : 'Time',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : (isRtl ? 'اختر الوقت' : 'Select time'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedTime != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            isRtl ? 'إلغاء' : 'Cancel',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: (_selectedDate != null && _selectedTime != null)
              ? _confirm
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            isRtl ? 'تأكيد' : 'Confirm',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

