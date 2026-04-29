class ApiEndpoints {
  // 🌍 Base URL
  static const String baseUrl = 'https://seasonksa.com/api';

  // 🔐 Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String loginWithGoogle = '/auth/login/google';
  static const String loginWithApple = '/auth/login/apple';
  static const String registerWithGoogle = '/auth/register/google';
  static const String registerWithApple = '/auth/register/apple';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resendResetOtp = '/auth/resend-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String authProfile = '/auth/profile';

  // 👤 Profile
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String userQr = '/user/qr';

  // 🏠 Home
  static const String getPosts = '/posts';
  static const String getPostDetails = '/posts/{id}';

  // ⚙️ Settings
  static const String changePassword = '/user/change-password';

  // 🧑‍🔧 Vendor Services
  static const String serviceTypes = '/service-types';
  static const String vendorServices = '/vendor-services';
  static const String vendorServicesMyServices = '/vendor-services/my-services';
  static const String vendorServiceById = '/vendor-services/{id}';
  static const String vendorServiceMyServiceById = '/vendor-services/my-services/{id}';
  static const String vendorServiceEnable = '/vendor-services/{id}/enable';
  static const String vendorServiceForceDelete = '/vendor-services/{id}/forceDelete';

  // 🌎 Location
  static const String locationCountries = '/Location/countries';
  static const String locationCities = '/Location/cities';

  // 📍 Geographical Guides
  static const String geographicalGuides = '/geographical-guides';
  static const String geographicalGuidesMyServices = '/geographical-guides/my-services';
  static const String geographicalGuideMyServiceById = '/geographical-guides/my-services/{id}';
  static const String geographicalGuideById = '/geographical-guides/{id}';
  static const String geographicalCategories = '/geographical-categories';
  static const String geographicalSubCategories = '/geographical-sub-categories';

  // 🎒 Bag & Reminders
  static const String reminders = '/reminders';
  static const String reminderById = '/reminders/{id}';
  static const String bagTypes = '/bag-types';
  // Item Categories API (Smart Bags)
  static const String itemCategories = '/item-categories';
  static const String items = '/items';
  // Legacy endpoints (kept for backward compatibility)
  static const String itemsCategories = '/items/categories'; // Deprecated
  // Legacy endpoints (kept for backward compatibility if needed)
  static const String bagCategories = '/categories';
  static const String bagCategoryItems = '/categories/items';
  static const String bagDetails = '/travel-bag/details';
  static const String bagAddItem = '/travel-bag/add-item';
  static const String bagDeleteItem = '/travel-bag/items/{item_id}';
  static const String bagUpdateItemQuantity = '/travel-bag/items/{item_id}/quantity';
  static const String bagUpdateMaxWeight = '/travel-bag/max-weight';
  static const String bagTravelDate = '/travel-bag/travel-date';
  static const String bagReminder = '/travel-bag/reminder';
  static const String bagItems = '/travel-bag/items';
  static const String bagEstimateWeight = '/travel-bag/estimate-weight';

  // 🚨 Emergency
  static const String emergency = '/emergency';

  // 🎯 Banners
  static const String banners = '/banners';

  // 💱 Currency
  static const String currencyConvert = '/currency/convert';

  // 📱 Digital Directory
  static const String categories = '/categories';
  static const String digitalDirectoryCategoryApps = '/digital-directory/category-apps';

  // 📅 Events
  static const String events = '/gemini/events';

  // 👥 Groups
  static const String groups = '/groups';
  static const String groupById = '/groups/{id}';
  static const String groupLocation = '/groups/{id}/location';

  // 🎒 Smart Bags (Smart Packing Assistant)
  static const String smartBags = '/smart-bags';
  static const String smartBagById = '/smart-bags/{id}';
  static const String smartBagItems = '/smart-bags/{id}/items';
  static const String smartBagItemById = '/smart-bags/{bagId}/items/{itemId}';
  static const String smartBagTogglePacked = '/smart-bags/{bagId}/items/{itemId}/toggle-packed';
  static const String smartBagAnalyze = '/smart-bags/{id}/analyze';
  static const String smartBagAnalysisLatest = '/smart-bags/{id}/analysis/latest';
  static const String smartBagAnalysisHistory = '/smart-bags/{id}/analysis/history';
  static const String smartBagSmartAlert = '/smart-bags/{id}/smart-alert';
  // Item Categories
  static const String itemCategoryById = '/item-categories/{id}';
  // AI-Powered Smart Packing
  static const String aiCategories = '/smart-bags/ai/categories';
  static const String aiSuggestItems = '/smart-bags/ai/suggest-items';
  static const String aiAddItem = '/smart-bags/{bagId}/ai/add-item';
}
