// core/router/routes.dart
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/signUp';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String welcome = '/welcome';
  static const String verifyOtp = '/verifyOtp';
  static const String webview = '/webview';
  static const String connectionError = '/connection-error';
  // Vendor services
  static const String vendorServices = '/vendor/services';
  static const String vendorServiceNew = '/vendor/services/new';
  static const String vendorServiceEdit = '/vendor/services/:id/edit';
  static const String vendorServiceDetails = '/vendor/services/:id';
  static const String locationPicker = '/location/picker';
  
  // Forgot Password Routes
  static const String forgotPassword = '/forgotPassword';
  static const String verifyResetOtp = '/verifyResetOtp';
  static const String resetPassword = '/resetPassword';
  
  // Emergency
  static const String emergency = '/emergency';
  
  // Currency
  static const String currencyConverter = '/currency/converter';
  
  // Public Vendor Services
  static const String publicVendorServices = '/vendor/services/public';
  static const String publicVendorServiceDetails = '/vendor/services/public/:id';
  
  // Digital Directory
  static const String categories = '/categories';
  static const String categoryApps = '/categories/:id/apps';
  
  // Geographical Guides
  static const String geographicalDirectory = '/geographical-directory';
  static const String applyAsTrader = '/apply-as-trader';
  static const String myGeographicalServices = '/my-geographical-services';
  static const String myGeographicalServiceDetails = '/my-geographical-services/:id';
  static const String newGeographicalGuide = '/geographical-guides/new';
  static const String editGeographicalGuide = '/geographical-guides/:id/edit';
  static const String geographicalGuideDetails = '/geographical-guides/:id';
  
  // Bags
  static const String bagDetails = '/bags/:id';
  static const String bagAnalysis = '/bags/:id/analysis';
  static const String createBag = '/bags/create';
  static const String editBag = '/bags/:id/edit';
  static const String addItems = '/bags/:id/add-items';
}
