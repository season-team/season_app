import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/features/home/data/models/bag_detail_model.dart';
import 'package:season_app/features/home/presentation/widgets/bag/bag_delete_dialog.dart';
import 'package:season_app/features/home/presentation/widgets/bag/bag_item_card_widget.dart';
import 'package:season_app/features/home/presentation/widgets/custom_notched_bottom_bar.dart';
import 'package:season_app/features/home/providers/bag_providers.dart';
import 'package:season_app/features/home/providers.dart';
import 'package:season_app/shared/widgets/custom_toast.dart';
import 'package:season_app/core/router/routes.dart';

class BagDetailScreen extends ConsumerStatefulWidget {
  final int bagId;

  const BagDetailScreen({
    super.key,
    required this.bagId,
  });

  @override
  ConsumerState<BagDetailScreen> createState() => _BagDetailScreenState();
}

class _BagDetailScreenState extends ConsumerState<BagDetailScreen> {
  BagDetailModel? _bag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBagDetails();
  }

  Future<void> _loadBagDetails() async {
    setState(() => _isLoading = true);
    try {
      // Always fetch fresh bag details with items from API
      final bag = await ref.read(bagControllerProvider.notifier).getBagDetailById(widget.bagId);
      if (mounted) {
        setState(() {
          _bag = bag;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bag details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshBag({bool showLoading = false}) async {
    if (showLoading) {
      await _loadBagDetails();
    } else {
      // Silent refresh - update bag without showing loading indicator
      try {
        final bag = await ref.read(bagControllerProvider.notifier).getBagDetailById(widget.bagId);
        if (mounted) {
          setState(() {
            _bag = bag;
          });
        }
      } catch (e) {
        debugPrint('Error refreshing bag details: $e');
        // On error, do a full reload
        if (mounted) {
          await _loadBagDetails();
        }
      }
    }
  }

  void _showAddItemSheet() {
    if (_bag == null) return;

    // Use bagId for Smart Bags, bagTypeId for legacy
    final bagId = _bag!.tripType != null 
        ? _bag!.bagId 
        : _bag!.bagTypeId;

    // Navigate to add items screen
    context.push('/bags/$bagId/add-items').then((success) async {
      if (!mounted) return;
      if (success == true) {
        // Silent refresh - update bag without showing loading
        await _refreshBag(showLoading: false);
      }
    });
  }

  Future<void> _deleteBagItem(int itemId) async {
    if (_bag == null) return;

    final loc = AppLocalizations.of(context);
    
    // Use bagId for Smart Bags, bagTypeId for legacy
    final bagId = _bag!.tripType != null 
        ? _bag!.bagId 
        : _bag!.bagTypeId;

    final confirmed = await BagDeleteDialog.show(
      context,
      title: loc.bagDeleteItemTitle,
      message: loc.bagDeleteItemMessage,
      confirmText: loc.bagDeleteConfirm,
      cancelText: loc.bagDeleteCancel,
    );

    if (!mounted || confirmed != true) return;

    try {
      final success = await ref.read(bagControllerProvider.notifier).deleteItemFromBag(
            itemId: itemId,
            bagTypeId: bagId,
          );
      if (!mounted) return;
      if (success) {
        CustomToast.success(context, loc.bagDeleteItemSuccess);
        // Silent refresh - update bag without showing loading
        await _refreshBag(showLoading: false);
      } else {
        CustomToast.error(context, loc.bagDeleteItemError);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomToast.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, loc.bagDeleteItemError);
    }
  }

  Future<void> _deleteBag() async {
    if (_bag == null) return;
    
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final loc = AppLocalizations.of(context);

    final confirmed = await BagDeleteDialog.show(
      context,
      title: isRtl ? 'حذف الحقيبة' : 'Delete Bag',
      message: isRtl
          ? 'هل أنت متأكد من حذف هذه الحقيبة؟ سيتم حذف جميع الأغراض الموجودة فيها.'
          : 'Are you sure you want to delete this bag? All items will be removed.',
      confirmText: loc.bagDeleteConfirm,
      cancelText: loc.bagDeleteCancel,
    );

    if (!mounted || confirmed != true) return;

    try {
      // Use Smart Bags API delete if bag has trip info (Smart Bag), otherwise delete items
      if (_bag!.tripType != null) {
        // Smart Bag - use delete endpoint
        final success = await ref.read(bagControllerProvider.notifier).deleteBag(_bag!.bagId);
        if (!mounted) return;
        
        if (success) {
          CustomToast.success(
            context,
            isRtl ? 'تم حذف الحقيبة بنجاح' : 'Bag deleted successfully',
          );
          // Navigate back to bag list
          if (mounted) {
            context.pop();
          }
        } else {
          CustomToast.error(
            context,
            isRtl ? 'فشل حذف الحقيبة' : 'Failed to delete bag',
          );
        }
      } else {
        // Legacy bag - delete all items
        for (final item in _bag!.items) {
          if (item.itemId != null) {
            await ref.read(bagControllerProvider.notifier).deleteItemFromBag(
                  itemId: item.itemId!,
                  bagTypeId: _bag!.bagTypeId,
                );
          }
        }
        CustomToast.success(
          context,
          isRtl ? 'تم حذف الحقيبة بنجاح' : 'Bag deleted successfully',
        );
        // Navigate back to bag list
        if (mounted) {
          context.pop();
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomToast.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(
        context,
        isRtl ? 'فشل حذف الحقيبة' : 'Failed to delete bag',
      );
    }
  }

  void _navigateToEditBag() async {
    if (_bag == null) return;
    
    final result = await context.push(
      Routes.editBag.replaceAll(':id', _bag!.bagId.toString()),
      extra: _bag,
    );
    
    // Refresh bag if edit was successful
    if (result == true && mounted) {
      await _refreshBag(showLoading: false);
    }
  }

  Future<void> _analyzeBag({bool forceReanalysis = false}) async {
    if (_bag == null) return;
    
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    if (_bag!.items.isEmpty) {
      CustomToast.error(
        context,
        isRtl ? 'الحقيبة فارغة. أضف أغراضاً أولاً' : 'Bag is empty. Add items first',
      );
      return;
    }
    
    // Navigate immediately to analysis screen - it will handle the analysis and loading
    final route = Routes.bagAnalysis.replaceAll(':id', _bag!.bagId.toString());
    context.push(route, extra: {'forceReanalysis': forceReanalysis});
  }


  @override
  Widget build(BuildContext context) {
    // Watch provider for reactivity
    ref.watch(bagControllerProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (_isLoading || _bag == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
        child: Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            extendBody: true,
            backgroundColor: AppColors.backgroundLight,
            body: RefreshIndicator(
            onRefresh: () => _refreshBag(showLoading: true),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar with back button
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  title: Text(isRtl ? 'الحقيبة' : 'Bag'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                              ),
                
                // Compact Header Card (like in image)
                SliverToBoxAdapter(
                  child: _buildCompactHeader(_bag!, isRtl),
                ),
                
                // Smart Assistant Card (Analyze Button)
                if (_bag!.tripType != null && _bag!.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: _buildSmartAssistantCard(isRtl),
                    ),
                  ),
                
                // Items Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _buildSectionHeader(
                      icon: Icons.inventory_2_rounded,
                      title: isRtl ? 'الأغراض' : 'Items',
                      count: _bag!.items.length,
                      onAction: _showAddItemSheet,
                      actionLabel: isRtl ? 'إضافة' : 'Add',
                      isRtl: isRtl,
                    ),
                  ),
                ),
                
                // Items List
                if (_bag!.items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildEmptyItemsState(isRtl),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _bag!.items.reversed.toList()[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _bag!.items.length - 1 ? 0 : 4,
                            ),
                            child: BagItemCardWidget(
                              item: item,
                              bagId: _bag!.bagId,
                              onDelete: () => _deleteBagItem(item.itemId ?? 0),
                              onUpdate: () => _refreshBag(showLoading: false),
                            ),
                          );
                        },
                        childCount: _bag!.items.length,
                      ),
                    ),
                  ),
                
                // Bottom Spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Compact Header Card (matching the image design)
  Widget _buildCompactHeader(BagDetailModel bag, bool isRtl) {
    final weightColor = _getWeightColor(bag.weightPercentage);
    final tripTypeColor = _getTripTypeColor(bag.tripType);
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: weightColor.withOpacity(0.15),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToEditBag,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Bag Name and Actions
                Row(
                  children: [
                    // Bag Icon with gradient
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tripTypeColor,
                            tripTypeColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: tripTypeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getTripTypeIcon(bag.tripType),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bag Name and Trip Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bag.bagName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (bag.tripType != null || bag.destination != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (bag.tripType != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: tripTypeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: tripTypeColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      bag.tripType!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: tripTypeColor,
                                      ),
                                    ),
                                  ),
                                  if (bag.destination != null) const SizedBox(width: 8),
                                ],
                                if (bag.destination != null) ...[
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      bag.destination!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Action Buttons
                    Row(
                      children: [
                        _buildHeaderActionButton(
                          icon: Icons.edit_outlined,
                          onTap: _navigateToEditBag,
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderActionButton(
                          icon: Icons.delete_outline_rounded,
                          onTap: _deleteBag,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Weight Section with Modern Design
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        weightColor.withOpacity(0.08),
                        weightColor.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: weightColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weight Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: weightColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.scale_rounded,
                                  color: weightColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isRtl ? 'الوزن' : 'Weight',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Percentage Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: weightColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: weightColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: weightColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${bag.weightPercentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: weightColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Weight Display
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            bag.currentWeight.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: weightColor,
                              height: 1,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              isRtl ? 'كجم' : 'kg',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: weightColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: weightColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${isRtl ? "من" : "of"} ${bag.maxWeight.toStringAsFixed(0)} ${isRtl ? "كجم" : "kg"}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Progress Bar with Modern Style
                      Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.border.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (bag.weightPercentage / 100).clamp(0.0, 1.0),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    weightColor,
                                    weightColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: weightColor.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Weight Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWeightStat(
                            icon: Icons.check_circle_outline_rounded,
                            label: isRtl ? 'مستخدم' : 'Used',
                            value: '${bag.currentWeight.toStringAsFixed(1)} ${isRtl ? "كجم" : "kg"}',
                            color: weightColor,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppColors.border.withOpacity(0.5),
                          ),
                          _buildWeightStat(
                            icon: Icons.add_circle_outline_rounded,
                            label: isRtl ? 'متاح' : 'Available',
                            value: '${(bag.maxWeight - bag.currentWeight).clamp(0.0, bag.maxWeight).toStringAsFixed(1)} ${isRtl ? "كجم" : "kg"}',
                            color: AppColors.success,
                          ),
                        ],
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

  Widget _buildWeightStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTripTypeColor(String? tripType) {
    if (tripType == null) return AppColors.primary;
    switch (tripType) {
      case 'سياحة':
        return const Color(0xFF6366F1);
      case 'عمل':
        return const Color(0xFF3B82F6);
      case 'علاج':
        return const Color(0xFFEF4444);
      case 'عائلية':
        return const Color(0xFFEC4899);
      case 'الجيم':
        return const Color(0xFF10B981);
      case 'أخرى':
        return const Color(0xFF6B7280);
      default:
        return AppColors.primary;
    }
  }

  IconData _getTripTypeIcon(String? tripType) {
    if (tripType == null) return Icons.luggage_rounded;
    switch (tripType) {
      case 'سياحة':
        return Icons.flight_rounded;
      case 'عمل':
        return Icons.business_rounded;
      case 'علاج':
        return Icons.medical_services_rounded;
      case 'عائلية':
        return Icons.family_restroom_rounded;
      case 'الجيم':
        return Icons.fitness_center_rounded;
      case 'أخرى':
        return Icons.more_horiz_rounded;
      default:
        return Icons.luggage_rounded;
    }
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive 
                ? AppColors.error.withOpacity(0.08)
                : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDestructive ? AppColors.error : AppColors.primary,
          ),
        ),
      ),
    );
  }

  // Smart Assistant Card (like in the image)
  Widget _buildSmartAssistantCard(bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6), // Purple
            Color(0xFF6366F1), // Indigo
            Color(0xFF06B6D4), // Cyan
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
        SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'المساعد الذكي جاهز' : 'Smart Assistant Ready',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRtl 
                        ? 'دعني أحلل حقيبتك وأقدم لك اقتراحات مخصصة لرحلتك'
                        : 'Let me analyze your bag and give you personalized suggestions',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Action button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _analyzeBag,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: Color(0xFF8B5CF6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRtl ? 'راجع حقيبتي' : 'Review My Bag',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Brain icon
    
          ],
        ),
      ),
    );
  }

  // Section Header with action button
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onAction,
    required String actionLabel,
    required bool isRtl,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? isRtl ? 'عنصر' : 'item' : isRtl ? 'عناصر' : 'items'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Empty Items State
  Widget _buildEmptyItemsState(bool isRtl) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isRtl ? 'لا توجد أغراض بعد' : 'No items yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRtl
                ? 'ابدأ بإضافة أغراضك للحقيبة'
                : 'Start adding items to your bag',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showAddItemSheet,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isRtl ? 'إضافة غرض' : 'Add Item',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getWeightColor(double percentage) {
    if (percentage > 100) return AppColors.error;
    if (percentage > 80) return AppColors.warning;
    return AppColors.success;
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavBar(bool isRtl) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    
    final List<BottomNavItem> navItems = [
      BottomNavItem(
        icon: Icons.luggage,
        label: isRtl ? 'الحقيبة' : 'Bag',
      ),
      BottomNavItem(
        icon: Icons.notifications_outlined,
        label: isRtl ? 'التذكيرات' : 'Reminders',
      ),
      BottomNavItem(
        icon: Icons.explore_outlined,
        label: isRtl ? 'عدم الضياع' : 'No Loss',
      ),
      BottomNavItem(
        icon: Icons.person_outline_rounded,
        label: isRtl ? 'حسابي' : 'Profile',
      ),
    ];

    return CustomNotchedBottomBar(
      currentIndex: currentIndex == 0 ? -1 : currentIndex - 1,
      onTap: (index) {
        // Map navigation bar index to page index
        ref.read(bottomNavIndexProvider.notifier).state = index + 1;
        // Navigate to main screen
        context.go(Routes.home);
      },
      onFabTap: () {
        // FAB opens home page (index 0)
        ref.read(bottomNavIndexProvider.notifier).state = 0;
        context.go(Routes.home);
      },
      items: isRtl ? navItems.reversed.toList() : navItems,
      isRtl: isRtl,
    );
  }
}
