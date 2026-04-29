import 'package:dio/dio.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/features/currency/data/models/currency_conversion_model.dart';

class CurrencyRemoteDataSource {
  final Dio dio;

  CurrencyRemoteDataSource(this.dio);

  Future<CurrencyConversionModel> convertCurrency({
    required String from,
    required String to,
    required double amount,
    String? date,
  }) async {
    final response = await dio.post(
      ApiEndpoints.currencyConvert,
      data: {
        'from': from,
        'to': to,
        'amount': amount,
        if (date != null) 'date': date,
      },
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        return CurrencyConversionModel.fromJson(data);
      }
    }

    throw Exception('Invalid response format');
  }
}
