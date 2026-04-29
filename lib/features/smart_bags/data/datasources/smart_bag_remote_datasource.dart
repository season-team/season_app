import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_analysis_model.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_item_model.dart';
import 'package:season_app/features/smart_bags/data/models/smart_bag_model.dart';

class SmartBagRemoteDataSource {
  final Dio dio;

  SmartBagRemoteDataSource(this.dio);

  /// Get all bags with filters
  /// GET /api/smart-bags
  Future<Map<String, dynamic>> getBags({
    String? status,
    String? tripType,
    bool? upcoming,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (tripType != null) queryParams['trip_type'] = tripType;
    if (upcoming != null) queryParams['upcoming'] = upcoming;
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (sortOrder != null) queryParams['sort_order'] = sortOrder;
    if (perPage != null) queryParams['per_page'] = perPage;
    if (page != null) queryParams['page'] = page;

    final response = await dio.get(
      ApiEndpoints.smartBags,
      queryParameters: queryParams,
    );

    final data = response.data['data'] as List<dynamic>;
    final pagination = response.data['pagination'] as Map<String, dynamic>?;

    return {
      'bags': data.map((json) => SmartBagModel.fromJson(json as Map<String, dynamic>)).toList(),
      'pagination': pagination,
    };
  }

  /// Create a new bag
  /// POST /api/smart-bags
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
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'trip_type': tripType,
      'duration': duration,
      'destination': destination,
      'departure_date': departureDate.toIso8601String().split('T')[0],
      'max_weight': maxWeight,
    };

    if (status != null) data['status'] = status;
    if (preferences != null) data['preferences'] = preferences;
    if (items != null) data['items'] = items;

