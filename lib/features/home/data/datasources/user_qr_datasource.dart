import 'package:dio/dio.dart';
import 'package:season_app/features/home/data/models/user_qr_model.dart';
import 'package:season_app/shared/providers/app_providers.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserQrDataSource {
  final Dio _dio;

  UserQrDataSource(this._dio);

  Future<UserQrModel> getUserQr() async {
    try {
      final response = await _dio.get(ApiEndpoints.userQr);
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return UserQrModel.fromJson(data);
      } else {
        throw Exception('Failed to load user QR data');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (e.response?.statusCode == 404) {
        throw Exception('User QR not found');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

final userQrDataSourceProvider = Provider<UserQrDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return UserQrDataSource(dio);
});
