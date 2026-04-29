import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/features/vendor/presentation/providers/vendor_providers.dart';
// import 'package:season_app/shared/widgets/custom_button.dart';

class VendorServiceDetailsScreen extends ConsumerWidget {
  final int serviceId;
  const VendorServiceDetailsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final detailsAsync = ref.watch(vendorServiceDetailsProvider(serviceId));

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.serviceDetails, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(Routes.vendorServiceEdit.replaceFirst(':id', serviceId.toString())),
            icon: const Icon(Icons.edit, color: Colors.white),
          )
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(e.toString())),
        data: (d) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.home_repair_service, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(d.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                      _StatusChip(text: d.status),
                    ]),
                    const SizedBox(height: 14),
                    _infoRow(Icons.description, loc.description, d.description),
                    const SizedBox(height: 10),
                    _infoRow(Icons.phone, loc.phone, d.contactNumber),
                    const SizedBox(height: 10),
                    _infoRow(Icons.place, loc.location, '${d.latitude}, ${d.longitude}'),
                  ]),
                ),
                const SizedBox(height: 16),
                if (d.images.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))
                    ]),
                    child: SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(d.images[i], width: 160, height: 120, fit: BoxFit.cover),
                        ),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: d.images.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // legacy helper removed

}

class _StatusChip extends StatelessWidget {
  final String text;
  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.textSecondary;
    if (text.contains('Pending') || text.contains('مراجعة') || text.contains('قيد المراجعة')) color = AppColors.secondary;
    if (text.contains('Active') || text.contains('نشط') || text.contains('تمت الموافقة') || text.contains('Approved')) color = AppColors.success;
    if (text.contains('Stopped') || text.contains('موقوف') || text.contains('متوقف') || text.contains('معطل')) color = AppColors.error;
    if (text.contains('Rejected') || text.contains('مرفوضة') || text.contains('مرفوض')) color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

Widget _infoRow(IconData icon, String title, String value) {
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 18, color: AppColors.textSecondary),
    const SizedBox(width: 8),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    ),
  ]);
}


