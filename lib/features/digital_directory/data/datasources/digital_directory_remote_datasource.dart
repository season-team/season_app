import 'package:dio/dio.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/core/services/country_detection_service.dart';
import 'package:season_app/features/digital_directory/data/models/category_app_model.dart';
import 'package:season_app/features/digital_directory/data/models/category_model.dart';

class DigitalDirectoryRemoteDataSource {
  final Dio _dio;

  DigitalDirectoryRemoteDataSource(this._dio);

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get(ApiEndpoints.categories);
    final list = (response.data['data'] as List?) ?? [];
    return list
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .where((category) => category.isActive)
        .toList();
  }

  Future<List<CategoryAppModel>> getCategoryApps(int categoryId) async {
    // Detect country from device IP (cached) to send Accept-Country
    final countryCode = await CountryDetectionService.getCountryCodeFromIP();

    final response = await _dio.get(
      ApiEndpoints.digitalDirectoryCategoryApps,
      queryParameters: {'category_id': categoryId},
      options: Options(
        headers: {
          // 3-letter code, default to SAU if detection fails
          'Accept-Country': countryCode ?? 'SAU',
        },
      ),
    );
    final list = (response.data['data'] as List?) ?? [];
    return list
        .map((json) => CategoryAppModel.fromJson(json as Map<String, dynamic>))
        .where((app) => app.isActive)
        .toList();
  }
}
