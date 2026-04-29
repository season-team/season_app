import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:season_app/features/emergency/data/models/emergency_model.dart';
import 'package:season_app/features/emergency/data/repositories/emergency_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = EmergencyRemoteDataSource(dio);
  return EmergencyRepository(dataSource);
});

class EmergencyState {
  final EmergencyModel? emergencyNumbers;
  final bool isLoading;
  final String? error;

  const EmergencyState({
    this.emergencyNumbers,
    this.isLoading = false,
    this.error,
  });

  EmergencyState copyWith({
    EmergencyModel? emergencyNumbers,
    bool? isLoading,
    String? error,
  }) {
    return EmergencyState(
      emergencyNumbers: emergencyNumbers ?? this.emergencyNumbers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EmergencyNotifier extends Notifier<EmergencyState> {
  EmergencyRepository get _repository => ref.read(emergencyRepositoryProvider);

  @override
  EmergencyState build() {
    Future.microtask(_loadEmergencyNumbers);
    return const EmergencyState();
  }

  Future<void> _loadEmergencyNumbers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final numbers = await _repository.getEmergencyNumbers();
      state = state.copyWith(
        emergencyNumbers: numbers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await _loadEmergencyNumbers();
  }
}

final emergencyControllerProvider =
    NotifierProvider<EmergencyNotifier, EmergencyState>(EmergencyNotifier.new);
