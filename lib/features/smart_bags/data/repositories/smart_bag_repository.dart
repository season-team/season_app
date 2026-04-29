import 'package:season_app/features/smart_bags/data/datasources/smart_bag_remote_datasource.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_analysis_model.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_item_model.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_model.dart';

class SmartBagRepository {
  final SmartBagRemoteDataSource remoteDataSource;

  SmartBagRepository(this.remoteDataSource);

  Future<Map<String, dynamic>> getBags({
    String? status,
    String? tripType,
    bool? upcoming,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) =>
      remoteDataSource.getBags(
        status: status,
        tripType: tripType,
        upcoming: upcoming,
        sortBy: sortBy,
        sortOrder: sortOrder,
        perPage: perPage,
        page: page,
      );

  Future<SmartBagModel> createBag({
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

  Future<Map<String, dynamic>> getBagDetails(int bagId) =>
      remoteDataSource.getBagDetails(bagId);

  Future<SmartBagModel> updateBag({
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

  Future<SmartBagItemModel> addItemToBag({
    required int bagId,
    required String name,
    required double weight,
    required String category,
    bool? essential,
    bool? packed,
    int? quantity,
    String? notes,
  }) =>
      remoteDataSource.addItemToBag(
        bagId: bagId,
        name: name,
        weight: weight,
        category: category,
        essential: essential,
        packed: packed,
        quantity: quantity,
        notes: notes,
      );

  Future<SmartBagItemModel> updateItem({
    required int bagId,
    required int itemId,
    String? name,
    double? weight,
    String? category,
    bool? essential,
    bool? packed,
    int? quantity,
    String? notes,
  }) =>
      remoteDataSource.updateItem(
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

  Future<void> deleteItem({
    required int bagId,
    required int itemId,
  }) =>
      remoteDataSource.deleteItem(bagId: bagId, itemId: itemId);

  Future<SmartBagItemModel> toggleItemPacked({
    required int bagId,
    required int itemId,
  }) =>
      remoteDataSource.toggleItemPacked(bagId: bagId, itemId: itemId);

  Future<SmartBagAnalysisModel> analyzeBag({
    required int bagId,
    Map<String, dynamic>? preferences,
    bool? forceReanalysis,
  }) =>
      remoteDataSource.analyzeBag(
        bagId: bagId,
        preferences: preferences,
        forceReanalysis: forceReanalysis,
      );

  Future<SmartBagAnalysisModel?> getLatestAnalysis(int bagId) =>
      remoteDataSource.getLatestAnalysis(bagId);

  Future<List<SmartBagAnalysisModel>> getAnalysisHistory(int bagId) =>
      remoteDataSource.getAnalysisHistory(bagId);

  Future<Map<String, dynamic>?> getSmartAlert(int bagId) =>
      remoteDataSource.getSmartAlert(bagId);
}

