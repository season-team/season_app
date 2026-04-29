import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/vendor/data/vendor_models.dart';
import 'package:season_app/features/vendor/data/vendor_service_api.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

// Service types
final serviceTypesProvider = FutureProvider<List<ServiceTypeModel>>((ref) async {
  return ref.read(vendorServiceApiProvider).getServiceTypes();
});

// Countries - watches locale to refetch when language changes
final countriesProvider = FutureProvider<List<CountryModel>>((ref) async {
  // Watch locale to refetch countries when language changes
  ref.watch(localeProvider);
  return ref.read(vendorServiceApiProvider).getCountries();
});

// Vendor services list (AsyncNotifier in Riverpod v3)
class VendorServicesController extends AsyncNotifier<List<VendorServiceSummary>> {
  VendorServiceApi get _api => ref.read(vendorServiceApiProvider);

  @override
  Future<List<VendorServiceSummary>> build() async {
    return _api.getVendorServices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.getVendorServices());
  }

  Future<void> deleteService(int id) async {
    await _api.deleteVendorService(id);
    await refresh();
  }

  Future<void> disableService(int id) async {
    await _api.disableVendorService(id);
    await refresh();
    // Invalidate details cache for this service
    ref.invalidate(vendorServiceDetailsProvider(id));
  }

  Future<void> enableService(int id) async {
    await _api.enableVendorService(id);
    await refresh();
    // Invalidate details cache for this service
    ref.invalidate(vendorServiceDetailsProvider(id));
  }

  Future<void> forceDeleteService(int id) async {
    await _api.forceDeleteVendorService(id);
    await refresh();
    ref.invalidate(vendorServiceDetailsProvider(id));
  }
}

final vendorServicesProvider =
    AsyncNotifierProvider<VendorServicesController, List<VendorServiceSummary>>(() {
  return VendorServicesController();
});

// Details
final vendorServiceDetailsProvider =
    FutureProvider.family<VendorServiceDetails, int>((ref, id) async {
  return ref.read(vendorServiceApiProvider).getVendorServiceDetails(id);
});

// Form actions
class VendorServiceFormController {
  VendorServiceFormController(this.ref);
  final Ref ref;

  Future<void> create(
    Map<String, dynamic> fields, {
    File? register,
    List<File> images = const [],
  }) async {
    await ref.read(vendorServiceApiProvider).createVendorService(
          fields,
          commercialRegister: register,
          images: images,
        );
    await ref.read(vendorServicesProvider.notifier).refresh();
  }

  Future<void> update(
    int id,
    Map<String, dynamic> fields, {
    File? register,
    List<File> images = const [],
  }) async {
    await ref.read(vendorServiceApiProvider).updateVendorService(
          id,
          fields,
          commercialRegister: register,
          images: images,
        );
    // Refresh list
    await ref.read(vendorServicesProvider.notifier).refresh();
    // Invalidate details so next watch re-fetches latest
    ref.invalidate(vendorServiceDetailsProvider(id));
  }
}

final vendorServiceFormControllerProvider =
    Provider<VendorServiceFormController>((ref) {
  return VendorServiceFormController(ref);
});

// Public Vendor Services (for home screen and public listing)
final publicVendorServicesProvider = FutureProvider<List<PublicVendorService>>((ref) async {
  // Watch locale to refetch when language changes
  ref.watch(localeProvider);
  return ref.read(vendorServiceApiProvider).getPublicVendorServices();
});

// Public Vendor Service Details
final publicVendorServiceDetailsProvider =
    FutureProvider.family<PublicVendorService, int>((ref, id) async {
  // Watch locale to refetch when language changes
  ref.watch(localeProvider);
  // Get all services and find the one with matching id
  final services = await ref.read(vendorServiceApiProvider).getPublicVendorServices();
  return services.firstWhere((s) => s.id == id);
});
