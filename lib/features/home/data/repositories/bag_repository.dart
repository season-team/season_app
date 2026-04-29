import 'package:season_app/features/home/data/datasources/bag_remote_datasource.dart';
import 'package:season_app/features/home/data/models/ai_category_model.dart';
import 'package:season_app/features/home/data/models/ai_item_model.dart';
import 'package:season_app/features/home/data/models/bag_category_model.dart';
import 'package:season_app/features/home/data/models/bag_detail_model.dart';
import 'package:season_app/features/home/data/models/bag_item_model.dart';
import 'package:season_app/features/home/data/models/bag_type_model.dart';

class BagRepository {
  final BagRemoteDataSource remoteDataSource;

  BagRepository(this.remoteDataSource);

  Future<List<BagTypeModel>> getBagTypes() => remoteDataSource.getBagTypes();

  Future<List<BagCategoryModel>> getCategories() =>
      remoteDataSource.getCategories();

  Future<BagCategoryModel> getCategoryById(int categoryId) =>
      remoteDataSource.getCategoryById(categoryId);

  Future<List<BagItemModel>> getCategoryItems(int categoryId) =>
      remoteDataSource.getCategoryItems(categoryId);

  Future<List<BagDetailModel>> getBagDetails({
    String? status,
    String? tripType,
    bool? upcoming,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) =>
      remoteDataSource.getBagDetails(
        status: status,
        tripType: tripType,
        upcoming: upcoming,
        sortBy: sortBy,
        sortOrder: sortOrder,
        perPage: perPage,
        page: page,
      );
  
  Future<BagDetailModel> getBagDetailById(int bagId) =>
      remoteDataSource.getBagDetailById(bagId);
  
  Future<BagDetailModel> createBag({
    required String name,
    required String tripType,
    required int duration,
    required String destination,
    required DateTime departureDate,
    required double maxWeight,
    String? status,
    Map<String, dynamic>? preferences,
    List<Map<String, dynamic>>? items,
  }) =>
      remoteDataSource.createBag(
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
  
  Future<BagDetailModel> updateBag({
    required int bagId,
    String? name,
    String? tripType,
    int? duration,
    String? destination,
    DateTime? departureDate,
    double? maxWeight,
    String? status,
    Map<String, dynamic>? preferences,
  }) =>
      remoteDataSource.updateBag(
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
  
  Future<void> deleteBag(int bagId) => remoteDataSource.deleteBag(bagId);

  Future<void> addItemToBag({
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
  }) =>
      remoteDataSource.addItemToBag(
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
  
  Future<void> updateItem({
    required int bagId,
    required int itemId,
    String? name,
    double? weight,
    int? itemCategoryId,
    int? quantity,
    bool? essential,
    bool? packed,
    String? notes,
  }) =>
      remoteDataSource.updateItem(
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

  Future<void> toggleItemPacked({
    required int bagId,
    required int itemId,
  }) =>
      remoteDataSource.toggleItemPacked(bagId: bagId, itemId: itemId);
  
  Future<Map<String, dynamic>> analyzeBag({
    required int bagId,
    Map<String, dynamic>? preferences,
    bool? forceReanalysis,
  }) =>
      remoteDataSource.analyzeBag(
        bagId: bagId,
        preferences: preferences,
        forceReanalysis: forceReanalysis,
      );
  
  Future<Map<String, dynamic>?> getLatestAnalysis(int bagId) =>
      remoteDataSource.getLatestAnalysis(bagId);

  Future<List<Map<String, dynamic>>> getAnalysisHistory({
    required int bagId,
    int? perPage,
  }) =>
      remoteDataSource.getAnalysisHistory(bagId: bagId, perPage: perPage);

  Future<Map<String, dynamic>?> getSmartAlert(int bagId) =>
      remoteDataSource.getSmartAlert(bagId);

  Future<void> deleteItemFromBag({
    required int itemId,
    required int bagTypeId,
    int? quantity,
  }) =>
      remoteDataSource.deleteItemFromBag(
        itemId: itemId,
        bagTypeId: bagTypeId,
        quantity: quantity,
      );

  Future<void> updateItemQuantity({
    required int itemId,
    required int bagTypeId,
    required int quantity,
  }) =>
      remoteDataSource.updateItemQuantity(
        itemId: itemId,
        bagTypeId: bagTypeId,
        quantity: quantity,
      );

  Future<void> updateMaxWeight({
    required double maxWeight,
    required String weightUnit,
    required int bagTypeId,
  }) =>
      remoteDataSource.updateMaxWeight(
        maxWeight: maxWeight,
        weightUnit: weightUnit,
        bagTypeId: bagTypeId,
      );

  Future<Map<String, dynamic>> setTravelDate({
    required int bagTypeId,
    required String date,
    required String time,
    String? timezone,
  }) =>
      remoteDataSource.setTravelDate(
        bagTypeId: bagTypeId,
        date: date,
        time: time,
        timezone: timezone,
      );

  Future<Map<String, dynamic>> getBagReminder({
    required int bagTypeId,
  }) =>
      remoteDataSource.getBagReminder(bagTypeId: bagTypeId);

  Future<Map<String, dynamic>> getBagItems({
    required int bagTypeId,
  }) =>
      remoteDataSource.getBagItems(bagTypeId: bagTypeId);

  Future<List<AICategoryModel>> getAICategories() =>
      remoteDataSource.getAICategories();

  Future<List<AIItemModel>> getAISuggestedItems(String categoryName) =>
      remoteDataSource.getAISuggestedItems(categoryName);

  Future<Map<String, dynamic>> addAIItemToBag({
    required int bagId,
    required String itemName,
    required double weight,
    bool? essential,
    int? quantity,
  }) =>
      remoteDataSource.addAIItemToBag(
        bagId: bagId,
        itemName: itemName,
        weight: weight,
        essential: essential,
        quantity: quantity,
      );

  Future<Map<String, dynamic>> estimateWeight(String customItemName) =>
      remoteDataSource.estimateWeight(customItemName);
}

