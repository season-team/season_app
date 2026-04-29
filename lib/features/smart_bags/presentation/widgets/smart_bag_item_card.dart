import 'package:flutter/material.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_item_model.dart';

class SmartBagItemCard extends StatelessWidget {
  final SmartBagItemModel item;
  final VoidCallback onTogglePacked;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SmartBagItemCard({
    super.key,
    required this.item,
    required this.onTogglePacked,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Checkbox(
          value: item.packed,
          onChanged: (_) => onTogglePacked(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  decoration: item.packed ? TextDecoration.lineThrough : null,
                  color: item.packed ? Colors.grey : null,
                ),
              ),
            ),
            if (item.essential)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRtl ? 'ضروري' : 'Essential',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${item.weight.toStringAsFixed(2)} kg',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '× ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.notes!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18),
                  const SizedBox(width: 8),
                  Text(isRtl ? 'تعديل' : 'Edit'),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 100),
                onEdit,
              ),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    isRtl ? 'حذف' : 'Delete',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 100),
                onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

