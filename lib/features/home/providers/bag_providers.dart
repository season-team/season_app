import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/features/home/data/datasources/bag_remote_datasource.dart';
import 'package:season_app/features/home/data/models/bag_category_model.dart';
import 'package:season_app/features/home/data/models/bag_detail_model.dart';
import 'package:season_app/features/home/data/models/bag_item_model.dart';
import 'package:season_app/features/home/data/models/bag_type_model.dart';
import 'package:season_app/features/home/data/repositories/bag_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';

final bagRepositoryProvider = Provider<BagRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = BagRemoteDataSource(dio);
  return BagRepository(dataSource);
});

class BagState {
  final List<BagTypeModel> bagTypes;
  final BagTypeModel? selectedBagType;
  final List<BagCategoryModel> categories;
  final BagCategoryModel? selectedCategory;
  final List<BagItemModel> items;
  final List<BagDetailModel> bagDetails;
  final bool isLoading;
  final bool isLoadingItems;
  final bool isLoadingBagDetails;
  final String? error;

  const BagState({
    required this.bagTypes,
    required this.selectedBagType,
    required this.categories,
    required this.selectedCategory,
    required this.items,
    required this.bagDetails,
    required this.isLoading,
    required this.isLoadingItems,
    required this.isLoadingBagDetails,
    this.error,
  });

  factory BagState.initial() => const BagState(
        bagTypes: [],
        selectedBagType: null,
        categories: [],
        selectedCategory: null,
        items: [],
        bagDetails: [],
        isLoading: false,
        isLoadingItems: false,
        isLoadingBagDetails: false,
        error: null,
      );

  BagDetailModel? getSelectedBagDetail() {
    if (selectedBagType == null || bagDetails.isEmpty) return null;
    try {
      return bagDetails.firstWhere(
        (detail) => detail.bagTypeId == selectedBagType!.id,
      );
    } catch (e) {
      return null;
    }
  }

  BagState copyWith({
    List<BagTypeModel>? bagTypes,
    BagTypeModel? selectedBagType,
    List<BagCategoryModel>? categories,
    BagCategoryModel? selectedCategory,
    List<BagItemModel>? items,
    List<BagDetailModel>? bagDetails,
    bool? isLoading,
    bool? isLoadingItems,
    bool? isLoadingBagDetails,
    String? error,
  }) {
    return BagState(
      bagTypes: bagTypes ?? this.bagTypes,
      selectedBagType: selectedBagType ?? this.selectedBagType,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      items: items ?? this.items,
      bagDetails: bagDetails ?? this.bagDetails,
      isLoading: isLoading ?? this.isLoading,
      isLoadingItems: isLoadingItems ?? this.isLoadingItems,
      isLoadingBagDetails: isLoadingBagDetails ?? this.isLoadingBagDetails,
      error: error,
    );
  }
}

class BagNotifier extends Notifier<BagState> {
  BagRepository get _repository => ref.read(bagRepositoryProvider);

