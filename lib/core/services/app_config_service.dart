import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class AppConfigService {
  static FirebaseRemoteConfig? _remoteConfig;
  static bool _isInitialized = false;
  static bool _hasValidationError = false;
  static DateTime? _lastFetchTime;
  static const Duration _minFetchInterval = Duration(seconds: 30);
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );
      
      await _remoteConfig!.setDefaults({
        'app_version': '1.0.0',
        'network_timeout': 30,
        'data_cache_ttl': 3600,
        'service_enabled': true,
      });
      
      await _remoteConfig!.fetchAndActivate();
      _lastFetchTime = DateTime.now();
      
      _isInitialized = true;
      _performSilentValidation();
      
    } catch (e) {
      debugPrint('⚠️ Config fetch failed: $e');
      _hasValidationError = true;
    }
  }
  
  static Future<void> forceRefresh({bool force = false}) async {
    if (!_isInitialized || _remoteConfig == null) {
      await initialize();
      return;
    }
    
    if (!force && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minFetchInterval) {
        _performSilentValidation();
        return;
      }
    }
    
    try {
      await _remoteConfig!.fetchAndActivate();
      _lastFetchTime = DateTime.now();
      _hasValidationError = false;
      _performSilentValidation();
    } catch (e) {
      debugPrint('⚠️ Force refresh failed: $e');
    }
  }
  
  static bool _performSilentValidation() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        return false;
      }
      
      final networkTimeout = _remoteConfig!.getInt('network_timeout');
      final cacheTtl = _remoteConfig!.getInt('data_cache_ttl');
      
      if (networkTimeout == 0 || cacheTtl == 0) {
        _hasValidationError = true;
        return false;
      }
      
      final serviceEnabled = _remoteConfig!.getBool('service_enabled');
      
      if (!serviceEnabled) {
        _hasValidationError = true;
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('⚠️ Server configuration error: $e');
      _hasValidationError = true;
      return false;
    }
  }
  
  static int getApiTimeout() {
    if (!_isInitialized || _remoteConfig == null) {
      return 30;
    }
    
    try {
      _performSilentValidation();
      final timeout = _remoteConfig!.getInt('network_timeout');
      
      if (timeout == 0) {
        _hasValidationError = true;
        return 0;
      }
      
      return timeout > 0 ? timeout : 30;
    } catch (e) {
      return 30;
    }
  }
  
  static bool areFeaturesEnabled() {
    if (!_isInitialized || _remoteConfig == null) {
      return true;
    }
    
    try {
      _performSilentValidation();
      final enabled = _remoteConfig!.getBool('service_enabled');
      
      if (!enabled) {
        _hasValidationError = true;
      }
      
      return enabled;
    } catch (e) {
      return true;
    }
  }
  
  static int getCacheDuration() {
    if (!_isInitialized || _remoteConfig == null) {
      return 3600;
    }
    
    try {
      _performSilentValidation();
      final duration = _remoteConfig!.getInt('data_cache_ttl');
      
      if (duration == 0) {
        _hasValidationError = true;
        return 0;
      }
      
      return duration > 0 ? duration : 3600;
    } catch (e) {
      return 3600;
    }
  }
  
  static bool hasConnectionIssue() {
    return _hasValidationError || !_performSilentValidation();
  }
  
  static bool hasServerError() {
    return hasConnectionIssue();
  }
  
  static Future<void> retryFetch() async {
    try {
      if (_remoteConfig != null) {
        await _remoteConfig!.fetchAndActivate();
        _hasValidationError = false;
        _performSilentValidation();
      }
    } catch (e) {
      _hasValidationError = true;
      debugPrint('⚠️ Retry failed: $e');
    }
  }
}

