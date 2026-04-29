import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/features/home/data/models/ai_category_model.dart';
import 'package:season_app/features/home/data/models/ai_item_model.dart';
import 'package:season_app/features/home/data/models/bag_category_model.dart';
import 'package:season_app/features/home/data/models/bag_detail_model.dart';
import 'package:season_app/features/home/data/models/bag_item_model.dart';
import 'package:season_app/features/home/data/models/bag_type_model.dart';

class BagRemoteDataSource {
  final Dio dio;

  BagRemoteDataSource(this.dio);

  Future<List<BagTypeModel>> getBagTypes() async {
    final response = await dio.get(ApiEndpoints.bagTypes);
    final data = _extractList(response.data);
    return data.map((json) => BagTypeModel.fromJson(json)).toList();
  }

  /// Get all item categories using Smart Bags API
  /// GET /api/item-categories
  Future<List<BagCategoryModel>> getCategories() async {
    try {
      // Try new endpoint first
      final response = await dio.get(ApiEndpoints.itemCategories);
      final data = _extractList(response.data);
      return data.map((json) => BagCategoryModel.fromJson(json)).toList();
    } catch (e) {
      // Fallback to legacy endpoint
      debugPrint('⚠️ item-categories endpoint failed, trying legacy endpoint: $e');
      final response = await dio.get(ApiEndpoints.itemsCategories);
      final data = _extractList(response.data);
      return data.map((json) => BagCategoryModel.fromJson(json)).toList();
    }
  }

  /// Get single item category using Smart Bags API
  /// GET /api/item-categories/{id}
  Future<BagCategoryModel> getCategoryById(int categoryId) async {
    final endpoint = ApiEndpoints.itemCategoryById.replaceAll('{id}', categoryId.toString());
    final response = await dio.get(endpoint);
    final data = response.data['data'] as Map<String, dynamic>;
    return BagCategoryModel.fromJson(data);
  }

  /// Get items by category ID using the new API
  /// GET /api/items?category_id={categoryId}
  Future<List<BagItemModel>> getCategoryItems(int categoryId) async {
    final response = await dio.get(
      ApiEndpoints.items,
      queryParameters: {'category_id': categoryId},
    );
    final data = _extractList(response.data);
    return data.map((json) => BagItemModel.fromJson(json)).toList();
  }

