import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/features/profile/presentation/screens/webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility class for handling banner navigation
/// Handles all routes that don't require an ID parameter
class BannerNavigation {
  /// Navigates to the appropriate screen based on the banner route
  /// 
  /// [route] - The route path (e.g., '/geographical-directory')
  /// [routeParams] - Optional query parameters (e.g., {'url': 'https://example.com', 'title': 'Website'})
  /// [context] - BuildContext for navigation
  static void navigate({
    required String route,
    Map<String, dynamic>? routeParams,
    required BuildContext context,
  }) {
    try {
      switch (route) {
        // Authentication Routes
        case Routes.login:
        case Routes.signUp:
        case Routes.welcome:
        case Routes.verifyOtp:
        case Routes.forgotPassword:
        case Routes.verifyResetOtp:
        case Routes.resetPassword:
          context.push(route);
          break;

        // Main App Routes
        case Routes.home:
          // Handle tab query parameter for home route
          if (routeParams != null && routeParams.containsKey('tab')) {
            final tab = routeParams['tab']?.toString() ?? '';
            context.push('${Routes.home}?tab=$tab');
          } else {
            context.push(route);
          }
          break;
        case Routes.profile:
        case Routes.profileEdit:
        case Routes.settings:
        case Routes.splash:
          context.push(route);
          break;

        // Vendor Services Routes
        case Routes.vendorServices:
        case Routes.vendorServiceNew:
        case Routes.publicVendorServices:
          context.push(route);
          break;

        // Geographical Guides Routes
        case Routes.geographicalDirectory:
        case Routes.applyAsTrader:
        case Routes.myGeographicalServices:
        case Routes.newGeographicalGuide:
          context.push(route);
          break;

        // Digital Directory Routes
        case Routes.categories:
          context.push(route);
          break;

        // Utility Routes
        case Routes.emergency:
        case Routes.currencyConverter:
          context.push(route);
          break;

        // Location Picker - handles query params
        case Routes.locationPicker:
          final lat = routeParams?['lat']?.toString() ?? '0';
          final lng = routeParams?['lng']?.toString() ?? '0';
          context.push('${Routes.locationPicker}?lat=$lat&lng=$lng');
          break;

        // WebView - handles query params
        case Routes.webview:
          final url = routeParams?['url']?.toString() ?? '';
          final title = routeParams?['title']?.toString() ?? 'Banner';
          if (url.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebViewScreen(
                  url: url,
                  title: title,
                ),
              ),
            );
          } else {
            // If no URL provided, try to use route as URL or show error
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No URL provided for webview'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        // Groups Routes
        case '/groups':
        case '/groups/create':
        case '/groups/join':
        case '/groups/qr-scanner':
          context.push(route);
          break;

        // Default: try to navigate using GoRouter
        // If route doesn't match, it will be handled by GoRouter's error handling
        default:
          // Check if it's an external URL
          if (route.startsWith('http://') || route.startsWith('https://')) {
            _launchExternalUrl(route, context);
          } else {
            // Build route with query parameters if provided
            String routePath = route;
            if (routeParams != null && routeParams.isNotEmpty) {
              final uri = Uri(path: routePath, queryParameters: routeParams.map(
                (key, value) => MapEntry(key, value.toString()),
              ));
              routePath = uri.toString();
            }
            // Try to navigate with GoRouter
            context.push(routePath);
          }
          break;
      }
    } catch (e) {
      // If navigation fails, show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to navigate to: $route'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Launches an external URL using url_launcher
  static Future<void> _launchExternalUrl(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open this URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

