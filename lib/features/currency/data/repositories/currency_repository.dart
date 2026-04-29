import 'package:season_app/features/currency/data/datasources/currency_remote_datasource.dart';
import 'package:season_app/features/currency/data/models/currency_conversion_model.dart';

class CurrencyRepository {
  final CurrencyRemoteDataSource remoteDataSource;

  CurrencyRepository(this.remoteDataSource);

  Future<CurrencyConversionModel> convertCurrency({
    required String from,
    required String to,
    required double amount,
    String? date,
  }) =>
      remoteDataSource.convertCurrency(
        from: from,
        to: to,
        amount: amount,
        date: date,
      );
}