    final response = await dio.post(ApiEndpoints.smartBags, data: data);
    return SmartBagModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get bag details
  /// GET /api/smart-bags/{id}
  Future<Map<String, dynamic>> getBagDetails(int bagId) async {
    final endpoint = ApiEndpoints.smartBagById.replaceAll('{id}', bagId.toString());
    final response = await dio.get(endpoint);
    final data = response.data['data'] as Map<String, dynamic>;
    
    return {
      'bag': SmartBagModel.fromJson(data),
      'items': (data['items'] as List<dynamic>?)
              ?.map((item) => SmartBagItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      'latest_analysis': data['latest_analysis'] != null
          ? SmartBagAnalysisModel.fromJson(data['latest_analysis'] as Map<String, dynamic>)
          : null,
    };
  }

  /// Update bag
  /// PUT /api/smart-bags/{id}
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
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (tripType != null) data['trip_type'] = tripType;
    if (duration != null) data['duration'] = duration;
    if (destination != null) data['destination'] = destination;
    if (departureDate != null) {
      data['departure_date'] = departureDate.toIso8601String().split('T')[0];
    }
    if (maxWeight != null) data['max_weight'] = maxWeight;
    if (status != null) data['status'] = status;
    if (preferences != null) data['preferences'] = preferences;

    final endpoint = ApiEndpoints.smartBagById.replaceAll('{id}', bagId.toString());
    final response = await dio.put(endpoint, data: data);
    return SmartBagModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Delete bag
  /// DELETE /api/smart-bags/{id}
  Future<void> deleteBag(int bagId) async {
    final endpoint = ApiEndpoints.smartBagById.replaceAll('{id}', bagId.toString());
    await dio.delete(endpoint);
  }

  /// Add item to bag
  /// POST /api/smart-bags/{bagId}/items
  Future<SmartBagItemModel> addItemToBag({
    required int bagId,
    required String name,
    required double weight,
    required String category,
    bool? essential,
    bool? packed,
    int? quantity,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'weight': weight,
      'category': category,
    };

    if (essential != null) data['essential'] = essential;
    if (packed != null) data['packed'] = packed;
    if (quantity != null) data['quantity'] = quantity;
    if (notes != null) data['notes'] = notes;

    final endpoint = ApiEndpoints.smartBagItems.replaceAll('{id}', bagId.toString());
    final response = await dio.post(endpoint, data: data);
    return SmartBagItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Update item
  /// PUT /api/smart-bags/{bagId}/items/{itemId}
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
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (weight != null) data['weight'] = weight;
    if (category != null) data['category'] = category;
    if (essential != null) data['essential'] = essential;
    if (packed != null) data['packed'] = packed;
    if (quantity != null) data['quantity'] = quantity;
    if (notes != null) data['notes'] = notes;

    final endpoint = ApiEndpoints.smartBagItemById
        .replaceAll('{bagId}', bagId.toString())
        .replaceAll('{itemId}', itemId.toString());
    final response = await dio.put(endpoint, data: data);
    return SmartBagItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Delete item
  /// DELETE /api/smart-bags/{bagId}/items/{itemId}
  Future<void> deleteItem({
    required int bagId,
    required int itemId,
  }) async {
    final endpoint = ApiEndpoints.smartBagItemById
        .replaceAll('{bagId}', bagId.toString())
        .replaceAll('{itemId}', itemId.toString());
    await dio.delete(endpoint);
  }

  /// Toggle item packed status
  /// POST /api/smart-bags/{bagId}/items/{itemId}/toggle-packed
  Future<SmartBagItemModel> toggleItemPacked({
    required int bagId,
    required int itemId,
  }) async {
    final endpoint = ApiEndpoints.smartBagTogglePacked
        .replaceAll('{bagId}', bagId.toString())
        .replaceAll('{itemId}', itemId.toString());
    final response = await dio.post(endpoint);
    return SmartBagItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Analyze bag with AI
  /// POST /api/smart-bags/{id}/analyze
  Future<SmartBagAnalysisModel> analyzeBag({
    required int bagId,
    Map<String, dynamic>? preferences,
    bool? forceReanalysis,
  }) async {
    final data = <String, dynamic>{};
    if (preferences != null) data['preferences'] = preferences;
    if (forceReanalysis != null) data['force_reanalysis'] = forceReanalysis;

    final endpoint = ApiEndpoints.smartBagAnalyze.replaceAll('{id}', bagId.toString());
    debugPrint('🤖 [ANALYZE API] Request to: $endpoint');
    debugPrint('🤖 [ANALYZE API] Request data: $data');
    
    // AI analysis can take longer, so increase timeout to 120 seconds
    final response = await dio.post(
      endpoint,
      data: data,
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    
    debugPrint('🤖 [ANALYZE API] Response status: ${response.statusCode}');
    debugPrint('🤖 [ANALYZE API] Full response: ${response.data}');
    debugPrint('🤖 [ANALYZE API] Response data: ${response.data['data']}');
    
    return SmartBagAnalysisModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get latest analysis
  /// GET /api/smart-bags/{id}/analysis/latest
  Future<SmartBagAnalysisModel?> getLatestAnalysis(int bagId) async {
    try {
      final endpoint = ApiEndpoints.smartBagAnalysisLatest.replaceAll('{id}', bagId.toString());
      final response = await dio.get(endpoint);
      if (response.data['data'] == null) return null;
      return SmartBagAnalysisModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Get analysis history
  /// GET /api/smart-bags/{id}/analysis/history
  Future<List<SmartBagAnalysisModel>> getAnalysisHistory(int bagId) async {
    final endpoint = ApiEndpoints.smartBagAnalysisHistory.replaceAll('{id}', bagId.toString());
    final response = await dio.get(endpoint);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => SmartBagAnalysisModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get smart alert
  /// GET /api/smart-bags/{id}/smart-alert
  Future<Map<String, dynamic>?> getSmartAlert(int bagId) async {
    try {
      final endpoint = ApiEndpoints.smartBagSmartAlert.replaceAll('{id}', bagId.toString());
      final response = await dio.get(endpoint);
      return response.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}

