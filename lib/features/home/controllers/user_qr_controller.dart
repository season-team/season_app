import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/home/data/datasources/user_qr_datasource.dart';
import 'package:season_app/features/home/data/models/user_qr_model.dart';

class UserQrState {
  final UserQrModel? userQr;
  final bool isLoading;
  final String? error;

  const UserQrState({
    this.userQr,
    this.isLoading = false,
    this.error,
  });

  UserQrState copyWith({
    UserQrModel? userQr,
    bool? isLoading,
    String? error,
  }) {
    return UserQrState(
      userQr: userQr ?? this.userQr,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserQrController extends Notifier<UserQrState> {
  @override
  UserQrState build() {
    return const UserQrState();
  }

  Future<void> loadUserQr() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final dataSource = ref.read(userQrDataSourceProvider);
      final userQr = await dataSource.getUserQr();
      state = state.copyWith(userQr: userQr, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}

final userQrControllerProvider = NotifierProvider<UserQrController, UserQrState>(() {
  return UserQrController();
});
