import 'dart:io';

import 'package:dio/dio.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/features/geographical_guides/data/models/geographical_guide_models.dart';

class GeographicalGuidesRemoteDataSource {
  final Dio _dio;

  GeographicalGuidesRemoteDataSource(this._dio);

  /// Get cities by country code (using Accept-Country header)
  Future<List<City>> getCities(String? countryCode) async {
    final headers = <String, dynamic>{};
    if (countryCode != null) {
      headers['Accept-Country'] = countryCode;
    }

    final response = await _dio.get(
      ApiEndpoints.locationCities,
      options: Options(headers: headers),
    );
    final list = (response.data['data'] as List?) ?? [];
    return list.map((json) => City.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get geographical categories (includes sub_categories nested)
  Future<List<GeographicalCategory>> getGeographicalCategories() async {
    final response = await _dio.get(ApiEndpoints.geographicalCategories);
    final list = (response.data['data'] as List?) ?? [];
    return list
        .map((json) =>
            GeographicalCategory.fromJson(json as Map<String, dynamic>))
        .where((category) => category.isActive)
        .toList();
  }

  /// Get single geographical category by ID
  Future<GeographicalCategory> getGeographicalCategory(int id) async {
    final response = await _dio.get('${ApiEndpoints.geographicalCategories}/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return GeographicalCategory.fromJson(data);
  }

  /// Get geographical sub-categories (optional filter by category ID)
  Future<List<GeographicalSubCategory>> getGeographicalSubCategories({
    int? geographicalCategoryId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (geographicalCategoryId != null) {
      queryParams['geographical_category_id'] = geographicalCategoryId;
    }

    final response = await _dio.get(
      ApiEndpoints.geographicalSubCategories,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = (response.data['data'] as List?) ?? [];
    return list
        .map((json) =>
            GeographicalSubCategory.fromJson(json as Map<String, dynamic>))
        .where((subCategory) => subCategory.isActive)
        .toList();
  }

  /// Get single geographical sub-category by ID
  Future<GeographicalSubCategory> getGeographicalSubCategory(int id) async {
    final response =
        await _dio.get('${ApiEndpoints.geographicalSubCategories}/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return GeographicalSubCategory.fromJson(data);
  }

  /// Get all geographical guides with optional filters
  Future<List<GeographicalGuide>> getGeographicalGuides({
    String? countryCode,
    int? cityId,
    int? geographicalCategoryId,
    int? geographicalSubCategoryId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (cityId != null) queryParams['city_id'] = cityId;
    if (geographicalCategoryId != null)
      queryParams['geographical_category_id'] = geographicalCategoryId;
    if (geographicalSubCategoryId != null)
      queryParams['geographical_sub_category_id'] = geographicalSubCategoryId;

    final headers = <String, dynamic>{};
    if (countryCode != null) {
      headers['Accept-Country'] = countryCode;
    }

    final response = await _dio.get(
      ApiEndpoints.geographicalGuides,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      options: Options(headers: headers.isNotEmpty ? headers : null),
    );
    final list = (response.data['data'] as List?) ?? [];
    return list
        .map((json) =>
            GeographicalGuide.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get user's own geographical guides (my-services)
  Future<List<GeographicalGuide>> getMyGeographicalGuides() async {
    final response = await _dio.get(ApiEndpoints.geographicalGuidesMyServices);
    final list = (response.data['data'] as List?) ?? [];
    return list
        .map((json) =>
            GeographicalGuide.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get single user's geographical guide service by ID
  /// Uses GET /api/geographical-guides/my-service/{id}
  Future<GeographicalGuide> getMyGeographicalGuide(int id) async {
    final path = ApiEndpoints.geographicalGuideMyServiceById.replaceFirst('{id}', id.toString());
    final response = await _dio.get(path);
    final responseData = response.data;
    if (responseData == null) {
      throw Exception('Response data is null');
    }
    final data = responseData['data'] ?? responseData;
    if (data == null) {
      throw Exception('Guide data is null');
    }
    return GeographicalGuide.fromJson(data as Map<String, dynamic>);
  }

  /// Get single geographical guide by ID
  /// Uses GET /api/geographical-guides/{id}
  Future<GeographicalGuide> getGeographicalGuide(int id) async {
    final path = ApiEndpoints.geographicalGuideById.replaceFirst('{id}', id.toString());
    final response = await _dio.get(path);
    final responseData = response.data;
    if (responseData == null) {
      throw Exception('Response data is null');
    }
    final data = responseData['data'] ?? responseData;
    if (data == null) {
      throw Exception('Guide data is null');
    }
    return GeographicalGuide.fromJson(data as Map<String, dynamic>);
  }

  /// Create a new geographical guide
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
    final formData = FormData();

    // Add required fields
    formData.fields.add(MapEntry('geographical_category_id',
        geographicalCategoryId.toString()));
    if (geographicalSubCategoryId != null) {
      formData.fields.add(MapEntry('geographical_sub_category_id',
          geographicalSubCategoryId.toString()));
    }
    formData.fields.add(MapEntry('service_name', serviceName));
    if (description != null && description.isNotEmpty) {
      formData.fields.add(MapEntry('description', description));
    }
    if (phone1 != null && phone1.isNotEmpty) {
      formData.fields.add(MapEntry('phone_1', phone1));
    }
    if (phone2 != null && phone2.isNotEmpty) {
      formData.fields.add(MapEntry('phone_2', phone2));
    }
    formData.fields.add(MapEntry('country_id', countryId.toString()));
    formData.fields.add(MapEntry('city_id', cityId.toString()));
    if (address != null && address.isNotEmpty) {
      formData.fields.add(MapEntry('address', address));
    }
    if (latitude != null) {
      formData.fields.add(MapEntry('latitude', latitude.toString()));
    }
    if (longitude != null) {
      formData.fields.add(MapEntry('longitude', longitude.toString()));
    }
    if (website != null && website.isNotEmpty) {
      formData.fields.add(MapEntry('website', website));
    }
    if (establishmentNumber != null && establishmentNumber.isNotEmpty) {
      formData.fields.add(MapEntry('establishment_number', establishmentNumber));
    }

    // Add commercial register file if provided
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

    final response = await _dio.post(
      ApiEndpoints.geographicalGuides,
      data: formData,
      options: Options(
        headers: {
          Headers.acceptHeader: 'application/json',
          Headers.contentTypeHeader: 'multipart/form-data',
        },
      ),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return GeographicalGuide.fromJson(data);
  }

  /// Update a geographical guide
  /// Uses PUT /api/geographical-guides/{id}
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
    final path = ApiEndpoints.geographicalGuideById.replaceFirst('{id}', id.toString());
    final body = <String, dynamic>{};

    // Add fields only if provided (partial update)
    if (geographicalCategoryId != null) {
      body['geographical_category_id'] = geographicalCategoryId;
    }
    if (geographicalSubCategoryId != null) {
      body['geographical_sub_category_id'] = geographicalSubCategoryId;
    }
    if (serviceName != null && serviceName.isNotEmpty) {
      body['service_name'] = serviceName;
    }
    if (description != null) {
      body['description'] = description;
    }
    if (phone1 != null) {
      body['phone_1'] = phone1;
    }
    if (phone2 != null) {
      body['phone_2'] = phone2;
    }
    if (countryId != null) {
      body['country_id'] = countryId;
    }
    if (cityId != null) {
      body['city_id'] = cityId;
    }
    if (address != null) {
      body['address'] = address;
    }
    if (latitude != null) {
      body['latitude'] = latitude;
    }
    if (longitude != null) {
      body['longitude'] = longitude;
    }
    if (website != null) {
      body['website'] = website;
    }
    if (establishmentNumber != null && establishmentNumber.isNotEmpty) {
      body['establishment_number'] = establishmentNumber;
    }

    // Note: File uploads (commercial_register) are not supported in JSON body
    // If file upload is needed, it should be handled separately or use form-data

    final response = await _dio.put(
      path,
      data: body,
      options: Options(
        headers: {
          Headers.acceptHeader: 'application/json',
          Headers.contentTypeHeader: 'application/json',
        },
      ),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return GeographicalGuide.fromJson(data);
  }

  /// Delete a geographical guide
  /// Uses DELETE /api/geographical-guides/{id}
  Future<void> deleteGeographicalGuide(int id) async {
    final path = ApiEndpoints.geographicalGuideById.replaceFirst('{id}', id.toString());
    await _dio.delete(path);
  }
}

