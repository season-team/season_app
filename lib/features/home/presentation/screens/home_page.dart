import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_assets.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/core/services/app_config_service.dart';
import 'package:season_app/core/services/auth_service.dart';
import 'package:season_app/shared/providers/locale_provider.dart';
import 'package:season_app/features/banners/data/models/banner_model.dart';
import 'package:season_app/features/banners/providers/banner_providers.dart';
import 'package:season_app/features/banners/utils/banner_navigation.dart';
import 'package:season_app/features/home/providers.dart';
import 'package:season_app/features/vendor/presentation/providers/vendor_providers.dart';
import 'package:season_app/features/vendor/data/vendor_models.dart';
import 'package:season_app/features/events/providers/events_providers.dart';
import 'package:season_app/features/events/data/models/event_model.dart';
import 'package:season_app/features/profile/presentation/screens/webview_screen.dart';
import 'package:season_app/features/profile/providers.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final bannerState = ref.watch(bannerControllerProvider);
    final servicesAsync = ref.watch(publicVendorServicesProvider);
    
    if (!AppConfigService.areFeaturesEnabled() || AppConfigService.hasConnectionIssue()) {
      Future.microtask(() {
        if (context.mounted) {
          context.go(Routes.connectionError);
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Load profile only when signed in; avoid scheduling loadProfile from build on
    // every frame after a failed load (profile null, isLoading false) — that caused an infinite loop.
    final profileState = ref.watch(profileControllerProvider);
    if (AuthService.isLoggedIn() &&
        profileState.profile == null &&
        !profileState.isLoading &&
        profileState.error == null) {
      Future.microtask(
        () => ref.read(profileControllerProvider.notifier).loadProfile(),
      );
    }
    
    // Check if any data is loading (initial load) - excluding events
    final bool isLoading = bannerState.isLoading || 
                          servicesAsync.isLoading ||
                          (profileState.isLoading && profileState.profile == null);
    
    // Also check if data hasn't loaded yet (empty state on initial load) - excluding events
    final bool hasNoData = bannerState.banners.isEmpty && 
                           !bannerState.isLoading &&
                           servicesAsync.hasValue == false &&
                           profileState.profile == null;
    
    final bool showShimmer = isLoading || hasNoData;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.home),
        centerTitle: true,
      ),
      body: showShimmer 
        ? _buildShimmerLoading(context)
        : SingleChildScrollView(
        child: Column(
          children: [
            // Banner Section
            if (bannerState.banners.isNotEmpty) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildBannerCarousel(context, bannerState.banners),
            ),
            
   
            // Quick Actions Icons
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              child: _buildQuickActions(context, ref),
            ),
            const SizedBox(height: 16),
                     // Smart Security Agent Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildSmartSecurityAgentBanner(context, ref),
            ),
            

            
            // Directory Buttons
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildDirectoryButtons(context, ref),
            ),

                const SizedBox(height: 12),
          
                // Loyalty Points Banner
                _buildLoyaltyPointsBanner(context, ref),
            
            const SizedBox(height: 24),
            
            // Vendor Services Section
            _buildVendorServicesSection(context, ref),

              const SizedBox(height: 24),
            
            // Events Section
            _buildEventsSection(context, ref),
            
            const SizedBox(height: 120),

          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(BuildContext context, List<BannerModel> banners) {
    return _BannerCarousel(banners: banners);
  }

  Widget _buildSmartSecurityAgentBanner(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final bannerImage = isArabic 
        ? AppAssets.smartSecurityAgentAr 
        : AppAssets.smartSecurityAgentEn;
    
    final webTitle =
        isArabic ? 'الوكيل الأمني الذكي' : 'Smart Security Agent';
    return GestureDetector(
      onTap: () {
        context.push(
          '${Routes.webview}?url=${Uri.encodeComponent('https://seasonksa.com/public/5.html/')}'
          '&title=${Uri.encodeComponent(webTitle)}',
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            bannerImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 120,
                color: AppColors.primary,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventsSection(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final eventsAsync = ref.watch(eventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            loc.events,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        const SizedBox(height: 12),
        eventsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, s) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                e.toString(),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (eventsResponse) {
            if (eventsResponse.events.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 235,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: eventsResponse.events.length > 5 ? 5 : eventsResponse.events.length,
                itemBuilder: (context, index) {
                  final event = eventsResponse.events[index];
                  return _buildEventCard(context, event);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(context, event.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      if (event.startAt != null) ...[
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeRange(event.startAt, event.endAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${event.city} - ${event.venue}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final locale = Localizations.localeOf(context);
      final format = DateFormat('dd MMM yyyy', locale.languageCode);
      return format.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTimeRange(String? startAt, String? endAt) {
    if (startAt == null) return '';
    try {
      final start = DateTime.parse(startAt);
      final startFormat = DateFormat('HH:mm');
      String result = startFormat.format(start);
      
      if (endAt != null) {
        final end = DateTime.parse(endAt);
        final endFormat = DateFormat('HH:mm');
        result += ' - ${endFormat.format(end)}';
      }
      
      return result;
    } catch (e) {
      return startAt;
    }
  }

  Widget _buildVendorServicesSection(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final servicesAsync = ref.watch(publicVendorServicesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.vendorServices,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              TextButton(
                onPressed: () => context.push(Routes.publicVendorServices),
                child: Text(
                  loc.viewAll,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        servicesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, s) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                e.toString(),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (services) {
            if (services.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: services.length > 5 ? 5 : services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _buildServiceCard(context, service);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, PublicVendorService service) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push(Routes.publicVendorServiceDetails.replaceFirst(':id', service.id.toString())),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: service.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: service.images.first,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 140,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 140,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.home_repair_service, size: 48, color: Colors.grey),
                    ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.serviceType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.address,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bag
            _QuickActionButton(
              icon: Icons.luggage,
              label: isRtl ? 'الحقيبة' : loc.bag,
              color: const Color(0xFF17A2B8), // Teal
              onTap: () {
                // Navigate to bag page (index 1 in bottom nav)
                ref.read(bottomNavIndexProvider.notifier).state = 1;
              },
            ),
            // Smart Alert
            _QuickActionButton(
              icon: Icons.notifications_active,
              label: isRtl ? 'التنبيه الذكي' : 'Smart Alert',
              color: const Color(0xFF17A2B8), // Teal
              badge: true,
              onTap: () {
                // Navigate to groups/alerts (index 1 in bottom nav)
                ref.read(bottomNavIndexProvider.notifier).state = 2;
              },
            ),
            // Emergency
            _QuickActionButton(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              label: isRtl ? 'طوارئ' : 'Emergency',
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E9B)], // Orange to Pink
              ),
              onTap: () => context.push(Routes.emergency),
            ),
            // Currency Converter
            _QuickActionButton(
              icon: Icons.currency_exchange,
              label: isRtl ? 'محول العملة' : 'Currency',
              color: const Color(0xFF7ED321), // Lime Green
              onTap: () => context.push(Routes.currencyConverter),
            ),
          ],
        ),
      
      ],
    );
  }

  Widget _buildDirectoryButtons(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    
    return Row(
      children: [
        Expanded(
          child: _DirectoryButton(
            icon: Icons.apps,
            label: loc.digitalDirectory,
            color: AppColors.primary,
            onTap: () => context.push(Routes.categories),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DirectoryButton(
            icon: Icons.map,
            label: loc.geographicDirectory,
            color: const Color(0xFF34C759),
            onTap: () => context.push(Routes.geographicalDirectory),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Banner Shimmer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            
            // Quick Actions Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                )),
              ),
            ),

            const SizedBox(height: 16),
            
            // Directory Buttons Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            
            // Loyalty Points Banner Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Vendor Services Section Shimmer
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 150,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 100,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyPointsBanner(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    // Get user points from profile, default to 0 if not loaded
    final points = profileState.profile?.coins ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4A90E2), // Lighter blue
              const Color(0xFF357ABD), // Darker blue
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90E2).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
        
              // Points Information (Right side)
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.yourLoyaltyPoints,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          points.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          loc.availablePoints,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
           
                  ],
                ),
              ),
                 // Redeem Soon Button (Left side)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8D4F0), // Light blue
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  loc.redeemSoon,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF092C4C), // Dark blue text
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DirectoryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 60,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                  Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                      maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Auto-scroll banners
    if (widget.banners.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && widget.banners.length > 1) {
        final nextPage = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // PageView for banners
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _buildBannerItem(context, banner);
            },
          ),
          
          // Page indicators
          if (widget.banners.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  VoidCallback? _getBannerTapHandler(BuildContext context, BannerModel banner) {
    // Priority: route (internal navigation) > link (external URL/webview)
    if (banner.route != null && banner.route!.isNotEmpty) {
      // Internal route navigation
      return () {
        BannerNavigation.navigate(
          route: banner.route!,
          routeParams: banner.routeParams,
          context: context,
        );
      };
    } else if (banner.link != null && banner.link!.isNotEmpty) {
      // Legacy support: external link opens in WebView
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              url: banner.link!,
              title: 'Banner',
            ),
          ),
        );
      };
    }
    return null;
  }

  Widget _buildBannerItem(BuildContext context, BannerModel banner) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _getBannerTapHandler(context, banner),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: CachedNetworkImage(
            imageUrl: banner.image,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Gradient? gradient;
  final bool badge;
  final VoidCallback onTap;

  _QuickActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.gradient,
    this.badge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: gradient != null ? null : (color ?? AppColors.primary),
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (color ?? AppColors.primary).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333), // Dark grey
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

