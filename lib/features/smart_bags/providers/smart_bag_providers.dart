import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/smart_bags/data/datasources/smart_bag_remote_datasource.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_analysis_model.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_item_model.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_model.dart';
import 'package:season_app/features/smart_bags/data/repositories/smart_bag_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';

final smartBagRepositoryProvider = Provider<SmartBagRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = SmartBagRemoteDataSource(dio);
  return SmartBagRepository(dataSource);
});

class SmartBagListState {
  final List<SmartBagModel> bags;
  final Map<String, dynamic>? pagination;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final String? tripTypeFilter;
  final bool? upcomingFilter;

  const SmartBagListState({
    required this.bags,
    this.pagination,
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.tripTypeFilter,
    this.upcomingFilter,
  });

  SmartBagListState copyWith({
    List<SmartBagModel>? bags,
    Map<String, dynamic>? pagination,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? tripTypeFilter,
    bool? upcomingFilter,
  }) {
    return SmartBagListState(
      bags: bags ?? this.bags,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      tripTypeFilter: tripTypeFilter ?? this.tripTypeFilter,
      upcomingFilter: upcomingFilter ?? this.upcomingFilter,
    );
  }
}

class SmartBagListNotifier extends Notifier<SmartBagListState> {
  SmartBagRepository get _repository => ref.read(smartBagRepositoryProvider);

  @override
  SmartBagListState build() {
    Future.microtask(loadBags);
    return const SmartBagListState(bags: []);
  }

  Future<void> loadBags({
    String? status,
    String? tripType,
    bool? upcoming,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getBags(
        status: status ?? state.statusFilter,
        tripType: tripType ?? state.tripTypeFilter,
        upcoming: upcoming ?? state.upcomingFilter,
        sortBy: sortBy,
        sortOrder: sortOrder,
        perPage: perPage,
        page: page,
      );
      state = state.copyWith(
        bags: result['bags'] as List<SmartBagModel>,
        pagination: result['pagination'] as Map<String, dynamic>?,
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
    await loadBags();
  }

  void setFilters({
    String? status,
    String? tripType,
    bool? upcoming,
  }) {
    state = state.copyWith(
      statusFilter: status,
      tripTypeFilter: tripType,
      upcomingFilter: upcoming,
    );
    loadBags();
  }
}

final smartBagListControllerProvider =
    NotifierProvider<SmartBagListNotifier, SmartBagListState>(
        SmartBagListNotifier.new);

// Detail State
class SmartBagDetailState {
  final SmartBagModel? bag;
  final List<SmartBagItemModel> items;
  final SmartBagAnalysisModel? latestAnalysis;
  final Map<String, dynamic>? smartAlert;
  final bool isLoading;
  final bool isAnalyzing;
  final String? error;

  const SmartBagDetailState({
    this.bag,
    required this.items,
    this.latestAnalysis,
    this.smartAlert,
    this.isLoading = false,
    this.isAnalyzing = false,
    this.error,
  });

  SmartBagDetailState copyWith({
    SmartBagModel? bag,
    List<SmartBagItemModel>? items,
    SmartBagAnalysisModel? latestAnalysis,
    Map<String, dynamic>? smartAlert,
    bool? isLoading,
    bool? isAnalyzing,
    String? error,
  }) {
    return SmartBagDetailState(
      bag: bag ?? this.bag,
      items: items ?? this.items,
      latestAnalysis: latestAnalysis ?? this.latestAnalysis,
      smartAlert: smartAlert ?? this.smartAlert,
      isLoading: isLoading ?? this.isLoading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
    );
  }
}

class SmartBagDetailNotifier extends Notifier<SmartBagDetailState> {
  SmartBagRepository get _repository => ref.read(smartBagRepositoryProvider);
  int? _currentBagId;

  @override
  SmartBagDetailState build() {
    return const SmartBagDetailState(items: []);
  }

  Future<void> loadBagDetails(int bagId) async {
    _currentBagId = bagId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getBagDetails(bagId);
      state = state.copyWith(
        bag: result['bag'] as SmartBagModel,
        items: result['items'] as List<SmartBagItemModel>,
        latestAnalysis: result['latest_analysis'] as SmartBagAnalysisModel?,
        isLoading: false,
      );
      await loadSmartAlert(bagId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadSmartAlert(int bagId) async {
    try {
      final alert = await _repository.getSmartAlert(bagId);
      state = state.copyWith(smartAlert: alert);
    } catch (e) {
      // Ignore errors for smart alert
    }
  }

  Future<void> refresh() async {
    if (_currentBagId != null) {
      await loadBagDetails(_currentBagId!);
    }
  }

  Future<bool> createBag({
    required String name,
    required String tripType,
    required int duration,
    required String destination,
    required DateTime departureDate,
    required double maxWeight,
    String? status,
    Map<String, dynamic>? preferences,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final bag = await _repository.createBag(
      name: name,
      tripType: tripType,
      duration: duration,
      destination: destination,
      departureDate: departureDate,
      maxWeight: maxWeight,
      status: status,
      preferences: preferences,
      items: items,
    );
      await loadBagDetails(bag.id);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateBag({
    required int bagId,
    String? name,
    String? tripType,
    int? duration,
    String? destination,
    DateTime? departureDate,
    double? maxWeight,
    String? status,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      await _repository.updateBag(
        bagId: bagId,
        name: name,
        tripType: tripType,
        duration: duration,
        destination: destination,
        departureDate: departureDate,
        maxWeight: maxWeight,
        status: status,
        preferences: preferences,
      );
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteBag(int bagId) async {
    try {
      await _repository.deleteBag(bagId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addItem({
    required int bagId,
    required String name,
    required double weight,
    required String category,
    bool? essential,
    bool? packed,
    int? quantity,
    String? notes,
  }) async {
    try {
      await _repository.addItemToBag(
        bagId: bagId,
        name: name,
        weight: weight,
        category: category,
        essential: essential,
        packed: packed,
        quantity: quantity,
        notes: notes,
      );
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateItem({
    required int bagId,
    required int itemId,
    String? name,
    double? weight,
    String? category,
    bool? essential,
    bool? packed,
    int? quantity,
    String? notes,
  }) async {
    try {
      await _repository.updateItem(
        bagId: bagId,
        itemId: itemId,
        name: name,
        weight: weight,
        category: category,
        essential: essential,
        packed: packed,
        quantity: quantity,
        notes: notes,
      );
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteItem({
    required int bagId,
    required int itemId,
  }) async {
    try {
      await _repository.deleteItem(bagId: bagId, itemId: itemId);
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> toggleItemPacked({
    required int bagId,
    required int itemId,
  }) async {
    try {
      await _repository.toggleItemPacked(bagId: bagId, itemId: itemId);
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<SmartBagAnalysisModel?> analyzeBag({
    required int bagId,
    Map<String, dynamic>? preferences,
    bool? forceReanalysis,
  }) async {
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final analysis = await _repository.analyzeBag(
        bagId: bagId,
        preferences: preferences,
        forceReanalysis: forceReanalysis,
      );
      await refresh();
      state = state.copyWith(isAnalyzing: false);
      return analysis;
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
      return null;
    }
  }
}

final smartBagDetailControllerProvider =
    NotifierProvider<SmartBagDetailNotifier, SmartBagDetailState>(
        SmartBagDetailNotifier.new);

