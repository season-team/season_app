import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/core/services/country_detection_service.dart';
import 'package:season_app/features/geographical_guides/data/models/geographical_guide_models.dart';
import 'package:season_app/features/geographical_guides/providers/geographical_guides_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class GeographicalDirectoryScreen extends ConsumerStatefulWidget {
  const GeographicalDirectoryScreen({super.key});

  @override
  ConsumerState<GeographicalDirectoryScreen> createState() =>
      _GeographicalDirectoryScreenState();
}

class _GeographicalDirectoryScreenState
    extends ConsumerState<GeographicalDirectoryScreen> {
  int? _selectedCityId;
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    // Auto-detect country code on init
    CountryDetectionService.getCountryCodeFromIP().then((code) {
      if (mounted) {
        setState(() {
          _countryCode = code;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final categoriesAsync = ref.watch(geographicalCategoriesProvider);

    // Watch cities when country is selected
    final citiesAsync = _countryCode != null
        ? ref.watch(citiesByCountryProvider(_countryCode))
        : null;

    // Build filters tuple
    final filters = (
      countryCode: _countryCode,
      cityId: _selectedCityId,
      geographicalCategoryId: _selectedCategoryId,
      geographicalSubCategoryId: _selectedSubCategoryId,
    );

    final guidesAsync = ref.watch(geographicalGuidesProvider(filters));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Static App Bar with Gradient
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            foregroundColor: Colors.white,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              loc.geographicDirectory,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          
          // Filters Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isRtl ? 'الفلترة' : 'Filters',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // City Dropdown
                  if (_countryCode != null && citiesAsync != null)
                    citiesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const SizedBox.shrink(),
                      data: (cities) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<int>(
                            value: _selectedCityId,
                            decoration: InputDecoration(
                              labelText: loc.city,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              DropdownMenuItem<int>(
                                value: null,
                                child: Text(
                                  isRtl ? 'جميع المدن' : 'All Cities',
                                ),
                              ),
                              ...cities.map(
                                (c) => DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              ),
                            ],
                            onChanged: (cityId) {
                              setState(() {
                                _selectedCityId = cityId;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  if (_countryCode != null && citiesAsync != null)
                    const SizedBox(height: 16),
                  // Category Filter
                  categoriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => const SizedBox.shrink(),
                    data: (categories) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: isRtl ? 'الفئة' : 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int>(
                              value: null,
                              child: Text(
                                isRtl ? 'جميع الفئات' : 'All Categories',
                              ),
                            ),
                            ...categories
                                .where((c) => c.isActive)
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                ),
                          ],
                          onChanged: (categoryId) {
                            setState(() {
                              _selectedCategoryId = categoryId;
                              _selectedSubCategoryId = null;
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Sub-Category Filter (when category is selected)
                  if (_selectedCategoryId != null)
                    ref
                        .watch(geographicalSubCategoriesProvider(_selectedCategoryId))
                        .when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => const SizedBox.shrink(),
                          data: (subCategories) {
                            if (subCategories.isEmpty) return const SizedBox.shrink();
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<int>(
                                value: _selectedSubCategoryId,
                                decoration: InputDecoration(
                                  labelText: isRtl ? 'الفئة الفرعية' : 'Sub-Category',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<int>(
                                    value: null,
                                    child: Text(
                                      isRtl ? 'جميع الفئات الفرعية' : 'All Sub-Categories',
                                    ),
                                  ),
                                  ...subCategories
                                      .where((sc) => sc.isActive)
                                      .map(
                                        (sc) => DropdownMenuItem<int>(
                                          value: sc.id,
                                          child: Text(sc.name),
                                        ),
                                      ),
                                ],
                                onChanged: (subCategoryId) {
                                  setState(() {
                                    _selectedSubCategoryId = subCategoryId;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                  if (_selectedCategoryId != null) const SizedBox(height: 16),
                  // Clear Filters Button
                  if (_selectedCityId != null ||
                      _selectedCategoryId != null ||
                      _selectedSubCategoryId != null)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[200]!,
                            Colors.grey[100]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedCityId = null;
                            _selectedCategoryId = null;
                            _selectedSubCategoryId = null;
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                        label: Text(
                          isRtl ? 'مسح الفلاتر' : 'Clear Filters',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Guides List
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: guidesAsync.when(
              loading: () => SliverFillRemaining(
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${e.toString()}',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (guides) {
                if (guides.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isRtl ? 'لم يتم العثور على أدلة جغرافية' : 'No geographical guides found',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isRtl ? 'حاول تعديل الفلاتر' : 'Try adjusting your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final guide = guides[index];
                      return _buildGuideCard(context, guide);
                    },
                    childCount: guides.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, GeographicalGuide guide) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return GestureDetector(
      onTap: (){
         context.push(Routes.geographicalGuideDetails.replaceFirst(':id', guide.id.toString()),);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Header with Icon - Clickable to view details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business_center,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.serviceName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          guide.category.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (guide.subCategory != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  guide.subCategory!.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description
      
                  // Action Buttons Row - Icon Only
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Call Button
                      if (guide.phone1 != null)
                        _IconOnlyButton(
                          icon: Icons.phone,
                          color: AppColors.success,
                          tooltip: guide.phone1!,
                          onTap: () => _makePhoneCall(guide.phone1!, context, isRtl),
                        ),
                      // Map Button
                      if (guide.latitude != null && guide.longitude != null)
                        _IconOnlyButton(
                          icon: Icons.map,
                          color: AppColors.info,
                          tooltip: isRtl ? 'فتح في الخرائط' : 'Open in Maps',
                          onTap: () => _openMap(
                            context,
                            double.parse(guide.latitude!),
                            double.parse(guide.longitude!),
                            isRtl,
                          ),
                        ),
                      // Website Button
                      if (guide.website != null && guide.website!.isNotEmpty)
                        _IconOnlyButton(
                          icon: Icons.language,
                          color: AppColors.secondary,
                          tooltip: isRtl ? 'فتح الموقع' : 'Open Website',
                          onTap: () => _openWebsite(guide.website!, context, isRtl),
                        ),
                      // Second Phone Button
                      if (guide.phone2 != null)
                        _IconOnlyButton(
                          icon: Icons.phone,
                          color: AppColors.success,
                          tooltip: guide.phone2!,
                          onTap: () => _makePhoneCall(guide.phone2!, context, isRtl),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phone, BuildContext context, bool isRtl) async {
    try {
      final uri = Uri.parse('tel:$phone');
      final launched = await launchUrl(uri);
      
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRtl
                  ? 'لا يمكن فتح تطبيق الهاتف'
                  : 'Unable to open phone app',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRtl
                  ? 'حدث خطأ أثناء فتح الهاتف: ${e.toString()}'
                  : 'Error opening phone: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openWebsite(String url, BuildContext context, bool isRtl) async {
    try {
      // Ensure URL has proper protocol
      String formattedUrl = url.trim();
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }

      final uri = Uri.parse(formattedUrl);
      
      // Try to launch URL
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRtl
                  ? 'لا يمكن فتح الموقع الإلكتروني'
                  : 'Unable to open website',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRtl
                  ? 'حدث خطأ أثناء فتح الموقع: ${e.toString()}'
                  : 'Error opening website: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openMap(
    BuildContext context,
    double latitude,
    double longitude,
    bool isRtl,
  ) async {
    try {
      // Try Google Maps URL
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      final uri = Uri.parse(googleMapsUrl);
      
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRtl
                  ? 'لا يمكن فتح تطبيق الخرائط'
                  : 'Unable to open maps application',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRtl
                  ? 'حدث خطأ أثناء فتح الخرائط: ${e.toString()}'
                  : 'Error opening maps: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _IconOnlyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconOnlyButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

