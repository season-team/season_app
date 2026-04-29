import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/core/services/country_detection_service.dart';
import 'package:season_app/features/vendor/data/vendor_models.dart';
import 'package:season_app/shared/providers/app_providers.dart';

final vendorServiceApiProvider = Provider<VendorServiceApi>((ref) {
  final dio = ref.watch(dioProvider);
  return VendorServiceApi(dio);
});

class VendorServiceApi {
  final Dio _dio;
  VendorServiceApi(this._dio);

  Future<List<ServiceTypeModel>> getServiceTypes() async {
    final res = await _dio.get(ApiEndpoints.serviceTypes);
    final list = (res.data['data'] as List?) ?? [];
    return list.map((e) => ServiceTypeModel.fromJson(e)).toList();
  }

  Future<List<CountryModel>> getCountries() async {
    final res = await _dio.get(ApiEndpoints.locationCountries);
    final list = (res.data['data'] as List?) ?? [];
    return list.map((e) => CountryModel.fromJson(e)).toList();
  }

  Future<List<VendorServiceSummary>> getVendorServices() async {
    // Use my-services endpoint to get user's own services
    final res = await _dio.get(ApiEndpoints.vendorServicesMyServices);
    final list = (res.data['data'] as List?) ?? [];
    return list.map((e) => VendorServiceSummary.fromJson(e)).toList();
  }

  Future<List<PublicVendorService>> getPublicVendorServices() async {
    // Detect country from device IP (cached) to send Accept-Country
    final countryCode = await CountryDetectionService.getCountryCodeFromIP();

    final res = await _dio.get(
      ApiEndpoints.vendorServices,
      options: Options(
        headers: {
          // 3-letter code, default to SAU if detection fails
          'Accept-Country': countryCode ?? 'SAU',
        },
      ),
    );
    final list = (res.data['data'] as List?) ?? [];
    return list.map((e) => PublicVendorService.fromJson(e)).toList();
  }

  Future<VendorServiceDetails> getVendorServiceDetails(int id) async {
    final path = ApiEndpoints.vendorServiceMyServiceById.replaceFirst('{id}', id.toString());
    final res = await _dio.get(path);
    return VendorServiceDetails.fromJson(res.data['data']);
  }

  Future<void> deleteVendorService(int id) async {
    final path = ApiEndpoints.vendorServiceById.replaceFirst('{id}', id.toString());
    await _dio.delete(path);
  }

  Future<void> disableVendorService(int id) async {
    final path = ApiEndpoints.vendorServiceById.replaceFirst('{id}', id.toString());
    await _dio.delete(path);
  }

  Future<void> enableVendorService(int id) async {
    final path = ApiEndpoints.vendorServiceEnable.replaceFirst('{id}', id.toString());
    await _dio.post(path);
  }

  Future<void> forceDeleteVendorService(int id) async {
    final path = ApiEndpoints.vendorServiceForceDelete.replaceFirst('{id}', id.toString());
    await _dio.delete(path);
  }

  Future<void> updateVendorService(
    int id,
    Map<String, dynamic> fields, {
    File? commercialRegister,
    List<File> images = const [],
  }) async {
    final path = ApiEndpoints.vendorServiceById.replaceFirst('{id}', id.toString());

    // Always send POST with _method override for Laravel-style updates
    fields['_method'] = 'PUT';

    final form = await _buildFormData(
      fields,
      commercialRegister: commercialRegister,
      images: images,
    );

    await _dio.post(
      path,
      data: form,
      options: Options(
        headers: {
          Headers.acceptHeader: 'application/json',
          Headers.contentTypeHeader: 'multipart/form-data',
        },
      ),
    );
  }

  Future<void> createVendorService(
    Map<String, dynamic> fields, {
    File? commercialRegister,
    List<File> images = const [],
  }) async {
    final form = await _buildFormData(
      fields,
      commercialRegister: commercialRegister,
      images: images,
    );
    await _dio.post(ApiEndpoints.vendorServices, data: form);
  }

  Future<FormData> _buildFormData(
    Map<String, dynamic> fields, {
    File? commercialRegister,
    List<File> images = const [],
  }) async {
    final formData = FormData();

    // Regular fields
    fields.forEach((key, value) {
      if (value is List) {
        for (final item in value) {
          formData.fields.add(MapEntry(key, item.toString()));
        }
      } else {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    // File: commercial_register
    if (commercialRegister != null) {
      formData.files.add(
        MapEntry(
          'commercial_register',
          await MultipartFile.fromFile(
            commercialRegister.path,
            filename: commercialRegister.path.split('/').last,
          ),
        ),
      );
    }

    // Files: images[]
    for (final image in images) {
      formData.files.add(
        MapEntry(
          'images[]',
          await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          ),
        ),
      );
    }

    return formData;
  }
}
