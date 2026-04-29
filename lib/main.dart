import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/services/firebase_service.dart';
import 'package:season_app/core/services/local_storage_service.dart';
import 'package:season_app/core/services/notification_service.dart';
import 'package:season_app/core/services/background_location_service.dart';
import 'package:season_app/core/services/safety_radius_alarm_service.dart';
import 'package:season_app/core/services/location_service.dart';
import 'package:season_app/core/services/screenshot_prevention_service.dart';
import 'package:season_app/core/services/country_detection_service.dart';
import 'package:season_app/core/services/auth_service.dart';
import 'package:season_app/core/services/app_config_service.dart';
import 'package:season_app/core/utils/timezone_helper.dart';
import 'package:season_app/shared/providers/locale_provider.dart';
import 'package:season_app/shared/providers/theme_provider.dart';
import 'core/localization/generated/l10n.dart';
import 'core/router/app_router.dart';
import 'core/themes/app_theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure status bar to be visible throughout the app
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize timezone data
  await TimezoneHelper.initialize();
  
  // Initialize local storage service
  await LocalStorageService.init();
  
  // Initialize Firebase and Notifications
  try {
    await FirebaseService.initialize();
    
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('❌ Error initializing Firebase: $e');
  }

  // Initialize background location service
  try {
    await initializeBackgroundLocationService();
    // Start background location tracking for all groups if user is logged in
    if (AuthService.isLoggedIn()) {
      // Request permissions first, then start tracking
      try {
        final hasPermission = await LocationService.requestPermissions();
        if (hasPermission) {
          await startBackgroundLocationTracking();
          debugPrint('✅ Background location tracking started with permissions');
        } else {
          debugPrint('⚠️ Location permissions not granted - location tracking may not work');
        }
      } catch (e) {
        debugPrint('⚠️ Error requesting location permissions: $e');
        // Still try to start tracking - native service will handle permissions
        await startBackgroundLocationTracking();
      }
      // Start continuous safety radius monitoring for all admin groups
      await SafetyRadiusAlarmService().startContinuousMonitoring();
    }
  } catch (e) {
    debugPrint('Error initializing background location service: $e');
  }

  // Enable screenshot prevention
  try {
    await ScreenshotPreventionService.disableScreenshotPrevention();
  } catch (e) {
    debugPrint('Error enabling screenshot prevention: $e');
  }

  // Initialize country detection on app startup
  // Clear cache first to ensure fresh detection
  CountryDetectionService.clearCache();
  try {
    final countryCode = await CountryDetectionService.getCountryCodeFromIP();
    debugPrint('✅ Country code detected: $countryCode');
  } catch (e) {
    debugPrint('⚠️ Error detecting country: $e');
  }

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      AppConfigService.forceRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return Consumer(
        builder:(context,ref,_){
          final themeMode = ref.watch(themeProvider);
          return MaterialApp.router(
            title: 'Season App',
            debugShowCheckedModeBanner: false,
            locale: locale,
            theme: AppTheme.lightTheme,
            themeMode: themeMode,
            supportedLocales: AppLocalizations.delegate.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          );
        }
    );
  }
}
