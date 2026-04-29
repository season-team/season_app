import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_model.dart';
import 'package:season_app/features/smart_bags/presentation/screens/smart_bag_detail_screen.dart';
import 'package:season_app/features/smart_bags/providers/smart_bag_providers.dart';

class SmartBagListScreen extends ConsumerStatefulWidget {
  const SmartBagListScreen({super.key});

  @override
  ConsumerState<SmartBagListScreen> createState() => _SmartBagListScreenState();
}

class _SmartBagListScreenState extends ConsumerState<SmartBagListScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartBagListControllerProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(isRtl ? 'حقائب السفر الذكية' : 'Smart Bags'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateBagDialog(context),
            ),
          ],
        ),
        body: state.isLoading && state.bags.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.bags.isEmpty
                ? _buildEmptyState(context, isRtl)
                : RefreshIndicator(
                    onRefresh: () => ref.read(smartBagListControllerProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.bags.length,
                      itemBuilder: (context, index) {
                        return _SmartBagCard(
                          bag: state.bags[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SmartBagDetailScreen(
                                  bagId: state.bags[index].id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isRtl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isRtl ? 'لا توجد حقائب' : 'No bags yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRtl
                ? 'ابدأ بإنشاء حقيبة سفر جديدة'
                : 'Start by creating a new travel bag',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateBagDialog(context),
            icon: const Icon(Icons.add),
            label: Text(isRtl ? 'إنشاء حقيبة جديدة' : 'Create New Bag'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    // TODO: Implement filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filters'),
        content: const Text('Filter options coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateBagDialog(BuildContext context) {
    // TODO: Implement create bag dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Bag'),
        content: const Text('Create bag form coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SmartBagCard extends StatelessWidget {
  final SmartBagModel bag;
  final VoidCallback onTap;

  const _SmartBagCard({
    required this.bag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final daysUntil = bag.daysUntilDeparture;
    final isOverweight = bag.isOverweight;
    final weightPercentage = bag.weightPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(bag.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    bag.destination,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${bag.duration} ${isRtl ? 'أيام' : 'days'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'الوزن' : 'Weight',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: weightPercentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOverweight ? AppColors.error : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bag.totalWeight.toStringAsFixed(1)} / ${bag.maxWeight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOverweight ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isRtl ? 'متبقي' : 'Days Left',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        daysUntil.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (bag.isAnalyzed) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      isRtl ? 'تم التحليل' : 'Analyzed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
}

