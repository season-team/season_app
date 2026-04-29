import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:season_app/core/services/auth_service.dart';
import 'package:season_app/core/services/session_expired_navigation_service.dart';

/// Callback function for token refresh
typedef TokenRefreshCallback =
Future<TokenResponse> Function(String refreshToken);

/// Token response model
class TokenResponse {
  final String accessToken;
  final String refreshToken;

  TokenResponse({required this.accessToken, required this.refreshToken});
}

/// Advanced Dio HTTP client wrapper with comprehensive features
class DioHelper {
  static DioHelper? _instance;
  late Dio _dio;
  CancelToken? _cancelToken;

  // Token management
  String? _accessToken;
  String? _refreshToken;
  TokenRefreshCallback? _tokenRefreshCallback;
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
  _pendingRequests = [];

  // Private constructor for singleton
  DioHelper._internal();

  /// Get singleton instance
  static DioHelper get instance {
    _instance ??= DioHelper._internal();
    return _instance!;
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current refresh token
  String? get refreshToken => _refreshToken;

  /// Initialize DioHelper with configuration
  void initialize({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    Map<String, dynamic>? headers,
    String? accessToken,
    String? refreshToken,
    TokenRefreshCallback? onRefreshToken,
    bool enableLogging = true,
    bool enableTokenRefresh = true,
  }) {
    _dio = Dio();

    // Store tokens
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenRefreshCallback = onRefreshToken;

    // Base configuration
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      },
    );

    // Add access token if provided
    if (accessToken != null) {
      setAccessToken(accessToken);
    }

