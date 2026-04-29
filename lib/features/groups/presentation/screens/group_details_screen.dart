import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/services/auth_service.dart';
import 'package:season_app/core/services/location_service.dart';
import 'package:season_app/core/services/background_location_service.dart';
import 'package:season_app/core/services/qr_share_service.dart';
import 'package:season_app/features/groups/data/models/group_model.dart';
import 'package:season_app/features/groups/providers.dart';
import 'package:season_app/shared/helpers/snackbar_helper.dart';
import 'package:season_app/shared/widgets/remove_user_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:season_app/features/groups/data/models/group_member_model.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final int groupId;
  
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> with WidgetsBindingObserver {
  Timer? _groupDetailsRefreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 5); // Auto-refresh every 5 seconds

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(groupsControllerProvider.notifier).loadGroupDetails(widget.groupId);
      _startLocationTracking();
      _startAutoRefresh();
      // Note: Safety radius monitoring is now continuous and runs globally
      // No need to start/stop it per screen
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause auto-refresh when app goes to background
      _stopAutoRefresh();
    } else if (state == AppLifecycleState.resumed) {
      // Resume auto-refresh when app comes to foreground
      _startAutoRefresh();
      // Also refresh immediately when resuming
      _refreshGroupDetails();
    }
  }

  /// Start automatic refresh timer
  void _startAutoRefresh() {
    _groupDetailsRefreshTimer?.cancel();
    _groupDetailsRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _refreshGroupDetails();
      } else {
        timer.cancel();
      }
    });
    debugPrint('🔄 Auto-refresh started: every ${_refreshInterval.inSeconds} seconds');
  }

  /// Stop automatic refresh timer
  void _stopAutoRefresh() {
    _groupDetailsRefreshTimer?.cancel();
    _groupDetailsRefreshTimer = null;
    debugPrint('⏸️ Auto-refresh stopped');
  }

  void _startLocationTracking() async {
    final hasPermission = await LocationService.requestPermissions();
    if (!hasPermission) return;

    // Refresh group IDs - location tracking is handled globally by startBackgroundLocationTracking()
    // It sends location updates to ALL groups regardless of which screen is open
    await refreshGroupIds();
    
    // Note: Location updates are handled globally by startBackgroundLocationTracking()
    // No need for screen-specific location tracking
  }

  // Note: Safety radius monitoring is now handled globally by SafetyRadiusAlarmService
  // It runs continuously every 10 seconds for all groups where user is admin
  // No need for screen-specific monitoring

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefresh();
    // Note: Location tracking and safety radius monitoring run globally
    // They continue even when leaving this screen and work on all screens
    super.dispose();
  }

  Future<void> _refreshGroupDetails() async {
    await ref.read(groupsControllerProvider.notifier).loadGroupDetails(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsControllerProvider);
    final group = groupsState.selectedGroup;
    final members = groupsState.members;
    final sosAlerts = groupsState.sosAlerts;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    ref.listen(groupsControllerProvider, (previous, next) {
      if (next.error != null) {
        SnackbarHelper.error(context, next.error!);
        ref.read(groupsControllerProvider.notifier).clearError();
      }
      if (next.message != null) {
        SnackbarHelper.success(context, next.message!);
        ref.read(groupsControllerProvider.notifier).clearMessage();
      }
    });

    if (groupsState.isLoading && group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (group == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isRtl ? 'خطأ' : 'Error'),
        ),
        body: Center(
          child: Text(isRtl ? 'المجموعة غير موجودة' : 'Group not found'),
        ),
      );
    }

    final currentUserId = AuthService.getUserId();
    final isOwner = currentUserId != null && currentUserId == group.ownerId.toString();

    // Note: Safety radius monitoring is now handled globally by SafetyRadiusAlarmService
    // It continuously monitors all groups where user is admin, regardless of current screen

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshGroupDetails,
        child: CustomScrollView(
          slivers: [
          // Custom App Bar - Redesigned
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
    
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  onPressed: () => _showInviteSheet(group),
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  if (isOwner) ...[
                    PopupMenuItem(
                      onTap: () => Future.delayed(Duration.zero, _editGroup),
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(isRtl ? 'تعديل' : 'Edit', style: const TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => Future.delayed(Duration.zero, _deleteGroup),
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text(isRtl ? 'حذف' : 'Delete', style: const TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  ] else
                    PopupMenuItem(
                      onTap: () => Future.delayed(Duration.zero, _leaveGroup),
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text(isRtl ? 'مغادرة' : 'Leave', style: const TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.9),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Title and subtitle
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  Text(
                                    group.description?.isNotEmpty == true 
                                        ? group.description! 
                                        : (isRtl ? 'مجموعة آمنة' : 'Safe Group'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.92),
                                      fontFamily: 'Cairo',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Stats as small chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatChip(
                              icon: Icons.people_rounded,
                              value: '${members.length}',
                              label: isRtl ? 'أعضاء' : 'Members',
                              color: Colors.white.withOpacity(0.2),
                            ),
                            _buildStatChip(
                              icon: Icons.gps_fixed_rounded,
                              value: '${group.safetyRadius}${isRtl ? "م" : "m"}',
                              label: isRtl ? 'نطاق' : 'Radius',
                              color: Colors.white.withOpacity(0.2),
                            ),
                            _buildStatChip(
                              icon: Icons.location_off_rounded,
                              value: '${group.outOfRangeCount}',
                              label: isRtl ? 'خارج النطاق' : 'Out of Range',
                              color: group.outOfRangeCount > 0 
                                  ? AppColors.error.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // SOS Button and Active Emergency in header
                        Row(
                          children: [
                            // SOS Button - Compact design
                            Container(
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.error,
                                    AppColors.error.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _sendSOS,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          isRtl ? 'SOS' : 'SOS',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Active Emergency (if exists) - Compact badge
                            if (sosAlerts.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push('/groups/${widget.groupId}/sos'),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isRtl ? 'طوارئ' : 'Emergency',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.error,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${sosAlerts.length}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // SOS Alerts Section - Compact Design
          if (sosAlerts.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Compact Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emergency,
                              color: AppColors.error,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRtl ? 'تنبيهات الطوارئ' : 'Emergency Alerts',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sosAlerts.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Compact Alerts List
                    ...sosAlerts.map((alert) => Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.error.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/groups/${widget.groupId}/sos'),
                          borderRadius: BorderRadius.circular(0),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Status indicator
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // User avatar
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.error.withOpacity(0.1),
                                  backgroundImage: alert.user.avatar != null 
                                      ? NetworkImage(alert.user.avatar!)
                                      : null,
                                  child: alert.user.avatar == null
                                      ? Text(
                                          alert.user.name.isNotEmpty 
                                              ? alert.user.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                // Alert content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.user.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        alert.message,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'Cairo',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Time and arrow
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatDateTime(alert.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey.shade400,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),

          // Members Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Text(
                    isRtl ? 'الأعضاء' : 'Members',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Spacer(),
                  if (isOwner)
                    TextButton.icon(
                      onPressed: () => _showInviteSheet(group),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: Text(
                        isRtl ? 'إضافة عضو' : 'Add Member',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Members List - Modern Clean Design
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = members[index];
                  final isOwnerMember = member.role == 'owner';
                  final isWithinRadius = member.isWithinRadius;
                  final canRemove = isOwner && !isOwnerMember;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                             Colors.grey.shade200,
                          
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToMemberMap(member, isRtl),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: _buildMemberAvatar(member, isWithinRadius, isOwnerMember),
                      title: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  member.user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                if (currentUserId != null && member.user.id.toString() == currentUserId)...[
                                  SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      '(${isRtl ? 'أنت' : 'You'})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          if (isOwnerMember)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isRtl ? 'مالك' : 'Owner',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Last seen status
                          Text(
                           member.isOnline ? (isRtl ? 'متصل الآن' : 'Online now') : member.lastSeen.isNotEmpty ? member.lastSeen : (isRtl ? 'غير متصل' : 'Offline'),
                            style: TextStyle(
                              fontSize: 12,
                              color: member.isOnline ? AppColors.success : Colors.grey.shade600,
                              fontFamily: 'Cairo',
                              fontWeight: member.isOnline ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Range status
                          Row(
                            children: [
                              Icon(
                                isWithinRadius ? Icons.check_circle : Icons.warning,
                                size: 14,
                                color: isWithinRadius ? AppColors.success : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isWithinRadius ? (isRtl ? 'في النطاق' : 'In Range') : (isRtl ? 'خارج النطاق' : 'Out of Range'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isWithinRadius ? AppColors.success : AppColors.error,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              // if (member.latestLocation != null) ...[
                              //   const SizedBox(width: 8),
                              //   Text(
                              //     '${member.latestLocation!.distanceFromCenter.toStringAsFixed(0)}${isRtl ? "م" : "m"}',
                              //     style: TextStyle(
                              //       fontSize: 11,
                              //       color: Colors.grey.shade600,
                              //       fontFamily: 'Cairo',
                              //     ),
                              //   ),
                              // ],
                       
                            ],
                          ),
                        ],
                      ),
                      trailing: canRemove
                          ? IconButton(
                              onPressed: () => _confirmRemoveMember(member, isRtl),
                              icon: Icon(
                                Icons.exit_to_app,
                                color: AppColors.error,
                                size: 20,
                              ),
                              tooltip: isRtl ? 'إزالة العضو' : 'Remove Member',
                            )
                          : null,
                        ),
                      ),
                    ),
                  );
                },
                childCount: members.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
        ),
      ),
    );
  }


  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOS() async {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    final position = await LocationService.getCurrentLocation();
    
    if (position == null) {
      if (mounted) {
        SnackbarHelper.error(
          context,
          isRtl ? 'فشل الحصول على الموقع' : 'Failed to get location',
        );
      }
      return;
    }
    
    await ref.read(groupsControllerProvider.notifier).sendSOS(
      groupId: widget.groupId,
      latitude: position.latitude,
      longitude: position.longitude,
      message: isRtl ? 'أحتاج المساعدة!' : 'I need help!',
    );
  }

  void _editGroup() {
    context.push('/groups/${widget.groupId}/edit');
  }

  Future<void> _leaveGroup() async {
    final success = await ref.read(groupsControllerProvider.notifier).leaveGroup(widget.groupId);
    if (success && mounted) {
      context.pop();
    }
  }

  Future<void> _deleteGroup() async {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Text(
              isRtl ? 'حذف المجموعة' : 'Delete Group',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isRtl 
              ? 'هل تريد حذف المجموعة؟ لا يمكن التراجع.'
              : 'Delete this group? This cannot be undone.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              isRtl ? 'إلغاء' : 'Cancel',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isRtl ? 'حذف' : 'Delete',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await ref.read(groupsControllerProvider.notifier).deleteGroup(widget.groupId);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  void _shareQRCode(GroupModel group) async {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    try {
      await QrShareService.shareGroupQR(
        inviteCode: group.inviteCode,
        groupName: group.name,
        isRtl: isRtl,
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.error(
          context,
          isRtl ? 'فشل المشاركة' : 'Failed to share',
        );
      }
    }
  }

  void _confirmRemoveMember(member, bool isRtl) {
    RemoveUserDialog.show(
      context: context,
      user: UserInfo(
        id: member.user.id,
        name: member.user.name,
        avatar: member.user.avatar,
        role: member.role,
        isOnline: member.isOnline,
      ),
      isRtl: isRtl,
      title: isRtl ? 'إزالة عضو من المجموعة' : 'Remove Member from Group',
      warningMessage: isRtl 
          ? 'سيتم إزالة العضو نهائياً من المجموعة'
          : 'Member will be permanently removed from the group',
      onConfirm: () => _removeMember(member.user.id),
    );
  }

  Future<void> _removeMember(int userId) async {
    final success = await ref.read(groupsControllerProvider.notifier).removeMember(
      groupId: widget.groupId,
      userId: userId,
    );

    if (success) {
      ref.read(groupsControllerProvider.notifier).loadGroupDetails(widget.groupId);
    }
  }

  void _navigateToMemberMap(member, bool isRtl) async {
    if (member.latestLocation == null) {
      SnackbarHelper.error(
        context,
        isRtl 
            ? 'لا يوجد موقع متاح لهذا العضو' 
            : 'No location available for this member',
      );
      return;
    }

    final latitude = member.latestLocation!.latitude;
    final longitude = member.latestLocation!.longitude;

    // Create URLs for different map apps
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
    final appleMapsUrl = 'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d';
    
    // Try to open Google Maps first, then Apple Maps as fallback
    try {
      final Uri googleMapsUri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Apple Maps
        final Uri appleMapsUri = Uri.parse(appleMapsUrl);
        if (await canLaunchUrl(appleMapsUri)) {
          await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
        } else {
          // If no map app is available, show error
          SnackbarHelper.error(
            context,
            isRtl 
                ? 'لا يوجد تطبيق خرائط متاح على الجهاز' 
                : 'No maps app available on device',
          );
        }
      }
    } catch (e) {
      SnackbarHelper.error(
        context,
        isRtl 
            ? 'حدث خطأ أثناء فتح الخرائط' 
            : 'Error opening maps: ${e.toString()}',
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return isRtl ? 'الآن' : 'Just now';
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return isRtl ? 'منذ $m دقيقة' : '$m minute${m == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return isRtl ? 'منذ $h ساعة' : '$h hour${h == 1 ? '' : 's'} ago';
    } else {
      final d = difference.inDays;
      return isRtl ? 'منذ $d يوم' : '$d day${d == 1 ? '' : 's'} ago';
    }
  }

  void _showInviteSheet(GroupModel group) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _GroupInviteSheet(
          group: group,
          isRtl: isRtl,
          onShare: () => _shareQRCode(group),
        );
      },
    );
  }

  Widget _buildMemberAvatar(GroupMemberModel member, bool isWithinRadius, bool isOwnerMember) {
    final baseColor = isWithinRadius ? AppColors.success : AppColors.error;
    final hasAvatar = member.user.avatar != null && member.user.avatar!.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: baseColor.withOpacity(0.15),
          backgroundImage: hasAvatar ? NetworkImage(member.user.avatar!) : null,
          child: !hasAvatar
              ? Text(
                  member.user.name.isNotEmpty ? member.user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: baseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: member.isOnline ? AppColors.success : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        if (isOwnerMember)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }
}

class _GroupInviteSheet extends StatelessWidget {
  final GroupModel group;
  final bool isRtl;
  final VoidCallback onShare;

  const _GroupInviteSheet({
    required this.group,
    required this.isRtl,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isRtl ? 'دعوة الأعضاء' : 'Invite Members',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRtl
                            ? 'شارك رمز الدعوة أو امسح رمز QR للانضمام إلى المجموعة.'
                            : 'Share the invite code or scan the QR code to join the group.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: group.inviteCode,
                              version: QrVersions.auto,
                              size: 140,
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              group.inviteCode,
                              style: const TextStyle(
                                fontSize: 20,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isRtl ? 'كود الدعوة' : 'Invite Code',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _copyInviteCode(context),
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: Text(
                                      isRtl ? 'نسخ الكود' : 'Copy Code',
                                      style: const TextStyle(fontFamily: 'Cairo'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: onShare,
                                    icon: const Icon(Icons.share, size: 16),
                                    label: Text(
                                      isRtl ? 'مشاركة' : 'Share',
                                      style: const TextStyle(fontFamily: 'Cairo'),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
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
            ],
          ),
        );
      },
    );
  }

  void _copyInviteCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: group.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRtl ? 'تم نسخ الكود' : 'Invite code copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

