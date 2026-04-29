import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/emergency/providers/emergency_providers.dart';
import 'package:season_app/features/emergency/data/models/emergency_model.dart';
import 'package:season_app/shared/providers/locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  String _getLocalizedString(String key, {bool isArabic = false}) {
    final fallbacksEn = {
      'emergencyNumbers': 'Emergency Numbers',
      'emergencySubtitle': 'Quick access to emergency services',
      'emergencyFire': 'Fire Department',
      'emergencyPolice': 'Police',
      'emergencyAmbulance': 'Ambulance',
      'emergencyEmbassy': 'Embassy',
      'emergencyError': 'Failed to load emergency numbers',
      'emergencyErrorDescription': 'Please check your internet connection and try again',
    };
    final fallbacksAr = {
      'emergencyNumbers': 'أرقام الطوارئ',
      'emergencySubtitle': 'وصول سريع لخدمات الطوارئ',
      'emergencyFire': 'الإطفاء',
      'emergencyPolice': 'الشرطة',
      'emergencyAmbulance': 'الإسعاف',
      'emergencyEmbassy': 'السفارة',
      'emergencyError': 'فشل تحميل أرقام الطوارئ',
      'emergencyErrorDescription': 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
    };
    return isArabic ? (fallbacksAr[key] ?? key) : (fallbacksEn[key] ?? key);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyState = ref.watch(emergencyControllerProvider);
    final loc = AppLocalizations.of(context);
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
           
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.emergency,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getLocalizedString('emergencyNumbers', isArabic: isArabic),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getLocalizedString('emergencySubtitle', isArabic: isArabic),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: emergencyState.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : emergencyState.error != null
                      ? _buildErrorState(context, ref, loc)
                      : emergencyState.emergencyNumbers != null
                          ? _buildEmergencyNumbers(
                              context,
                              emergencyState.emergencyNumbers!,
                              loc,
                              isArabic: isArabic,
                            )
                          : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
  ) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _getLocalizedString('emergencyError', isArabic: isArabic),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getLocalizedString('emergencyErrorDescription', isArabic: isArabic),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(emergencyControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(loc.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumbers(
    BuildContext context,
    EmergencyModel emergencyNumbers,
    AppLocalizations loc, {
    bool isArabic = false,
  }) {
    return Column(
      children: [
        _buildEmergencyCard(
          context: context,
          icon: Icons.fire_extinguisher,
          title: _getLocalizedString('emergencyFire', isArabic: isArabic),
          number: emergencyNumbers.fire,
          color: Colors.orange,
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
        ),
        const SizedBox(height: 16),
        _buildEmergencyCard(
          context: context,
          icon: Icons.local_police,
          title: _getLocalizedString('emergencyPolice', isArabic: isArabic),
          number: emergencyNumbers.police,
          color: Colors.blue,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
        ),
        const SizedBox(height: 16),
        _buildEmergencyCard(
          context: context,
          icon: Icons.medical_services,
          title: _getLocalizedString('emergencyAmbulance', isArabic: isArabic),
          number: emergencyNumbers.ambulance,
          color: Colors.red,
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
          ),
        ),
        const SizedBox(height: 16),
        _buildEmergencyCard(
          context: context,
          icon: Icons.business,
          title: _getLocalizedString('emergencyEmbassy', isArabic: isArabic),
          number: emergencyNumbers.embassy,
          color: AppColors.primary,
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String number,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makeCall(number),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Copy to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: phoneNumber));
    }
  }
}
