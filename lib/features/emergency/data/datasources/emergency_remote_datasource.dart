import 'package:dio/dio.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/core/services/country_detection_service.dart';
import 'package:season_app/features/emergency/data/models/emergency_model.dart';

class EmergencyRemoteDataSource {
  final Dio dio;

  EmergencyRemoteDataSource(this.dio);

  Future<EmergencyModel> getEmergencyNumbers() async {
    // Get country code
    final countryCode = await CountryDetectionService.getCountryCodeFromIP();
    
    final response = await dio.get(
      ApiEndpoints.emergency,
      options: Options(
        headers: {
          'Accept-Country': countryCode ?? 'SAU',
        },
      ),
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        return EmergencyModel.fromJson(data);
      }
    }

    throw Exception('Invalid response format');
  }
}
