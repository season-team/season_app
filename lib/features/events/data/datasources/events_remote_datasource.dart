import 'package:dio/dio.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/core/services/country_detection_service.dart';
import 'package:season_app/features/events/data/models/event_model.dart';

class EventsRemoteDataSource {
  final Dio _dio;

  EventsRemoteDataSource(this._dio);

  Future<EventsResponse> getEvents(String language) async {
    // Detect country from device IP (cached) to send Accept-Country
    final countryCode = await CountryDetectionService.getCountryCodeFromIP();

    final response = await _dio.get(
      ApiEndpoints.events,
      options: Options(
        headers: {
          'Accept-Language': language,
          // 3-letter code, default to SAU if detection fails
          'Accept-Country': countryCode ?? 'SAU',
        },
        // Increase timeout for events API (60 seconds)
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    // Handle both response structures: wrapped in 'data' key or direct
    final data = response.data['data'] ?? response.data;
    
    if (data == null) {
      throw Exception('Invalid response structure: data is null');
    }
    
    return EventsResponse.fromJson(data as Map<String, dynamic>);
  }
}
