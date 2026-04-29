import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/services/country_detection_service.dart';
import 'package:season_app/features/geographical_guides/data/datasources/geographical_guides_remote_datasource.dart';
import 'package:season_app/features/geographical_guides/data/models/geographical_guide_models.dart';
import 'package:season_app/features/geographical_guides/data/repositories/geographical_guides_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

// Remote Data Source Provider
final geographicalGuidesRemoteDataSourceProvider =
    Provider<GeographicalGuidesRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return GeographicalGuidesRemoteDataSource(dio);
});

// Repository Provider
final geographicalGuidesRepositoryProvider =
    Provider<GeographicalGuidesRepository>((ref) {
  final remoteDataSource =
      ref.watch(geographicalGuidesRemoteDataSourceProvider);
  return GeographicalGuidesRepository(remoteDataSource);
});

// Cities Provider (by country code)
final citiesByCountryProvider =
    FutureProvider.family<List<City>, String?>((ref, countryCode) async {
  ref.watch(localeProvider); // Watch locale to refetch when language changes
  return ref.read(geographicalGuidesRepositoryProvider).getCities(countryCode);
});

// Geographical Categories Provider
final geographicalCategoriesProvider =
    FutureProvider<List<GeographicalCategory>>((ref) async {
  ref.watch(localeProvider); // Watch locale to refetch when language changes
  return ref
      .read(geographicalGuidesRepositoryProvider)
      .getGeographicalCategories();
});

// Single Geographical Category Provider
final geographicalCategoryProvider =
    FutureProvider.family<GeographicalCategory, int>((ref, id) async {
  ref.watch(localeProvider);
  return ref.read(geographicalGuidesRepositoryProvider).getGeographicalCategory(id);
});

// Geographical Sub-Categories Provider (optional filter by category ID)
final geographicalSubCategoriesProvider =
    FutureProvider.family<List<GeographicalSubCategory>, int?>((ref, categoryId) async {
  ref.watch(localeProvider); // Watch locale to refetch when language changes
  return ref
      .read(geographicalGuidesRepositoryProvider)
      .getGeographicalSubCategories(
        geographicalCategoryId: categoryId,
      );
});

// Single Geographical Sub-Category Provider
final geographicalSubCategoryProvider =
    FutureProvider.family<GeographicalSubCategory, int>((ref, id) async {
  ref.watch(localeProvider);
  return ref.read(geographicalGuidesRepositoryProvider).getGeographicalSubCategory(id);
});

// Geographical Guides Provider (with optional filters)
final geographicalGuidesProvider = FutureProvider.family<
    List<GeographicalGuide>,
    ({
      String? countryCode,
      int? cityId,
      int? geographicalCategoryId,
      int? geographicalSubCategoryId,
    })>((ref, filters) async {
  ref.watch(localeProvider); // Watch locale to refetch when language changes
  
  // Auto-detect country code if not provided
  String? countryCode = filters.countryCode;
  if (countryCode == null) {
    countryCode = await CountryDetectionService.getCountryCodeFromIP();
  }
  
  return ref.read(geographicalGuidesRepositoryProvider).getGeographicalGuides(
        countryCode: countryCode,
        cityId: filters.cityId,
        geographicalCategoryId: filters.geographicalCategoryId,
        geographicalSubCategoryId: filters.geographicalSubCategoryId,
      );
});

// My Services Provider
final myGeographicalGuidesProvider =
    FutureProvider<List<GeographicalGuide>>((ref) async {
  ref.watch(localeProvider); // Watch locale to refetch when language changes
  return ref.read(geographicalGuidesRepositoryProvider).getMyGeographicalGuides();
});

// Single My Service Provider (uses /my-service/{id} endpoint)
final myGeographicalGuideProvider =
    FutureProvider.family<GeographicalGuide, int>((ref, id) async {
  ref.watch(localeProvider);
  return ref.read(geographicalGuidesRepositoryProvider).getMyGeographicalGuide(id);
});

// Single Guide Provider (public endpoint)
final geographicalGuideProvider =
    FutureProvider.family<GeographicalGuide, int>((ref, id) async {
  ref.watch(localeProvider);
  return ref.read(geographicalGuidesRepositoryProvider).getGeographicalGuide(id);
});

// Form Controller Provider
class GeographicalGuideFormController {
  final Ref ref;

  GeographicalGuideFormController(this.ref);

  Future<GeographicalGuide> createGeographicalGuide({
    required int geographicalCategoryId,
    int? geographicalSubCategoryId,
    required String serviceName,
    String? description,
    String? phone1,
    String? phone2,
    required int countryId,
    required int cityId,
    String? address,
    double? latitude,
    double? longitude,
    String? website,
    File? commercialRegister,
    String? establishmentNumber,
  }) async {
    final guide = await ref
        .read(geographicalGuidesRepositoryProvider)
        .createGeographicalGuide(
          geographicalCategoryId: geographicalCategoryId,
          geographicalSubCategoryId: geographicalSubCategoryId,
          serviceName: serviceName,
          description: description,
          phone1: phone1,
          phone2: phone2,
          countryId: countryId,
          cityId: cityId,
          address: address,
          latitude: latitude,
          longitude: longitude,
          website: website,
          commercialRegister: commercialRegister,
          establishmentNumber: establishmentNumber,
        );

    // Invalidate guides provider to refresh list
    ref.invalidate(geographicalGuidesProvider);
    ref.invalidate(myGeographicalGuidesProvider);

    return guide;
  }

  Future<GeographicalGuide> updateGeographicalGuide({
    required int id,
    int? geographicalCategoryId,
    int? geographicalSubCategoryId,
    String? serviceName,
    String? description,
    String? phone1,
    String? phone2,
    int? countryId,
    int? cityId,
    String? address,
    double? latitude,
    double? longitude,
    String? website,
    File? commercialRegister,
    String? establishmentNumber,
  }) async {
    final guide = await ref
        .read(geographicalGuidesRepositoryProvider)
        .updateGeographicalGuide(
          id: id,
          geographicalCategoryId: geographicalCategoryId,
          geographicalSubCategoryId: geographicalSubCategoryId,
          serviceName: serviceName,
          description: description,
          phone1: phone1,
          phone2: phone2,
          countryId: countryId,
          cityId: cityId,
          address: address,
          latitude: latitude,
          longitude: longitude,
          website: website,
          commercialRegister: commercialRegister,
          establishmentNumber: establishmentNumber,
        );

    // Invalidate providers to refresh lists
    ref.invalidate(geographicalGuidesProvider);
    ref.invalidate(myGeographicalGuidesProvider);
    ref.invalidate(geographicalGuideProvider(id));

    return guide;
  }

  Future<void> deleteGeographicalGuide(int id) async {
    await ref.read(geographicalGuidesRepositoryProvider).deleteGeographicalGuide(id);

    // Invalidate providers to refresh lists
    ref.invalidate(geographicalGuidesProvider);
    ref.invalidate(myGeographicalGuidesProvider);
    ref.invalidate(geographicalGuideProvider(id));
  }
}

final geographicalGuideFormControllerProvider =
    Provider<GeographicalGuideFormController>((ref) {
  return GeographicalGuideFormController(ref);
});

