import 'package:flutter/material.dart';
import 'package:season_app/core/constants/app_colors.dart';

class SmartBagSmartAlertWidget extends StatelessWidget {
  final Map<String, dynamic> alert;

  const SmartBagSmartAlertWidget({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final severity = alert['severity'] as String? ?? 'medium';
    final message = alert['message'] as String? ?? '';
    final timeRemaining = alert['time_remaining'] as String? ?? '';
    final issues = alert['issues'] as List<dynamic>? ?? [];

    Color alertColor;
    IconData alertIcon;

    switch (severity.toLowerCase()) {
      case 'high':
        alertColor = AppColors.error;
        alertIcon = Icons.warning;
        break;
      case 'medium':
        alertColor = AppColors.warning;
        alertIcon = Icons.info_outline;
        break;
      default:
        alertColor = AppColors.info;
        alertIcon = Icons.notifications_outlined;
    }

    return Card(
      elevation: 2,
      color: alertColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: alertColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(alertIcon, color: alertColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRtl ? 'تنبيه ذكي' : 'Smart Alert',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: alertColor,
                    ),
                  ),
                ),
                if (timeRemaining.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: alertColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      timeRemaining,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: alertColor,
                      ),
                    ),
                  ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...issues.map((issue) {
                final issueMap = issue as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: alertColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (issueMap['category'] != null)
                        Text(
                          issueMap['category'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: alertColor,
                          ),
                        ),
                      if (issueMap['message'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          issueMap['message'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      if (issueMap['action'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          issueMap['action'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

