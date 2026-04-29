import 'package:dio/dio.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/features/banners/data/models/banner_model.dart';

class BannerRemoteDataSource {
  final Dio dio;

  BannerRemoteDataSource(this.dio);

  Future<List<BannerModel>> getAllBanners(String language) async {
    final response = await dio.get(
      ApiEndpoints.banners,
      options: Options(
        headers: {
          'Accept-Language': language,
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'];

      // API returns a list of banners; return all active ones
      if (data is List && data.isNotEmpty) {
        return data
            .map((bannerJson) => BannerModel.fromJson(bannerJson as Map<String, dynamic>))
            .where((banner) => banner.isActive)
            .toList();
      }
    }

    return [];
  }
}
