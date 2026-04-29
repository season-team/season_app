import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/features/home/data/models/bag_category_model.dart';
import 'package:season_app/features/home/data/models/bag_detail_model.dart';
import 'package:season_app/features/home/providers/bag_providers.dart';
import 'package:season_app/shared/widgets/custom_toast.dart';

class BagAnalysisScreen extends ConsumerStatefulWidget {
  final int bagId;
  final Map<String, dynamic> analysisData;

  const BagAnalysisScreen({
    super.key,
    required this.bagId,
    required this.analysisData,
  });

  @override
  ConsumerState<BagAnalysisScreen> createState() => _BagAnalysisScreenState();
}

class _BagAnalysisScreenState extends ConsumerState<BagAnalysisScreen> {
  final Set<String> _processedItems = {}; // Track processed items to avoid duplicates
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;
  bool _needsAnalysis = false;
  bool _forceReanalysis = false;

  @override
  void initState() {
    super.initState();
    // Check if we need to perform analysis
    final hasValidData = widget.analysisData.isNotEmpty && 
        (widget.analysisData.containsKey('data') || 
         widget.analysisData.containsKey('missing_items') ||
         widget.analysisData.containsKey('extra_items'));
    
    if (!hasValidData) {
      // Check if forceReanalysis flag was passed
      _forceReanalysis = widget.analysisData['forceReanalysis'] == true;
      _needsAnalysis = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performAnalysis();
      });
    } else {
      _analysisResult = widget.analysisData;
    }
  }

  Future<void> _performAnalysis({bool forceReanalysis = false}) async {
    if (!mounted) return;
    
    debugPrint('🔵 [ANALYSIS] Starting analysis for bag ${widget.bagId}');
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _needsAnalysis = true; // Set to true when starting
      _errorMessage = null;
    });

    try {
      final analysis = await ref.read(bagControllerProvider.notifier).analyzeBag(
        bagId: widget.bagId,
        forceReanalysis: forceReanalysis || _forceReanalysis,
      );

      debugPrint('🔵 [ANALYSIS] Analysis completed, result: ${analysis != null}');

      if (!mounted) return;

      if (analysis != null) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _needsAnalysis = false;
          _analysisResult = analysis;
        });
      } else {
        // If analysis is null, check provider error state
        final bagState = ref.read(bagControllerProvider);
        final errorMsg = bagState.error ?? 'Failed to analyze bag';
        debugPrint('🔵 [ANALYSIS] Analysis returned null, error: $errorMsg');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _needsAnalysis = false;
            _errorMessage = errorMsg;
          });
        }
      }
    } on ApiException catch (e) {
      debugPrint('🔴 [ANALYSIS] ApiException caught! Status: ${e.statusCode}');
      if (!mounted) return;

      final isRtl = Directionality.of(context) == TextDirection.rtl;
      
      // Check if it's a 422 error about recent analysis (handle this first)
      if (e.statusCode == 422 && 
          (e.message.toLowerCase().contains('analyzed recently') || 
           e.message.toLowerCase().contains('تم تحليل الحقيبة مؤخراً') || 
           e.message.toLowerCase().contains('force_reanalysis'))) {
        // Show dialog asking if user wants to force reanalysis
        final shouldForce = await _showForceReanalysisDialog(e.message);
        if (shouldForce == true && mounted) {
          // Retry with force reanalysis
          await _performAnalysis(forceReanalysis: true);
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _needsAnalysis = false;
              _errorMessage = e.message;
            });
          }
        }
        return;
      }
      
      // Extract response data - check multiple sources
      Map<String, dynamic>? responseDataMap;
      try {
        if (e.responseData is Map) {
          responseDataMap = Map<String, dynamic>.from(e.responseData as Map);
        } else if (e.dioException?.response?.data is Map) {
          responseDataMap = Map<String, dynamic>.from(e.dioException!.response!.data as Map);
        }
      } catch (ex) {
        debugPrint('🔴 [ANALYSIS ERROR] Failed to parse responseData: $ex');
      }
      
      // Debug: Print error details
      debugPrint('🔴 [ANALYSIS ERROR] Status: ${e.statusCode}');
      debugPrint('🔴 [ANALYSIS ERROR] Message: ${e.message}');
      debugPrint('🔴 [ANALYSIS ERROR] responseData type: ${e.responseData?.runtimeType}');
      debugPrint('🔴 [ANALYSIS ERROR] responseData: ${e.responseData}');
      debugPrint('🔴 [ANALYSIS ERROR] dioException response data: ${e.dioException?.response?.data}');
      debugPrint('🔴 [ANALYSIS ERROR] responseDataMap: $responseDataMap');
      
      // Extract error message - prioritize message_ar for Arabic, then message
      String errorMessage = '';
      
      if (responseDataMap != null) {
        // Try message_ar first for Arabic
        if (isRtl && responseDataMap['message_ar'] != null) {
          errorMessage = responseDataMap['message_ar'].toString().trim();
          debugPrint('🔴 [ANALYSIS ERROR] Found message_ar: $errorMessage');
        }
        
        // Fallback to message if message_ar not found or not Arabic
        if (errorMessage.isEmpty && responseDataMap['message'] != null) {
          errorMessage = responseDataMap['message'].toString().trim();
          debugPrint('🔴 [ANALYSIS ERROR] Found message: $errorMessage');
        }
      }
      
      // If still empty, use the exception message or default
      if (errorMessage.isEmpty) {
        errorMessage = e.message;
        // For 500 errors with quota, use default quota message
        if (e.statusCode == 500 && (errorMessage.contains('status code of 500') || errorMessage.contains('Server error'))) {
          errorMessage = isRtl 
              ? 'تم تجاوز الحصة المسموحة لخدمة التحليل ولا يوجد تحليل سابق. يرجى المحاولة لاحقاً.'
              : 'Analysis service quota exceeded and no previous analysis found. Please try again later.';
        }
      }
      
      debugPrint('🔴 [ANALYSIS ERROR] Final errorMessage: $errorMessage');
      
      // Check if it's a quota error (500 with quota message, or 429)
      final isQuota = e.statusCode == 429 || 
                      (e.statusCode == 500 && (
                        errorMessage.toLowerCase().contains('quota') ||
                        errorMessage.toLowerCase().contains('exceeded') ||
                        errorMessage.contains('الحصة') ||
                        errorMessage.contains('تجاوز')
                      ));
      
      // Check if it's a timeout error (504 Gateway Timeout)
      final isTimeout = e.statusCode == 504 || 
                       e.type == ApiExceptionType.gatewayTimeout ||
                       errorMessage.toLowerCase().contains('timeout') ||
                       errorMessage.toLowerCase().contains('انتهت مهلة') ||
                       errorMessage.toLowerCase().contains('time out');
      
      // Try to get latest analysis if quota or timeout error
      if (isQuota || isTimeout) {
        debugPrint('🔴 [ANALYSIS ERROR] ${isQuota ? "Quota" : "Timeout"} error detected, trying to get latest analysis...');
        try {
          final latestAnalysis = await ref.read(bagControllerProvider.notifier).getLatestAnalysis(widget.bagId);
          if (latestAnalysis != null && mounted) {
            debugPrint('🔴 [ANALYSIS ERROR] Found latest analysis, showing it');
            setState(() {
              _isLoading = false;
              _hasError = false;
              _needsAnalysis = false;
              _analysisResult = latestAnalysis;
            });
            CustomToast.info(
              context,
              isRtl 
                  ? (isTimeout 
                      ? 'تم عرض آخر تحليل متاح بسبب انتهاء مهلة الطلب'
                      : 'تم عرض آخر تحليل متاح بسبب تجاوز الحصة')
                  : (isTimeout
                      ? 'Showing last available analysis due to request timeout'
                      : 'Showing last available analysis due to quota limit'),
            );
            return;
          } else {
            debugPrint('🔴 [ANALYSIS ERROR] No latest analysis found');
          }
        } catch (ex) {
          debugPrint('🔴 [ANALYSIS ERROR] Failed to get latest analysis: $ex');
          // Continue to show error
        }
      }
      
      // Show error message - ALWAYS update state
      debugPrint('🔴 [ANALYSIS ERROR] Setting error state with message: $errorMessage');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _needsAnalysis = false; // Important: stop the loading screen
          _errorMessage = errorMessage;
        });
        debugPrint('🔴 [ANALYSIS ERROR] State updated - isLoading: false, hasError: true, needsAnalysis: false, errorMessage: $errorMessage');
      }
      return;
    } catch (e) {
      if (!mounted) return;
      
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      String errorMsg = 'Error during analysis';
      
      // Try to extract error message if it's an ApiException
      if (e is ApiException) {
        Map<String, dynamic>? responseDataMap;
        if (e.responseData is Map) {
          responseDataMap = Map<String, dynamic>.from(e.responseData as Map);
        } else if (e.dioException?.response?.data is Map) {
          responseDataMap = Map<String, dynamic>.from(e.dioException!.response!.data as Map);
        }
        
        if (responseDataMap != null) {
          if (isRtl && responseDataMap['message_ar'] != null) {
            errorMsg = responseDataMap['message_ar'].toString().trim();
          } else if (responseDataMap['message'] != null) {
            errorMsg = responseDataMap['message'].toString().trim();
          } else {
            errorMsg = e.message;
          }
        } else {
          errorMsg = e.message;
        }
      }
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _needsAnalysis = false; // Important: stop the loading screen
        _errorMessage = errorMsg;
      });
    }
  }

  Future<bool?> _showForceReanalysisDialog(String message) async {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRtl ? 'تحليل حديث' : 'Recent Analysis'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isRtl ? 'إعادة التحليل' : 'Re-analyze'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    // Show loading state
    if (_isLoading || _needsAnalysis) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Text(isRtl ? 'تحليل الحقيبة' : 'Bag Analysis'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isRtl ? 'جاري تحليل حقيبتك...' : 'Analyzing your bag...',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRtl 
                        ? 'يرجى الانتظار، نحن نفحص محتويات حقيبتك ونقدم لك أفضل الاقتراحات'
                        : 'Please wait while we analyze your bag contents and provide the best suggestions',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRtl 
                              ? 'قد يستغرق هذا بضع لحظات'
                              : 'This may take a few moments',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show error state
    if (_hasError) {
      final isQuotaError = _errorMessage?.toLowerCase().contains('quota') == true ||
                          _errorMessage?.toLowerCase().contains('exceeded') == true ||
                          _errorMessage?.toLowerCase().contains('الحصة') == true ||
                          _errorMessage?.toLowerCase().contains('تجاوز') == true;
      
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Text(isRtl ? 'تحليل الحقيبة' : 'Bag Analysis'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isQuotaError ? Icons.schedule_rounded : Icons.error_outline_rounded,
                    size: 64,
                    color: isQuotaError ? AppColors.warning : AppColors.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isQuotaError 
                        ? (isRtl ? 'تم تجاوز الحصة المسموحة' : 'Quota Exceeded')
                        : (isRtl ? 'فشل التحليل' : 'Analysis Failed'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? (isRtl ? 'حدث خطأ أثناء تحليل الحقيبة' : 'An error occurred while analyzing the bag'),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isQuotaError) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isRtl 
                                  ? 'يمكنك المحاولة مرة أخرى لاحقاً أو مراجعة آخر تحليل متاح'
                                  : 'You can try again later or review the last available analysis',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (!isQuotaError)
                    ElevatedButton(
                      onPressed: () => _performAnalysis(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text(isRtl ? 'إعادة المحاولة' : 'Retry'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text(isRtl ? 'رجوع' : 'Go Back'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show analysis results
    final analysis = _analysisResult?['data'] ?? _analysisResult ?? {};
    final missingItems = (analysis['missing_items'] as List?) ?? [];
    final extraItems = (analysis['extra_items'] as List?) ?? [];
    final weightOptimization = analysis['weight_optimization'] as Map<String, dynamic>?;
    final additionalSuggestions = (analysis['additional_suggestions'] as List?) ?? [];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(isRtl ? 'تحليل الحقيبة' : 'Bag Analysis'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => _returnToBag(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Missing Items Section (Red-bordered)
                    if (missingItems.isNotEmpty)
                      _buildMissingItemsSection(missingItems, isRtl),
                    
                    if (missingItems.isNotEmpty && extraItems.isNotEmpty)
                      const SizedBox(height: 20),
                    
                    // Optional Items Section (Blue-bordered)
                    if (extraItems.isNotEmpty)
                      _buildOptionalItemsSection(extraItems, isRtl),
                    
                    if ((missingItems.isNotEmpty || extraItems.isNotEmpty) && 
                        (weightOptimization != null || additionalSuggestions.isNotEmpty))
                      const SizedBox(height: 20),
                    
                    // Improvement Suggestions Section (Green-bordered)
                    if (weightOptimization != null || additionalSuggestions.isNotEmpty)
                      _buildImprovementSuggestionsSection(
                        weightOptimization,
                        additionalSuggestions,
                        isRtl,
                      ),
                    
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
            
            // Bottom Action Buttons
            _buildBottomActions(isRtl),
          ],
        ),
      ),
    );
  }

  // Missing Items Section (Red-bordered)
  Widget _buildMissingItemsSection(List missingItems, bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${isRtl ? 'أغراض ناقصة' : 'Missing Items'} (${missingItems.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: missingItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < missingItems.length - 1 ? 16 : 0),
                  child: _buildMissingItemCard(item, isRtl),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItemCard(Map<String, dynamic> item, bool isRtl) {
    final name = item['name'] ?? '';
    final reason = item['reason'] ?? '';
    final priority = item['priority'] ?? 'medium';
    final category = item['category'] ?? '';
    
    final priorityText = priority == 'high' 
        ? (isRtl ? 'مهم جدا' : 'Very Important')
        : priority == 'medium'
            ? (isRtl ? 'مهم' : 'Important')
            : (isRtl ? 'عادي' : 'Normal');
    
    final priorityColor = priority == 'high' 
        ? AppColors.error
        : priority == 'medium'
            ? AppColors.warning
            : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Name and Priority Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: priorityColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  priorityText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          
          // Reason
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              reason,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          
          // Add Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await _addMissingItem(item, isRtl);
                if (mounted && success) {
                  CustomToast.success(
                    context,
                    isRtl ? 'تم إضافة ${item['name']} بنجاح' : '${item['name']} added successfully',
                  );
                  // Refresh bag
                  await ref.read(bagControllerProvider.notifier).loadBagDetails();
                } else if (mounted) {
                  CustomToast.error(
                    context,
                    isRtl ? 'فشل إضافة ${item['name']}' : 'Failed to add ${item['name']}',
                  );
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isRtl ? 'أضف للحقيبة' : 'Add to Bag'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Optional Items Section (Blue-bordered)
  Widget _buildOptionalItemsSection(List extraItems, bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isRtl ? 'يمكن الاستغناء عنها' : 'Optional Items',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: extraItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < extraItems.length - 1 ? 16 : 0),
                  child: _buildOptionalItemCard(item, isRtl),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalItemCard(Map<String, dynamic> item, bool isRtl) {
    final name = item['name'] ?? '';
    final reason = item['reason'] ?? '';
    final weightSaved = item['weight_saved']?.toString() ?? 
        item['weight']?.toString() ?? 
        '0';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Name and Weight Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Weight Saved Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '- $weightSaved',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isRtl ? 'كجم' : 'kg',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.success.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Reason
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              reason,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          
          // Remove Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final success = await _removeOptionalItem(item, isRtl);
                if (mounted && success) {
                  CustomToast.success(
                    context,
                    isRtl ? 'تم حذف ${item['name']} بنجاح' : '${item['name']} removed successfully',
                  );
                  // Refresh bag
                  await ref.read(bagControllerProvider.notifier).loadBagDetails();
                } else if (mounted) {
                  CustomToast.error(
                    context,
                    isRtl ? 'فشل حذف ${item['name']}' : 'Failed to remove ${item['name']}',
                  );
                }
              },
              icon: const Icon(Icons.remove_rounded, size: 18),
              label: Text(isRtl ? 'احذف من الحقيبة' : 'Remove from Bag'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: BorderSide(color: AppColors.info),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Improvement Suggestions Section (Green-bordered)
  Widget _buildImprovementSuggestionsSection(
    Map<String, dynamic>? weightOptimization,
    List additionalSuggestions,
    bool isRtl,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isRtl ? 'اقتراحات التحسين' : 'Improvement Suggestions',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Weight Reduction
                if (weightOptimization != null)
                  _buildWeightReductionCard(weightOptimization, isRtl),
                
                if (weightOptimization != null && additionalSuggestions.isNotEmpty)
                  const SizedBox(height: 16),
                
                // Item Redistribution
                if (additionalSuggestions.isNotEmpty)
                  _buildItemRedistributionCard(additionalSuggestions, isRtl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightReductionCard(Map<String, dynamic> optimization, bool isRtl) {
    final currentWeight = optimization['current_weight']?.toString() ?? '0';
    final suggestedWeight = optimization['suggested_weight']?.toString() ?? '0';
    final weightSaved = optimization['weight_saved']?.toString() ?? '0';
    final impactLevel = optimization['impact_level'] ?? 'medium';
    
    final impactText = impactLevel == 'high'
        ? (isRtl ? 'تأثير عالي' : 'High Impact')
        : impactLevel == 'medium'
            ? (isRtl ? 'تأثير متوسط' : 'Medium Impact')
            : (isRtl ? 'تأثير منخفض' : 'Low Impact');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_down_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isRtl ? 'تخفيف الوزن' : 'Weight Reduction',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Weight Comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'الحالي' : 'Current',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentWeight ${isRtl ? 'كجم' : 'kg'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'المقترح' : 'Suggested',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$suggestedWeight ${isRtl ? 'كجم' : 'kg'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Savings and Impact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.save_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isRtl ? 'توفير' : 'Save'} $weightSaved ${isRtl ? 'كجم' : 'kg'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  impactText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRedistributionCard(List suggestions, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isRtl ? 'إعادة توزيع الأغراض' : 'Item Redistribution',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((suggestion) {
            String title = '';
            String description = '';
            String benefits = '';
            
            if (suggestion is Map<String, dynamic>) {
              // Handle nested category structure
              if (suggestion['category'] is Map) {
                final category = suggestion['category'] as Map;
                title = (category['title']?.toString() ?? '').trim();
                description = (category['description']?.toString() ?? '').trim();
              }
              
              // If description not found in category, try top level
              if (description.isEmpty) {
                description = (suggestion['description']?.toString() ?? 
                             suggestion['suggestion']?.toString() ?? 
                             suggestion['text']?.toString() ?? '').trim();
              }
              
              // If title not found in category, try top level
              if (title.isEmpty) {
                title = (suggestion['title']?.toString() ?? 
                        suggestion['name']?.toString() ?? '').trim();
              }
              
              // Try to extract benefits
              if (suggestion['benefits'] != null) {
                if (suggestion['benefits'] is List) {
                  benefits = (suggestion['benefits'] as List)
                      .map((e) => e.toString().trim())
                      .where((e) => e.isNotEmpty)
                      .join(', ');
                } else {
                  benefits = suggestion['benefits'].toString().trim();
                }
              }
            } else if (suggestion is String) {
              description = suggestion.trim();
            }
            
            // Clean up the description
            description = description.trim();
            
            // Skip if no description
            if (description.isEmpty) {
              return null;
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty) ...[
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        if (benefits.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            benefits,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).whereType<Widget>().toList(),
        ],
      ),
    );
  }

  // Bottom Action Buttons
  Widget _buildBottomActions(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: OutlinedButton(
          onPressed: () => _returnToBag(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              isRtl ? 'رجوع' : 'Return',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add missing item to bag (returns success status, no toast)
  Future<bool> _addMissingItem(Map<String, dynamic> item, bool isRtl) async {
    final itemName = item['name'] ?? '';
    final weight = (item['weight'] as num?)?.toDouble() ?? 0.0;
    final category = item['category'] ?? '';
    
    if (itemName.isEmpty || weight <= 0) {
      return false;
    }

    try {
      // Get categories to find matching category ID
      final bagState = ref.read(bagControllerProvider);
      final categories = bagState.categories;
      
      // Find category by name (try Arabic and English)
      BagCategoryModel? selectedCategory;
      for (var cat in categories) {
        if (cat.nameAr == category || cat.nameEn == category || cat.name == category) {
          selectedCategory = cat;
          break;
        }
      }
      
      // If no match found, use first category as fallback
      if (selectedCategory == null && categories.isNotEmpty) {
        selectedCategory = categories.first;
      }
      
      if (selectedCategory == null) {
        return false;
      }

      final success = await ref.read(bagControllerProvider.notifier).addItemToBag(
        itemId: null,
        bagTypeId: widget.bagId,
        quantity: 1,
        customItemName: itemName,
        customWeight: weight,
        weightUnit: 'kg',
        itemCategoryId: selectedCategory.id,
        essential: item['priority'] == 'high',
      );

      if (success) {
        // Mark as processed to avoid duplicates
        _processedItems.add(item['id'] ?? itemName);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Remove optional item from bag (returns success status, no toast)
  Future<bool> _removeOptionalItem(Map<String, dynamic> item, bool isRtl) async {
    final itemName = item['name'] ?? '';
    final itemId = item['item_id'] ?? item['id'];
    
    if (itemId == null) {
      // Try to find item by name in the bag
      final bagState = ref.read(bagControllerProvider);
      // Find bag that matches the bagId (bagTypeId)
      BagDetailModel? bag;
      try {
        bag = bagState.bagDetails.firstWhere(
          (detail) => detail.bagTypeId == widget.bagId,
        );
      } catch (e) {
        // Bag not found, try to use first bag if available
        if (bagState.bagDetails.isNotEmpty) {
          bag = bagState.bagDetails.first;
        }
      }
      
      if (bag != null && bag.items.isNotEmpty) {
        // Find item by name match
        try {
          final matchingItem = bag.items.firstWhere(
            (bagItem) => bagItem.name.toLowerCase() == itemName.toLowerCase(),
          );
          
          if (matchingItem.itemId != null) {
            try {
              final success = await ref.read(bagControllerProvider.notifier).deleteItemFromBag(
                itemId: matchingItem.itemId!,
                bagTypeId: widget.bagId,
              );
              return success;
            } catch (e) {
              return false;
            }
          }
        } catch (e) {
          // Item not found by name
          return false;
        }
      }
      return false;
    }

    try {
      final success = await ref.read(bagControllerProvider.notifier).deleteItemFromBag(
        itemId: itemId,
        bagTypeId: widget.bagId,
      );
      return success;
    } catch (e) {
      return false;
    }
  }


  // Return to bag
  Future<void> _returnToBag() async {
    // Reload bag details to show any added items
    try {
      await ref.read(bagControllerProvider.notifier).loadBagDetails();
    } catch (e) {
      debugPrint('Error reloading bag details: $e');
    }
    
    if (mounted) {
      context.pop();
    }
  }
}
