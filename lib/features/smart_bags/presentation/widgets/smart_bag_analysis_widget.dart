import 'package:flutter/material.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_analysis_model.dart';

class SmartBagAnalysisWidget extends StatelessWidget {
  final SmartBagAnalysisModel analysis;

  const SmartBagAnalysisWidget({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
                const Icon(Icons.auto_awesome, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  isRtl ? 'تحليل الذكاء الاصطناعي' : 'AI Analysis',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (analysis.missingItems.isNotEmpty) ...[
              _buildSectionTitle(
                isRtl ? 'أغراض ناقصة' : 'Missing Items',
                Icons.add_circle_outline,
                AppColors.warning,
              ),
              const SizedBox(height: 8),
              ...analysis.missingItems.map((item) => _buildMissingItem(item, isRtl)),
              const SizedBox(height: 16),
            ],
            if (analysis.extraItems.isNotEmpty) ...[
              _buildSectionTitle(
                isRtl ? 'أغراض زائدة' : 'Extra Items',
                Icons.remove_circle_outline,
                AppColors.info,
              ),
              const SizedBox(height: 8),
              ...analysis.extraItems.map((item) => _buildExtraItem(item, isRtl)),
              const SizedBox(height: 16),
            ],
            if (analysis.weightOptimization != null) ...[
              _buildSectionTitle(
                isRtl ? 'تحسين الوزن' : 'Weight Optimization',
                Icons.trending_down,
                AppColors.success,
              ),
              const SizedBox(height: 8),
              _buildWeightOptimization(analysis.weightOptimization!, isRtl),
              const SizedBox(height: 16),
            ],
            if (analysis.additionalSuggestions.isNotEmpty) ...[
              _buildSectionTitle(
                isRtl ? 'اقتراحات إضافية' : 'Additional Suggestions',
                Icons.lightbulb_outline,
                AppColors.secondary,
              ),
              const SizedBox(height: 8),
              ...analysis.additionalSuggestions.map(
                (suggestion) => _buildSuggestion(suggestion, isRtl),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRtl ? 'درجة الثقة' : 'Confidence',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${(analysis.confidenceScore * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMissingItem(MissingItem item, bool isRtl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(item.priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(item.priority),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.reason,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.weight.toStringAsFixed(2)} kg • ${item.category}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraItem(ExtraItem item, bool isRtl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '-${item.weightSaved.toStringAsFixed(2)} kg',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.reason,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightOptimization(WeightOptimization optimization, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRtl ? 'الوزن الحالي' : 'Current Weight',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                '${optimization.currentWeight.toStringAsFixed(2)} kg',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRtl ? 'الوزن المقترح' : 'Suggested Weight',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                '${optimization.suggestedWeight.toStringAsFixed(2)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRtl ? 'توفير الوزن' : 'Weight Saved',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${optimization.weightSaved.toStringAsFixed(2)} kg (${optimization.percentageSaved.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(Map<String, dynamic> suggestion, bool isRtl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        suggestion['message']?.toString() ?? suggestion.toString(),
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }
}

