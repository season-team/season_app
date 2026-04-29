import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_analysis_model.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_item_model.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_model.dart';
import 'package:season_app/features/smart_bags/presentation/widgets/smart_bag_analysis_widget.dart';
import 'package:season_app/features/smart_bags/presentation/widgets/smart_bag_item_card.dart';
import 'package:season_app/features/smart_bags/presentation/widgets/smart_bag_smart_alert_widget.dart';
import 'package:season_app/features/smart_bags/providers/smart_bag_providers.dart';
import 'package:season_app/shared/widgets/custom_toast.dart';

class SmartBagDetailScreen extends ConsumerStatefulWidget {
  final int bagId;

  const SmartBagDetailScreen({
    super.key,
    required this.bagId,
  });

  @override
  ConsumerState<SmartBagDetailScreen> createState() => _SmartBagDetailScreenState();
}

class _SmartBagDetailScreenState extends ConsumerState<SmartBagDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(smartBagDetailControllerProvider.notifier).loadBagDetails(widget.bagId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartBagDetailControllerProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(state.bag?.name ?? (isRtl ? 'حقيبة السفر' : 'Travel Bag')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(smartBagDetailControllerProvider.notifier).refresh(),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => _analyzeBag(context),
            ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.bag == null
                ? Center(
                    child: Text(
                      isRtl ? 'لا توجد بيانات' : 'No data available',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(smartBagDetailControllerProvider.notifier).refresh(),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildBagHeader(state.bag!, isRtl),
                        const SizedBox(height: 16),
                        if (state.smartAlert != null) ...[
                          SmartBagSmartAlertWidget(alert: state.smartAlert!),
                          const SizedBox(height: 16),
                        ],
                        _buildWeightCard(state.bag!, isRtl),
                        const SizedBox(height: 16),
                        _buildTripInfoCard(state.bag!, isRtl),
                        const SizedBox(height: 16),
                        _buildItemsSection(state.items, isRtl),
                        const SizedBox(height: 16),
                        if (state.latestAnalysis != null) ...[
                          SmartBagAnalysisWidget(analysis: state.latestAnalysis!),
                          const SizedBox(height: 16),
                        ],
                        _buildAnalyzeButton(context, state, isRtl),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildBagHeader(SmartBagModel bag, bool isRtl) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bag.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(bag.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bag.destination,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(SmartBagModel bag, bool isRtl) {
    final isOverweight = bag.isOverweight;
    final weightPercentage = bag.weightPercentage;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRtl ? 'الوزن' : 'Weight',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${weightPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOverweight ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: weightPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverweight ? AppColors.error : AppColors.success,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'الحالي' : 'Current',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${bag.totalWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isRtl ? 'المتبقي' : 'Remaining',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${bag.remainingWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: bag.remainingWeight < 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoCard(SmartBagModel bag, bool isRtl) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.calendar_today,
              isRtl ? 'تاريخ المغادرة' : 'Departure Date',
              bag.departureDate.toString().split(' ')[0],
            ),
            const Divider(),
            _buildInfoRow(
              Icons.access_time,
              isRtl ? 'المدة' : 'Duration',
              '${bag.duration} ${isRtl ? 'أيام' : 'days'}',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.category,
              isRtl ? 'نوع الرحلة' : 'Trip Type',
              bag.tripType,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.timer,
              isRtl ? 'متبقي' : 'Days Until',
              '${bag.daysUntilDeparture} ${isRtl ? 'يوم' : 'days'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<SmartBagItemModel> items, bool isRtl) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRtl ? 'الأغراض' : 'Items',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddItemDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(isRtl ? 'إضافة' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    isRtl ? 'لا توجد أغراض' : 'No items yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SmartBagItemCard(
                      item: item,
                      onTogglePacked: () => _toggleItemPacked(item),
                      onEdit: () => _showEditItemDialog(context, item),
                      onDelete: () => _deleteItem(item),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(BuildContext context, SmartBagDetailState state, bool isRtl) {
    return ElevatedButton.icon(
      onPressed: state.isAnalyzing
          ? null
          : () => _analyzeBag(context),
      icon: state.isAnalyzing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(
        state.isAnalyzing
            ? (isRtl ? 'جاري التحليل...' : 'Analyzing...')
            : (isRtl ? 'تحليل بالذكاء الاصطناعي' : 'Analyze with AI'),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'draft':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'in_progress':
        color = AppColors.info;
        label = 'In Progress';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _analyzeBag(BuildContext context) async {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final analysis = await ref.read(smartBagDetailControllerProvider.notifier).analyzeBag(
          bagId: widget.bagId,
        );

    if (!mounted) return;

    if (analysis != null) {
      CustomToast.success(
        context,
        isRtl ? 'تم التحليل بنجاح' : 'Analysis completed successfully',
      );
    } else {
      CustomToast.error(
        context,
        isRtl ? 'فشل التحليل' : 'Analysis failed',
      );
    }
  }

  void _showAddItemDialog(BuildContext context) {
    // TODO: Implement add item dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: const Text('Add item form coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, SmartBagItemModel item) {
    // TODO: Implement edit item dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: const Text('Edit item form coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleItemPacked(SmartBagItemModel item) async {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final success = await ref.read(smartBagDetailControllerProvider.notifier).toggleItemPacked(
          bagId: widget.bagId,
          itemId: item.id,
        );

    if (!mounted) return;

    if (success) {
      CustomToast.success(
        context,
        isRtl ? 'تم التحديث' : 'Updated',
      );
    }
  }

  Future<void> _deleteItem(SmartBagItemModel item) async {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRtl ? 'حذف الغرض' : 'Delete Item'),
        content: Text(isRtl ? 'هل أنت متأكد؟' : 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(isRtl ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(smartBagDetailControllerProvider.notifier).deleteItem(
            bagId: widget.bagId,
            itemId: item.id,
          );

      if (mounted) {
        if (success) {
          CustomToast.success(
            context,
            isRtl ? 'تم الحذف' : 'Deleted',
          );
        } else {
          CustomToast.error(
            context,
            isRtl ? 'فشل الحذف' : 'Delete failed',
          );
        }
      }
    }
  }
}