  /// Get all bags using Smart Bags API
  /// GET /api/smart-bags
  Future<List<BagDetailModel>> getBagDetails({
    String? status,
    String? tripType,
    bool? upcoming,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) async {
    try {
      // Use Smart Bags API only - don't fallback to broken legacy endpoint
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (tripType != null) queryParams['trip_type'] = tripType;
      if (upcoming != null) queryParams['upcoming'] = upcoming;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (perPage != null) queryParams['per_page'] = perPage;
      if (page != null) queryParams['page'] = page;

      debugPrint('🚀 REQUEST[GET] => PATH: ${ApiEndpoints.smartBags}');
      debugPrint('   Query Parameters: $queryParams');
      
      final response = await dio.get(
        ApiEndpoints.smartBags,
        queryParameters: queryParams,
      );
      
      debugPrint('✅ RESPONSE[${response.statusCode}] => PATH: ${ApiEndpoints.smartBags}');
      debugPrint('   Response data: ${response.data}');
      
      // Handle response structure
      List<dynamic> data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data')) {
          data = responseMap['data'] as List<dynamic>? ?? [];
        } else {
          debugPrint('⚠️ Response does not contain "data" key');
          data = [];
        }
      } else if (response.data is List) {
        data = response.data as List<dynamic>;
      } else {
        debugPrint('⚠️ Unexpected response format: ${response.data.runtimeType}');
        data = [];
      }
      
      debugPrint('📦 Parsed ${data.length} bags from response');
      
      final bags = data.map((json) {
        try {
          return BagDetailModel.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('❌ Error parsing bag: $e');
          debugPrint('   Bag JSON: $json');
          rethrow;
        }
      }).toList();
      
      debugPrint('✅ Successfully parsed ${bags.length} bags');
      return bags;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching bags from Smart Bags API: $e');
      debugPrint('   Stack trace: $stackTrace');
      // Don't fallback to broken legacy endpoint - just return empty list
      // The error will be handled by the provider
      rethrow;
    }
  }
  
  /// Get bag details by ID using Smart Bags API
  /// GET /api/smart-bags/{id}
  Future<BagDetailModel> getBagDetailById(int bagId) async {
    final endpoint = ApiEndpoints.smartBagById.replaceAll('{id}', bagId.toString());
    debugPrint('🔍 Fetching bag detail: $endpoint');
    final response = await dio.get(endpoint);
    debugPrint('📦 Bag detail response: ${response.data}');
    final data = response.data['data'] as Map<String, dynamic>;
    return BagDetailModel.fromJson(data);
  }
  
  /// Create a new bag using Smart Bags API
  /// POST /api/smart-bags
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
    return BagDetailModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
  
  /// Update bag using Smart Bags API
  /// PUT /api/smart-bags/{id}
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
    return BagDetailModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
  
  /// Delete bag using Smart Bags API
  /// DELETE /api/smart-bags/{id}
  Future<void> deleteBag(int bagId) async {
    final endpoint = ApiEndpoints.smartBagById.replaceAll('{id}', bagId.toString());
    await dio.delete(endpoint);
  }

  /// Add item to bag using Smart Bags API
  /// POST /api/smart-bags/{bagId}/items
  Future<void> addItemToBag({
    int? itemId,
    required int bagTypeId, // This will be bagId for Smart Bags
    required int quantity,
    String? customItemName,
    double? customWeight,
    String? weightUnit,
    int? itemCategoryId, // Use item_category_id instead of category string
    String? category, // Deprecated - kept for backward compatibility
    bool? essential,
    bool? packed,
    String? notes,
  }) async {
    // Try Smart Bags API first (use bagTypeId as bagId)
    try {
      final data = <String, dynamic>{
        'quantity': quantity,
      };
      
      // Set item name (required for Smart Bags API)
      if (customItemName != null && customItemName.trim().isNotEmpty) {
        data['name'] = customItemName.trim();
      } else {
        throw Exception('Item name is required');
      }
      
      // Convert weight to kg if unit is grams
      double weightToSend = customWeight ?? 0.0;
      if (customWeight != null && weightUnit != null) {
        final unit = weightUnit.toLowerCase().trim();
        if (unit == 'g' || unit == 'gram' || unit == 'grams') {
          // Convert grams to kg
          weightToSend = customWeight / 1000.0;
        }
      }
      
      // Weight is required for Smart Bags API
      if (weightToSend > 0) {
        data['weight'] = weightToSend;
      } else if (customWeight != null && customWeight > 0) {
        data['weight'] = customWeight;
      } else {
        throw Exception('Item weight is required');
      }
      
      // item_category_id is required for Smart Bags API
      if (itemCategoryId != null) {
        data['item_category_id'] = itemCategoryId;
      } else {
        throw Exception('Item category is required');
      }
      
      // Optional fields
      if (essential != null) data['essential'] = essential;
      if (packed != null) data['packed'] = packed;
      if (notes != null && notes.trim().isNotEmpty) data['notes'] = notes.trim();
      
      debugPrint('📦 Adding item to bag: $data');
      
      final endpoint = ApiEndpoints.smartBagItems.replaceAll('{id}', bagTypeId.toString());
      final response = await dio.post(endpoint, data: data);
      
      debugPrint('✅ Item added successfully: ${response.data}');
      return;
    } catch (e) {
      debugPrint('❌ Smart Bags API failed: $e');
      rethrow;
    }
  }

  /// Delete item from bag using Smart Bags API
  /// DELETE /api/smart-bags/{bagId}/items/{itemId}
  Future<void> deleteItemFromBag({
    required int itemId,
    required int bagTypeId, // This will be bagId for Smart Bags
    int? quantity,
  }) async {
    final endpoint = ApiEndpoints.smartBagItemById
        .replaceAll('{bagId}', bagTypeId.toString())
        .replaceAll('{itemId}', itemId.toString());
    debugPrint('🗑️ Deleting item: $endpoint');
    await dio.delete(endpoint);
    debugPrint('✅ Item deleted successfully');
  }
  
  /// Update item using Smart Bags API
  /// PUT /api/smart-bags/{bagId}/items/{itemId}
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
  }) async {
    final data = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) data['name'] = name.trim();
    if (weight != null && weight > 0) data['weight'] = weight;
    if (itemCategoryId != null) data['item_category_id'] = itemCategoryId;
    if (quantity != null && quantity > 0) data['quantity'] = quantity;
    if (essential != null) data['essential'] = essential;
    if (packed != null) data['packed'] = packed;
    if (notes != null && notes.trim().isNotEmpty) data['notes'] = notes.trim();

    final endpoint = ApiEndpoints.smartBagItemById
        .replaceAll('{bagId}', bagId.toString())
        .replaceAll('{itemId}', itemId.toString());
    
    debugPrint('✏️ Updating item: $endpoint with data: $data');
    await dio.put(endpoint, data: data);
    debugPrint('✅ Item updated successfully');
  }

  /// Toggle item packed status using Smart Bags API
  /// POST /api/smart-bags/{bagId}/items/{itemId}/toggle-packed
  Future<void> toggleItemPacked({
    required int bagId,
    required int itemId,
  }) async {
    final endpoint = ApiEndpoints.smartBagTogglePacked
        .replaceAll('{bagId}', bagId.toString())
        .replaceAll('{itemId}', itemId.toString());
    await dio.post(endpoint);
  }
  
  /// Analyze bag with AI using Smart Bags API
  /// POST /api/smart-bags/{id}/analyze
  Future<Map<String, dynamic>> analyzeBag({
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
    
    return response.data['data'] as Map<String, dynamic>;
  }
  
  /// Get latest analysis using Smart Bags API
  /// GET /api/smart-bags/{bagId}/analysis/latest
  Future<Map<String, dynamic>?> getLatestAnalysis(int bagId) async {
    try {
      final endpoint = ApiEndpoints.smartBagAnalysisLatest.replaceAll('{id}', bagId.toString());
      debugPrint('📊 Fetching latest analysis: $endpoint');
      final response = await dio.get(endpoint);
      debugPrint('📊 Latest analysis response: ${response.data}');
      return response.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('⚠️ No latest analysis found: $e');
      return null;
    }
  }

  /// Get analysis history using Smart Bags API
  /// GET /api/smart-bags/{bagId}/analysis/history
  Future<List<Map<String, dynamic>>> getAnalysisHistory({
    required int bagId,
    int? perPage,
  }) async {
    try {
      final endpoint = ApiEndpoints.smartBagAnalysisHistory.replaceAll('{id}', bagId.toString());
      final queryParams = <String, dynamic>{};
      if (perPage != null) queryParams['per_page'] = perPage;
      
      debugPrint('📜 Fetching analysis history: $endpoint');
      final response = await dio.get(endpoint, queryParameters: queryParams);
      debugPrint('📜 Analysis history response: ${response.data}');
      
      final data = response.data['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ Error fetching analysis history: $e');
      return [];
    }
  }

  /// Get smart alert using Smart Bags API
  /// GET /api/smart-bags/{id}/smart-alert
  Future<Map<String, dynamic>?> getSmartAlert(int bagId) async {
    try {
      final endpoint = ApiEndpoints.smartBagSmartAlert.replaceAll('{id}', bagId.toString());
      debugPrint('🚨 Fetching smart alert: $endpoint');
      final response = await dio.get(endpoint);
      debugPrint('🚨 Smart alert response: ${response.data}');
      return response.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('⚠️ No smart alert found: $e');
      return null;
    }
  }

  Future<void> updateItemQuantity({
    required int itemId,
    required int bagTypeId,
    required int quantity,
  }) async {
    final endpoint = ApiEndpoints.bagUpdateItemQuantity.replaceAll('{item_id}', itemId.toString());
    await dio.put(
      endpoint,
      data: {
        'bag_type_id': bagTypeId,
        'quantity': quantity,
      },
    );
  }

  Future<void> updateMaxWeight({
    required double maxWeight,
    required String weightUnit,
    required int bagTypeId,
  }) async {
    await dio.put(
      ApiEndpoints.bagUpdateMaxWeight,
      data: {
        'max_weight': maxWeight,
        'weight_unit': weightUnit,
        'bag_type_id': bagTypeId,
      },
    );
  }

  Future<Map<String, dynamic>> setTravelDate({
    required int bagTypeId,
    required String date,
    required String time,
    String? timezone,
  }) async {
    final response = await dio.post(
      ApiEndpoints.bagTravelDate,
      data: {
        'bag_type_id': bagTypeId,
        'date': date,
        'time': time,
        'timezone': timezone ?? 'Africa/Cairo', // Default to Africa/Cairo if not provided
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBagReminder({
    required int bagTypeId,
  }) async {
    final response = await dio.get(
      ApiEndpoints.bagReminder,
      queryParameters: {'bag_type_id': bagTypeId},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBagItems({
    required int bagTypeId,
  }) async {
    final response = await dio.get(
      ApiEndpoints.bagItems,
      queryParameters: {'bag_type_id': bagTypeId},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get AI categories using Smart Bags API
  /// GET /api/smart-bags/ai/categories
  Future<List<AICategoryModel>> getAICategories() async {
    try {
      final response = await dio.get(ApiEndpoints.aiCategories);
      debugPrint('🤖 [AI Categories] Response: ${response.data}');
      
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        return [];
      }
      
      final categories = data['categories'] as List<dynamic>? ?? [];
      return categories
          .map((json) => AICategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching AI categories: $e');
      rethrow;
    }
  }

  /// Get AI suggested items for a category
  /// GET /api/smart-bags/ai/suggest-items?category={categoryName}
  Future<List<AIItemModel>> getAISuggestedItems(String categoryName) async {
    try {
      final response = await dio.get(
        ApiEndpoints.aiSuggestItems,
        queryParameters: {'category': categoryName},
      );
      debugPrint('🤖 [AI Items] Response: ${response.data}');
      
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        return [];
      }
      
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((json) => AIItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching AI suggested items: $e');
      rethrow;
    }
  }

  /// Add AI item to bag using Smart Bags API
  /// POST /api/smart-bags/{bagId}/ai/add-item
  Future<Map<String, dynamic>> addAIItemToBag({
    required int bagId,
    required String itemName,
    required double weight, // in kg
    bool? essential,
    int? quantity,
  }) async {
    try {
      final data = <String, dynamic>{
        'item_name': itemName,
        'weight': weight,
      };
      
      if (essential != null) data['essential'] = essential;
      if (quantity != null && quantity > 0) data['quantity'] = quantity;
      
      final endpoint = ApiEndpoints.aiAddItem.replaceAll('{bagId}', bagId.toString());
      debugPrint('🤖 [AI Add Item] Request to: $endpoint');
      debugPrint('🤖 [AI Add Item] Data: $data');
      
      final response = await dio.post(endpoint, data: data);
      debugPrint('✅ [AI Add Item] Response: ${response.data}');
      
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error adding AI item to bag: $e');
      rethrow;
    }
  }

  /// Estimate weight for custom item using AI
  /// POST /api/travel-bag/estimate-weight
  Future<Map<String, dynamic>> estimateWeight(String customItemName) async {
    try {
      final data = <String, dynamic>{
        'custom_item_name': customItemName,
      };
      
      debugPrint('🤖 [Estimate Weight] Request to: ${ApiEndpoints.bagEstimateWeight}');
      debugPrint('🤖 [Estimate Weight] Data: $data');
      
      final response = await dio.post(ApiEndpoints.bagEstimateWeight, data: data);
      debugPrint('✅ [Estimate Weight] Response: ${response.data}');
      
      // Return the data object from response
      final responseData = response.data['data'] as Map<String, dynamic>;
      return responseData;
    } catch (e) {
      debugPrint('❌ Error estimating weight: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    } else if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    }
    return [];
  }
}