  @override
  BagState build() {
    Future.microtask(_loadInitialData);
    return BagState.initial();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Only load bagTypes and categories on initial load
      // Bags will be loaded when bag screen opens
      final bagTypes = await _repository.getBagTypes();
      final categories = await _repository.getCategories();

      BagTypeModel? selectedBagType = state.selectedBagType;
      if (bagTypes.isNotEmpty) {
        selectedBagType ??= bagTypes.first;
      }

      BagCategoryModel? selectedCategory = state.selectedCategory;
      if (categories.isNotEmpty) {
        selectedCategory ??= categories.first;
      }

      List<BagItemModel> items = state.items;
      if (selectedCategory != null) {
        items = await _repository.getCategoryItems(selectedCategory.id);
      } else {
        items = [];
      }

      state = state.copyWith(
        bagTypes: bagTypes,
        categories: categories,
        selectedBagType: selectedBagType,
        selectedCategory: selectedCategory,
        items: items,
        // Preserve existing bagDetails if they were already loaded
        // Don't clear them here - they will be loaded when bag screen opens
        bagDetails: state.bagDetails, // Keep existing bags
        isLoading: false,
        isLoadingItems: false,
        isLoadingBagDetails: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingItems: false,
        isLoadingBagDetails: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadBagDetails() async {
    state = state.copyWith(isLoadingBagDetails: true, error: null);
    try {
      debugPrint('📦 Loading bags from Smart Bags API...');
      final bagDetails = await _repository.getBagDetails();
      debugPrint('✅ Loaded ${bagDetails.length} bags from repository');
      debugPrint('   Bag IDs: ${bagDetails.map((b) => b.bagId).toList()}');
      
      state = state.copyWith(
        bagDetails: bagDetails,
        isLoadingBagDetails: false,
        error: null,
      );
      
      debugPrint('✅ State updated - bagDetails count: ${state.bagDetails.length}');
    } on ApiException catch (e) {
      // Handle API errors with better messages
      String errorMessage = e.message;
      if (e.message.contains('travel_bag_id') || e.message.contains('Column not found')) {
        errorMessage = 'Backend database error: Smart Bags API is using incorrect column name. '
            'Please check BACKEND_FIX_SMART_BAGS_API.md for details.';
      }
      debugPrint('❌ API Error loading bags: $errorMessage');
      state = state.copyWith(
        bagDetails: [], // Set empty list on error
        isLoadingBagDetails: false,
        error: errorMessage,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading bags: $e');
      debugPrint('   Stack trace: $stackTrace');
      state = state.copyWith(
        bagDetails: [], // Set empty list on error
        isLoadingBagDetails: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> addItemToBag({
    int? itemId,
    required int bagTypeId,
    required int quantity,
    String? customItemName,
    double? customWeight,
    String? weightUnit,
    int? itemCategoryId, // Use item_category_id instead of category
    String? category, // Deprecated - kept for backward compatibility
    bool? essential,
    bool? packed,
    String? notes,
  }) async {
    try {
      await _repository.addItemToBag(
        itemId: itemId,
        bagTypeId: bagTypeId,
        quantity: quantity,
        customItemName: customItemName,
        customWeight: customWeight,
        weightUnit: weightUnit,
        itemCategoryId: itemCategoryId,
        category: category,
        essential: essential,
        packed: packed,
        notes: notes,
      );
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteItemFromBag({
    required int itemId,
    required int bagTypeId,
  }) async {
    try {
      await _repository.deleteItemFromBag(
        itemId: itemId,
        bagTypeId: bagTypeId,
      );
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateItemQuantity({
    required int itemId,
    required int bagTypeId,
    required int quantity,
  }) async {
    try {
      await _repository.updateItemQuantity(
        itemId: itemId,
        bagTypeId: bagTypeId,
        quantity: quantity,
      );
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> refreshCategories() async {
    try {
      final categories = await _repository.getCategories();
      BagCategoryModel? selectedCategory = categories.isNotEmpty ? categories.first : null;
      state = state.copyWith(categories: categories, selectedCategory: selectedCategory);
      if (selectedCategory != null) {
        await selectCategory(selectedCategory);
      } else {
        state = state.copyWith(items: [], isLoadingItems: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void selectBagType(BagTypeModel bagType) {
    if (state.selectedBagType?.id == bagType.id) return;
    state = state.copyWith(selectedBagType: bagType);
  }

  Future<void> selectCategory(BagCategoryModel category) async {
    if (state.selectedCategory?.id == category.id) return;
    state = state.copyWith(
      selectedCategory: category,
      isLoadingItems: true,
      error: null,
    );
    try {
      final items = await _repository.getCategoryItems(category.id);
      state = state.copyWith(
        items: items,
        isLoadingItems: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingItems: false,
        error: e.toString(),
      );
    }
  }

  Future<void> retryItems() async {
    final category = state.selectedCategory;
    if (category == null) return;
    await selectCategory(category);
  }

  Future<bool> updateMaxWeight({
    required double maxWeight,
    required String weightUnit,
    required int bagTypeId,
  }) async {
    try {
      await _repository.updateMaxWeight(
        maxWeight: maxWeight,
        weightUnit: weightUnit,
        bagTypeId: bagTypeId,
      );
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> reload() async {
    await _loadInitialData();
  }

  Future<bool> setTravelDate({
    required int bagTypeId,
    required String date,
    required String time,
    String? timezone,
  }) async {
    try {
      await _repository.setTravelDate(
        bagTypeId: bagTypeId,
        date: date,
        time: time,
        timezone: timezone,
      );
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBagReminder({
    required int bagTypeId,
  }) async {
    try {
      return await _repository.getBagReminder(bagTypeId: bagTypeId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBagItems({
    required int bagTypeId,
  }) async {
    try {
      return await _repository.getBagItems(bagTypeId: bagTypeId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
  
  /// Create a new bag using Smart Bags API
  Future<BagDetailModel?> createBag({
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
      await loadBagDetails();
      return bag;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
  
  /// Update bag using Smart Bags API
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
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
  
  /// Delete bag using Smart Bags API
  Future<bool> deleteBag(int bagId) async {
    try {
      await _repository.deleteBag(bagId);
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
  
  /// Update item
  Future<bool> updateItem({
    required int bagId,
    required int itemId,
    String? name,
    double? weight,
    int? itemCategoryId,
    int? quantity,
    bool? essential,
    bool? packed,
    String? notes,
  }) async {
    try {
      await _repository.updateItem(
        bagId: bagId,
        itemId: itemId,
        name: name,
        weight: weight,
        itemCategoryId: itemCategoryId,
        quantity: quantity,
        essential: essential,
        packed: packed,
        notes: notes,
      );
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Toggle item packed status
  Future<bool> toggleItemPacked({
    required int bagId,
    required int itemId,
  }) async {
    try {
      await _repository.toggleItemPacked(bagId: bagId, itemId: itemId);
      await loadBagDetails();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
  
  /// Analyze bag with AI
  Future<Map<String, dynamic>?> analyzeBag({
    required int bagId,
    Map<String, dynamic>? preferences,
    bool? forceReanalysis,
  }) async {
    try {
      final analysis = await _repository.analyzeBag(
        bagId: bagId,
        preferences: preferences,
        forceReanalysis: forceReanalysis,
      );
      await loadBagDetails();
      return analysis;
    } on ApiException catch (e) {
      // Re-throw ApiException so the screen can handle it with full error details
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
  
  /// Get latest analysis
  Future<Map<String, dynamic>?> getLatestAnalysis(int bagId) async {
    try {
      return await _repository.getLatestAnalysis(bagId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get analysis history
  Future<List<Map<String, dynamic>>> getAnalysisHistory({
    required int bagId,
    int? perPage,
  }) async {
    try {
      return await _repository.getAnalysisHistory(bagId: bagId, perPage: perPage);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Get smart alert
  Future<Map<String, dynamic>?> getSmartAlert(int bagId) async {
    try {
      return await _repository.getSmartAlert(bagId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
  
  /// Get bag detail by ID
  Future<BagDetailModel> getBagDetailById(int bagId) async {
    try {
      return await _repository.getBagDetailById(bagId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final bagControllerProvider =
    NotifierProvider<BagNotifier, BagState>(BagNotifier.new);

