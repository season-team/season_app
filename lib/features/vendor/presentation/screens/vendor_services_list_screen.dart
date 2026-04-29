import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/features/vendor/presentation/providers/vendor_providers.dart';
import 'package:season_app/shared/widgets/custom_button.dart';

class VendorServicesListScreen extends ConsumerWidget {
  const VendorServicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final servicesAsync = ref.watch(vendorServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.yourServices,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: servicesAsync.maybeWhen(
        data: (items) => items.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => context.push(Routes.vendorServiceNew),
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                label: Text(loc.createService),
                icon: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(vendorServicesProvider.notifier).refresh(),
        child: servicesAsync.when(
          loading: () => const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, s) => SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 400,
              child: Center(child: Text(e.toString())),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(loc.noServicesYet, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * (2 / 3),
                          child: CustomButton(text: loc.createService, onPressed: () => context.push(Routes.vendorServiceNew)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => context.push(Routes.vendorServiceDetails.replaceFirst(':id', item.id.toString())),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.home_repair_service, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            _StatusChip(text: item.status),
                          ]),
                        ),
                        PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          context.push(Routes.vendorServiceEdit.replaceFirst(':id', item.id.toString()));
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(loc.areYouSureDelete),
                              content: Text(loc.areYouSureDeleteMessage),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  child: Text(loc.deletePermanently, style: const TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(vendorServicesProvider.notifier).forceDeleteService(item.id);
                          }
                        } else if (value == 'disable') {
                          await ref.read(vendorServicesProvider.notifier).disableService(item.id);
                        } else if (value == 'enable') {
                          await ref.read(vendorServicesProvider.notifier).enableService(item.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text(loc.edit)),
                        PopupMenuItem(
                          value: (item.status.contains('Disabled') || item.status.contains('موقوف') || item.status.contains('معطل'))
                              ? 'enable'
                              : 'disable',
                          child: Text((item.status.contains('Disabled') || item.status.contains('موقوف') || item.status.contains('معطل'))
                              ? loc.enable
                              : loc.disable),
                        ),
                        PopupMenuItem(value: 'delete', child: Text(loc.deletePermanently)),
                      ],
                    ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: items.length,
            );
          },
        ),
      ),
    );
  }
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