    // Add interceptors
    _addInterceptors(enableLogging, enableTokenRefresh);
  }

  /// Add interceptors for logging, headers, and error handling
  void _addInterceptors(bool enableLogging, bool enableTokenRefresh) {
    // Request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode && enableLogging) {
            dPrint('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
            dPrint('Headers: ${options.headers}');
            if (options.data != null) {
              dPrint('Data: ${options.data}');
            }
            if (options.queryParameters.isNotEmpty) {
              dPrint('Query Parameters: ${options.queryParameters}');
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode && enableLogging) {
            dPrint(
              '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
            );
            dPrint('Data: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode && enableLogging) {
            dPrint(
              '❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
            );
            dPrint('Message: ${error.message}');
            if (error.response?.data != null) {
              dPrint('Error Data: ${error.response?.data}');
            }
          }
          handler.next(error);
        },
      ),
    );

    // Token refresh interceptor (add before error handling interceptor)
    if (enableTokenRefresh) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) async {
            // Check if error is 401 and we have refresh token
            if (error.response?.statusCode == 401 &&
                _refreshToken != null &&
                _tokenRefreshCallback != null &&
                !_isRefreshing) {
              // Prevent multiple refresh attempts
              _isRefreshing = true;

              try {
                // Call the refresh token callback
                final tokenResponse = await _tokenRefreshCallback!(
                  _refreshToken!,
                );

                // Update tokens
                setAccessToken(tokenResponse.accessToken);
                setRefreshToken(tokenResponse.refreshToken);

                // Retry the failed request with new token
                error.requestOptions.headers['Authorization'] =
                'Bearer ${tokenResponse.accessToken}';

                final response = await _dio.fetch(error.requestOptions);

                // Resolve all pending requests with new token
                _retryPendingRequests(tokenResponse.accessToken);

                _isRefreshing = false;
                handler.resolve(response);
                return;
              } catch (e) {
                _isRefreshing = false;
                // Clear tokens on refresh failure
                clearTokens();
                SessionExpiredNavigationService.handleSessionExpired();
                // Reject all pending requests
                _rejectPendingRequests(error);
                handler.reject(error);
                return;
              }
            } else if (_isRefreshing && error.response?.statusCode == 401) {
              // Queue the request if token refresh is in progress
              _pendingRequests.add((
              options: error.requestOptions,
              handler: handler,
              ));
              return;
            }

            handler.next(error);
          },
        ),
      );
    }

    // Error handling interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _scheduleUnauthenticatedRedirectIfNeeded(error);
          final apiException = DioExceptionHandler.handleException(error);

          // Create a new DioException with custom error message
          final customError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: apiException,
            message: apiException.message,
          );

          handler.reject(customError);
        },
      ),
    );
  }

  /// Retry all pending requests with new access token
  void _retryPendingRequests(String newAccessToken) {
    for (final pending in _pendingRequests) {
      pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
      _dio
          .fetch(pending.options)
          .then(
            (response) => pending.handler.resolve(response),
        onError: (error) => pending.handler.reject(error as DioException),
      );
    }
    _pendingRequests.clear();
  }

  /// Reject all pending requests
  void _rejectPendingRequests(DioException error) {
    for (final pending in _pendingRequests) {
      pending.handler.reject(error);
    }
    _pendingRequests.clear();
  }

  /// Get ApiException from DioException
  static ApiException? getApiException(DioException error) {
    if (error.error is ApiException) {
      return error.error as ApiException;
    }
    return null;
  }

  /// Handle error and return ApiException
  static ApiException handleError(dynamic error) {
    if (error is DioException) {
      if (error.error is ApiException) {
        return error.error as ApiException;
      }
      return DioExceptionHandler.handleException(error);
    }

    return ApiException(
      type: ApiExceptionType.unknown,
      message: error.toString(),
    );
  }

  /// Set access token
  void setAccessToken(String token, {String tokenType = 'Bearer'}) {
    _accessToken = token;
    _dio.options.headers['Authorization'] = '$tokenType $token';
  }

  /// Set refresh token
  void setRefreshToken(String token) {
    _refreshToken = token;
  }

  /// Set both access and refresh tokens
  void setTokens({
    required String accessToken,
    required String refreshToken,
    String tokenType = 'Bearer',
  }) {
    setAccessToken(accessToken, tokenType: tokenType);
    setRefreshToken(refreshToken);
  }

  /// Update token refresh callback
  void setTokenRefreshCallback(TokenRefreshCallback callback) {
    _tokenRefreshCallback = callback;
  }

  /// Clear all tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _dio.options.headers.remove('Authorization');
  }

  /// Check if tokens are available
  bool get hasTokens => _accessToken != null && _refreshToken != null;

  /// Check if only access token is available
  bool get hasAccessToken => _accessToken != null;

  /// Manually refresh token
  Future<void> refreshTokenManually() async {
    if (_refreshToken == null || _tokenRefreshCallback == null) {
      throw Exception('Refresh token or callback not available');
    }

    try {
      _isRefreshing = true;
      final tokenResponse = await _tokenRefreshCallback!(_refreshToken!);
      setAccessToken(tokenResponse.accessToken);
      setRefreshToken(tokenResponse.refreshToken);
    } catch (e) {
      clearTokens();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Set authentication token (deprecated - use setAccessToken)
  void setAuthToken(String token, {String tokenType = 'Bearer'}) {
    setAccessToken(token, tokenType: tokenType);
  }

  /// Remove authentication token (deprecated - use clearTokens)
  @Deprecated('Use clearTokens instead')
  void removeAuthToken() {
    clearTokens();
  }

  /// Set custom headers
  void setHeaders(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }

  /// Remove specific header
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// Update base URL
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Create new cancel token
  CancelToken createCancelToken() {
    _cancelToken = CancelToken();
    return _cancelToken!;
  }

  /// Cancel current request
  void cancelRequest([String? reason]) {
    _cancelToken?.cancel(reason ?? 'Request cancelled by user');
  }

  /// GET request
  Future<Response<T>> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
        Map<String, dynamic>? headers,
        dynamic data,
      }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(options, headers),
        cancelToken: cancelToken ?? _cancelToken,
        onReceiveProgress: onReceiveProgress,
        data: data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(options, headers),
        cancelToken: cancelToken ?? _cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(options, headers),
        cancelToken: cancelToken ?? _cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(options, headers),
        cancelToken: cancelToken ?? _cancelToken,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(options, headers),
        cancelToken: cancelToken ?? _cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload file
  Future<Response<T>> uploadFile<T>(
      String path,
      String filePath, {
        String? fileName,
        Map<String, dynamic>? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: _buildOptions(options, headers),
        cancelToken: cancelToken ?? _cancelToken,
        onSendProgress: onSendProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Download file
  Future<Response> downloadFile(
      String urlPath,
      String savePath, {
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        bool deleteOnError = true,
        String lengthHeader = Headers.contentLengthHeader,
        Options? options,
        ProgressCallback? onReceiveProgress,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? _cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        options: _buildOptions(options, headers),
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Build options with custom headers
  Options _buildOptions(Options? options, Map<String, dynamic>? headers) {
    if (headers == null) return options ?? Options();

    final mergedHeaders = <String, dynamic>{...?options?.headers, ...headers};

    return (options ?? Options()).copyWith(headers: mergedHeaders);
  }

  /// Get current Dio instance (use carefully)
  Dio get dio => _dio;

  /// Clear all headers
  void clearHeaders() {
    _dio.options.headers.clear();
    // Re-add essential headers
    _dio.options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
  }

  /// Add retry interceptor
  void addRetryInterceptor({
    int retries = 3,
    List<int> retryStatuses = const [502, 503, 504],
  }) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (retryStatuses.contains(error.response?.statusCode) &&
              error.requestOptions.extra['retryCount'] == null) {
            error.requestOptions.extra['retryCount'] = 0;
          }

          final retryCount = error.requestOptions.extra['retryCount'] ?? 0;

          if (retryCount < retries &&
              retryStatuses.contains(error.response?.statusCode)) {
            error.requestOptions.extra['retryCount'] = retryCount + 1;

            // Add delay before retry
            await Future.delayed(Duration(seconds: retryCount + 1));

            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }
}

/// Custom exception types for better error handling
enum ApiExceptionType {
  /// Network related errors
  network,

  /// Bad request (400)
  badRequest,

  /// Unauthorized (401)
  unauthorized,

  /// Forbidden (403)
  forbidden,

  /// Not found (404)
  notFound,

  /// Request timeout (408)
  requestTimeout,

  /// Conflict (409)
  conflict,

  /// Validation error (422)
  validationError,

  /// Too many requests (429)
  tooManyRequests,

  /// Internal server error (500)
  internalServerError,

  /// Bad gateway (502)
  badGateway,

  /// Service unavailable (503)
  serviceUnavailable,

  /// Gateway timeout (504)
  gatewayTimeout,

  /// Request cancelled
  requestCancelled,

  /// Connection timeout
  connectionTimeout,

  /// Send timeout
  sendTimeout,

  /// Receive timeout
  receiveTimeout,

  /// Bad certificate
  badCertificate,

  /// Unknown error
  unknown,
}

/// Custom API Exception class
class ApiException implements Exception {
  /// Exception type
  final ApiExceptionType type;

  /// Error message
  final String message;

  /// HTTP status code
  final int? statusCode;

  /// Original DioException
  final DioException? dioException;

  /// Response data
  final dynamic responseData;

  /// Request path
  final String? requestPath;

  /// Request method
  final String? requestMethod;

  /// Error details (for validation errors)
  final Map<String, dynamic>? errorDetails;

  ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.dioException,
    this.responseData,
    this.requestPath,
    this.requestMethod,
    this.errorDetails,
  });

  @override
  String toString() {
    return 'ApiException: $message (Type: $type, Status: $statusCode)';
  }

  /// Check if error is a network error
  bool get isNetworkError => type == ApiExceptionType.network;

  /// Check if error is an authentication error
  bool get isAuthError => type == ApiExceptionType.unauthorized;

  /// Check if error is a validation error
  bool get isValidationError => type == ApiExceptionType.validationError;

  /// Check if error is a server error
  bool get isServerError =>
      type == ApiExceptionType.internalServerError ||
          type == ApiExceptionType.badGateway ||
          type == ApiExceptionType.serviceUnavailable ||
          type == ApiExceptionType.gatewayTimeout;

  /// Check if request was cancelled
  bool get isCancelled => type == ApiExceptionType.requestCancelled;

  /// Check if error is a timeout error
  bool get isTimeout =>
      type == ApiExceptionType.connectionTimeout ||
          type == ApiExceptionType.sendTimeout ||
          type == ApiExceptionType.receiveTimeout ||
          type == ApiExceptionType.requestTimeout;
}

/// DioException handler class
class DioExceptionHandler {
  /// Convert DioException to ApiException
  static ApiException handleException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return _handleConnectionTimeout(error);

      case DioExceptionType.sendTimeout:
        return _handleSendTimeout(error);

      case DioExceptionType.receiveTimeout:
        return _handleReceiveTimeout(error);

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return _handleCancel(error);

      case DioExceptionType.connectionError:
        return _handleConnectionError(error);

      case DioExceptionType.badCertificate:
        return _handleBadCertificate(error);

      case DioExceptionType.unknown:
        return _handleUnknown(error);
    }
  }

  /// Handle connection timeout
  static ApiException _handleConnectionTimeout(DioException error) {
    return ApiException(
      type: ApiExceptionType.connectionTimeout,
      message:
      'Connection timeout. Please check your internet connection and try again.',
      dioException: error,
      requestPath: error.requestOptions.path,
      requestMethod: error.requestOptions.method,
    );
  }

  /// Handle send timeout
  static ApiException _handleSendTimeout(DioException error) {
    return ApiException(
      type: ApiExceptionType.sendTimeout,
      message:
      'Send timeout. The request took too long to send. Please try again.',
      dioException: error,
      requestPath: error.requestOptions.path,
      requestMethod: error.requestOptions.method,
    );
  }

  /// Handle receive timeout
  static ApiException _handleReceiveTimeout(DioException error) {
    return ApiException(
      type: ApiExceptionType.receiveTimeout,
      message:
      'Receive timeout. The server took too long to respond. Please try again.',
      dioException: error,
      requestPath: error.requestOptions.path,
      requestMethod: error.requestOptions.method,
    );
  }

  /// Handle bad response (HTTP errors)
  static ApiException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Try to extract error message from response
    String errorMessage = _extractErrorMessage(responseData);
    Map<String, dynamic>? errorDetails = _extractValidationErrors(responseData);

    switch (statusCode) {
      case 400:
        return ApiException(
          type: ApiExceptionType.badRequest,
          message: errorMessage.isEmpty
              ? 'Bad request. Please check your input and try again.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
          errorDetails: errorDetails,
        );

      case 401:
        return ApiException(
          type: ApiExceptionType.unauthorized,
          message: errorMessage.isEmpty
              ? 'Unauthorized. Please login again.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 403:
        return ApiException(
          type: ApiExceptionType.forbidden,
          message: errorMessage.isEmpty
              ? 'Forbidden. You don\'t have permission to access this resource.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 404:
        return ApiException(
          type: ApiExceptionType.notFound,
          message: errorMessage.isEmpty ? 'Resource not found.' : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 408:
        return ApiException(
          type: ApiExceptionType.requestTimeout,
          message: errorMessage.isEmpty
              ? 'Request timeout. Please try again.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 409:
        return ApiException(
          type: ApiExceptionType.conflict,
          message: errorMessage.isEmpty
              ? 'Conflict. The resource already exists or there is a conflict.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 422:
        return ApiException(
          type: ApiExceptionType.validationError,
          message: errorMessage.isEmpty
              ? 'Validation error. Please check your input.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
          errorDetails: errorDetails,
        );

      case 429:
        return ApiException(
          type: ApiExceptionType.tooManyRequests,
          message: errorMessage.isEmpty
              ? 'Too many requests. Please try again later.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 500:
        return ApiException(
          type: ApiExceptionType.internalServerError,
          message: errorMessage.isEmpty
              ? 'Internal server error. Please try again later.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 502:
        return ApiException(
          type: ApiExceptionType.badGateway,
          message: errorMessage.isEmpty
              ? 'Bad gateway. Please try again later.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 503:
        return ApiException(
          type: ApiExceptionType.serviceUnavailable,
          message: errorMessage.isEmpty
              ? 'Service unavailable. Please try again later.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      case 504:
        return ApiException(
          type: ApiExceptionType.gatewayTimeout,
          message: errorMessage.isEmpty
              ? 'Gateway timeout. Please try again later.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );

      default:
        return ApiException(
          type: ApiExceptionType.unknown,
          message: errorMessage.isEmpty
              ? 'An error occurred. Please try again.'
              : errorMessage,
          statusCode: statusCode,
          dioException: error,
          responseData: responseData,
          requestPath: error.requestOptions.path,
          requestMethod: error.requestOptions.method,
        );
    }
  }

  /// Handle request cancellation
  static ApiException _handleCancel(DioException error) {
    return ApiException(
      type: ApiExceptionType.requestCancelled,
      message: 'Request was cancelled.',
      dioException: error,
      requestPath: error.requestOptions.path,
      requestMethod: error.requestOptions.method,
    );
  }

  /// Handle connection error
  static ApiException _handleConnectionError(DioException error) {
    return ApiException(
      type: ApiExceptionType.network,
      message:
      'No internet connection. Please check your network and try again.',
      dioException: error,
      requestPath: error.requestOptions.path,
      requestMethod: error.requestOptions.method,
    );
  }

  /// Handle bad certificate
  static ApiException _handleBadCertificate(DioException error) {
    return ApiException(
      type: ApiExceptionType.badCertificate,
      message: 'Security certificate error. Please try again.',
      dioException: error,
      requestPath: error.requestOptions.path,
      requestMethod: error.requestOptions.method,
    );
  }

  /// Handle unknown error
  static ApiException _handleUnknown(DioException error) {
    return ApiException(
      type: ApiExceptionType.unknown,
      message:
      error.message ?? 'An unexpected error occurred. Please try again.',
      dioException: error,
      requestPath: error.requestOptions.path,
      requestMethod: error.requestOptions.method,
    );
  }

  /// Extract error message from response data
  static String _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return '';

    try {
      if (responseData is Map) {
        // Common error message keys
        final messageKeys = [
          'message',
          'error',
          'msg',
          'detail',
          'details',
          'errorMessage',
        ];

        for (final key in messageKeys) {
          if (responseData.containsKey(key) && responseData[key] is String) {
            return responseData[key] as String;
          }
        }

        // Try nested error object
        if (responseData.containsKey('error') && responseData['error'] is Map) {
          final errorObj = responseData['error'] as Map;
          for (final key in messageKeys) {
            if (errorObj.containsKey(key) && errorObj[key] is String) {
              return errorObj[key] as String;
            }
          }
        }
      } else if (responseData is String) {
        return responseData;
      }
    } catch (e) {
      return '';
    }

    return '';
  }

  /// Extract validation errors from response data
  static Map<String, dynamic>? _extractValidationErrors(dynamic responseData) {
    if (responseData == null) return null;

    try {
      if (responseData is Map) {
        // Common validation error keys
        if (responseData.containsKey('errors') &&
            responseData['errors'] is Map) {
          return Map<String, dynamic>.from(responseData['errors'] as Map);
        }

        if (responseData.containsKey('validationErrors') &&
            responseData['validationErrors'] is Map) {
          return Map<String, dynamic>.from(
            responseData['validationErrors'] as Map,
          );
        }

        if (responseData.containsKey('fields') &&
            responseData['fields'] is Map) {
          return Map<String, dynamic>.from(responseData['fields'] as Map);
        }
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(ApiException exception) {
    return exception.message;
  }

  /// Get validation error message for a specific field
  static String? getFieldError(ApiException exception, String fieldName) {
    if (exception.errorDetails == null) return null;

    final fieldError = exception.errorDetails![fieldName];
    if (fieldError == null) return null;

    if (fieldError is String) {
      return fieldError;
    } else if (fieldError is List && fieldError.isNotEmpty) {
      return fieldError.first.toString();
    }

    return null;
  }

  /// Get all validation errors as formatted string
  static String getValidationErrorsString(ApiException exception) {
    if (exception.errorDetails == null || exception.errorDetails!.isEmpty) {
      return exception.message;
    }

    final errors = <String>[];
    exception.errorDetails!.forEach((field, error) {
      if (error is String) {
        errors.add('$field: $error');
      } else if (error is List && error.isNotEmpty) {
        errors.add('$field: ${error.first}');
      }
    });

    return errors.isEmpty ? exception.message : errors.join('\n');
  }
}

/// Custom print function for debug mode
void dPrint(String message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Paths where HTTP 401 means invalid credentials / OTP, not an expired app session.
bool _shouldSkip401RedirectForPath(String path) {
  final p = path.toLowerCase();
  const skips = [
    '/auth/login',
    '/auth/register',
    '/auth/verify-otp',
    '/auth/resend-otp',
    '/auth/forgot-password',
    '/auth/verify-reset-otp',
    '/auth/resend-reset-otp',
    '/auth/reset-password',
  ];
  for (final s in skips) {
    if (p.contains(s)) return true;
  }
  return false;
}

/// Laravel-style `{ status: 401, message: Unauthenticated. }`, or a request that sent Bearer token.
bool _shouldRedirectToHomeFor401Body(dynamic data, RequestOptions options) {
  if (data is Map) {
    final msg = data['message']?.toString().toLowerCase() ?? '';
    if (msg.contains('unauthenticated')) return true;
    if (data['status'] == 401) return true;
  }
  final auth = options.headers['Authorization'] ?? options.headers['authorization'];
  if (auth != null && auth.toString().trim().isNotEmpty) {
    return true;
  }
  return false;
}

void _scheduleUnauthenticatedRedirectIfNeeded(DioException error) {
  if (error.response?.statusCode != 401) return;
  if (_shouldSkip401RedirectForPath(error.requestOptions.path)) return;

  final auth = error.requestOptions.headers['Authorization'] ??
      error.requestOptions.headers['authorization'];
  final hasAuthHeader = auth != null && auth.toString().trim().isNotEmpty;
  // Guest hit a protected route without a token — not "session expired"; avoid redirect/log spam.
  if (!hasAuthHeader && !AuthService.isLoggedIn()) {
    return;
  }

  if (!_shouldRedirectToHomeFor401Body(
        error.response?.data,
        error.requestOptions,
      )) {
    return;
  }
  SessionExpiredNavigationService.handleSessionExpired();
}