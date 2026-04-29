import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/currency/data/datasources/currency_remote_datasource.dart';
import 'package:season_app/features/currency/data/models/currency_conversion_model.dart';
import 'package:season_app/features/currency/data/repositories/currency_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = CurrencyRemoteDataSource(dio);
  return CurrencyRepository(dataSource);
});

class CurrencyState {
  final CurrencyConversionModel? conversion;
  final bool isLoading;
  final String? error;

  const CurrencyState({
    this.conversion,
    this.isLoading = false,
    this.error,
  });

  CurrencyState copyWith({
    CurrencyConversionModel? conversion,
    bool? isLoading,
    String? error,
  }) {
    return CurrencyState(
      conversion: conversion ?? this.conversion,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CurrencyNotifier extends Notifier<CurrencyState> {
  CurrencyRepository get _repository => ref.read(currencyRepositoryProvider);

  @override
  CurrencyState build() {
    return const CurrencyState();
  }

  Future<void> convertCurrency({
    required String from,
    required String to,
    required double amount,
    String? date,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversion = await _repository.convertCurrency(
        from: from,
        to: to,
        amount: amount,
        date: date,
      );
      state = state.copyWith(
        conversion: conversion,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearConversion() {
    state = state.copyWith(conversion: null, error: null);
  }
}

final currencyControllerProvider =
    NotifierProvider<CurrencyNotifier, CurrencyState>(CurrencyNotifier.new);
