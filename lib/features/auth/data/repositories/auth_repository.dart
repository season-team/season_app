import 'package:dio/dio.dart';
import 'package:season_app/core/services/auth_service.dart';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/core/services/background_location_service.dart';
import 'package:season_app/features/auth/data/datasources/auth_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepository(this.remoteDataSource);

  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? notificationToken,
  }) async {
    try {
      final response = await remoteDataSource.registerUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        notificationToken: notificationToken,
      );

      if (response.statusCode == 201) {
        return response.data["message"] ?? "OTP sent successfully.";
      } else {
        throw Exception(response.data["message"] ?? "Registration failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'حدث خطأ غير متوقع';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء التسجيل');
      }
    }
  }

  Future<String> login({
    required String email,
    required String password,
    String? notificationToken,
  }) async {
    try {
      final response = await remoteDataSource.loginUser(
        email: email,
        password: password,
        notificationToken: notificationToken,
      );

      // Debug: Print the response structure
      print('🔍 Login Response: ${response.data}');
      
      if (response.statusCode == 200) {
        // Try to extract token from various possible locations
        dynamic token;
        dynamic userId;
        
        // Check multiple possible paths for token
        if (response.data is Map) {
          // Try: data.token
          token = response.data['data']?['token'];
          
          // Try: token
          token ??= response.data['token'];
          
          // Try: data.access_token
          token ??= response.data['data']?['access_token'];
          
          // Try: access_token
          token ??= response.data['access_token'];
          
          // Get user ID - check multiple possible locations
          userId = response.data['data']?['user']?['id']?.toString();
          userId ??= response.data['user']?['id']?.toString();
          userId ??= response.data['userInfo']?['id']?.toString(); // Season API uses 'userInfo'
        }
        
        print('🔑 Extracted Token: ${token?.toString().substring(0, token.toString().length > 30 ? 30 : token.toString().length)}...');
        print('👤 User ID: $userId');
        
        if (token != null && token.toString().isNotEmpty) {
          await AuthService.saveAuthData(
            token: token.toString(),
            userId: userId,
            email: email,
          );
          
          // Set token in DioHelper immediately
          DioHelper.instance.setAccessToken(token.toString());
          print('✅ Token saved and set in DioHelper');
          
          // Fetch and store group IDs for background location tracking
          // This ensures group IDs are available even when app is terminated
          try {
            await startBackgroundLocationTracking();
            print('✅ Background location tracking started after login');
          } catch (e) {
            print('⚠️ Error starting background location tracking after login: $e');
          }
        } else {
          print('⚠️ No token in login response - might require OTP verification');
        }
        
        return response.data["message"] ?? "Login successful.";
      } else {
        throw Exception(response.data["message"] ?? "Login failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final message = e.response?.data['message'] ?? 'Invalid credentials';
        throw Exception(message);
      } else if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'حدث خطأ غير متوقع';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء تسجيل الدخول');
      }
    }
  }

  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await remoteDataSource.verifyOtp(
        email: email,
        otp: otp,
      );

      // Debug: Print the response structure
      print('🔍 OTP Verification Response: ${response.data}');
      
      if (response.statusCode == 200) {
        // Try to extract token from various possible locations
        dynamic token;
        dynamic userId;
        
        // Check multiple possible paths for token
        if (response.data is Map) {
          // Try: data.token
          token = response.data['data']?['token'];
          
          // Try: token
          token ??= response.data['token'];
          
          // Try: data.access_token
          token ??= response.data['data']?['access_token'];
          
          // Try: access_token
          token ??= response.data['access_token'];
          
          // Get user ID - check multiple possible locations
          userId = response.data['data']?['user']?['id']?.toString();
          userId ??= response.data['user']?['id']?.toString();
          userId ??= response.data['userInfo']?['id']?.toString(); // Season API uses 'userInfo'
        }
        
        print('🔑 Extracted Token: ${token?.toString().substring(0, token.toString().length > 30 ? 30 : token.toString().length)}...');
        print('👤 User ID: $userId');
        
        if (token != null && token.toString().isNotEmpty) {
          await AuthService.saveAuthData(
            token: token.toString(),
            userId: userId,
            email: email,
          );
          
          // Set token in DioHelper immediately
          DioHelper.instance.setAccessToken(token.toString());
          print('✅ Token saved and set in DioHelper');
          
          // Fetch and store group IDs for background location tracking
          // This ensures group IDs are available even when app is terminated
          try {
            await startBackgroundLocationTracking();
            print('✅ Background location tracking started after OTP verification');
          } catch (e) {
            print('⚠️ Error starting background location tracking after OTP: $e');
          }
        } else {
          print('⚠️ No token found in OTP verification response');
        }
        
        return response.data["message"] ?? "OTP verified successfully.";
      } else {
        throw Exception(response.data["message"] ?? "OTP verification failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid OTP';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء التحقق من الرمز');
      }
    }
  }

  Future<String> resendOtp({
    required String email,
  }) async {
    try {
      final response = await remoteDataSource.resendOtp(
        email: email,
      );

      if (response.statusCode == 200) {
        return response.data["message"] ?? "OTP resent successfully.";
      } else {
        throw Exception(response.data["message"] ?? "Failed to resend OTP");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'حدث خطأ غير متوقع';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء إعادة إرسال الرمز');
      }
    }
  }

  Future<String> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await remoteDataSource.forgotPassword(
        email: email,
      );

      if (response.statusCode == 200) {
        return response.data["message"] ?? "Reset OTP sent successfully.";
      } else {
        throw Exception(response.data["message"] ?? "Failed to send reset OTP");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'حدث خطأ غير متوقع';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء إرسال رمز إعادة تعيين كلمة المرور');
      }
    }
  }

  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await remoteDataSource.verifyResetOtp(
        email: email,
        otp: otp,
      );

      if (response.statusCode == 200) {
        return response.data["message"] ?? "Reset OTP verified successfully.";
      } else {
        throw Exception(response.data["message"] ?? "Reset OTP verification failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid reset OTP';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء التحقق من رمز إعادة تعيين كلمة المرور');
      }
    }
  }

  Future<String> resendResetOtp({
    required String email,
  }) async {
    try {
      final response = await remoteDataSource.resendResetOtp(
        email: email,
      );

      if (response.statusCode == 200) {
        return response.data["message"] ?? "Reset OTP resent successfully.";
      } else {
        throw Exception(response.data["message"] ?? "Failed to resend reset OTP");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'حدث خطأ غير متوقع';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء إعادة إرسال رمز إعادة تعيين كلمة المرور');
      }
    }
  }

  Future<String> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await remoteDataSource.resetPassword(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.statusCode == 200) {
        return response.data["message"] ?? "Password reset successfully.";
      } else {
        throw Exception(response.data["message"] ?? "Password reset failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'حدث خطأ غير متوقع';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء إعادة تعيين كلمة المرور');
      }
    }
  }

  // Logout method
  Future<void> logout() async {
    await AuthService.logout();
    // Clear token from DioHelper
    DioHelper.instance.clearTokens();
  }

  /// Login with Google
  Future<String> loginWithGoogle({
    required String idToken,
    required String accessToken,
    String? notificationToken,
  }) async {
    try {
      final response = await remoteDataSource.loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
        notificationToken: notificationToken,
      );

      if (response.statusCode == 200) {
        // Extract token and user data
        dynamic token;
        dynamic userId;
        String? email;

        if (response.data is Map) {
          token = response.data['data']?['token'] ??
              response.data['token'] ??
              response.data['data']?['access_token'] ??
              response.data['access_token'];

          userId = response.data['data']?['user']?['id']?.toString() ??
              response.data['user']?['id']?.toString() ??
              response.data['data']?['userInfo']?['id']?.toString() ??
              response.data['userInfo']?['id']?.toString();

          email = response.data['data']?['user']?['email'] ??
              response.data['user']?['email'] ??
              response.data['data']?['userInfo']?['email'] ??
              response.data['userInfo']?['email'];
        }

        if (token != null && token.toString().isNotEmpty) {
          await AuthService.saveAuthData(
            token: token.toString(),
            userId: userId,
            email: email,
          );

          DioHelper.instance.setAccessToken(token.toString());

          try {
            await startBackgroundLocationTracking();
          } catch (e) {
            print('⚠️ Error starting background location tracking: $e');
          }
        }

        return response.data["message"] ?? "Login successful.";
      } else {
        throw Exception(response.data["message"] ?? "Google login failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // User not found - this is expected for new users
        final message = e.response?.data['message'] ?? 'User not found. Please register first.';
        throw Exception('404: $message'); // Prefix with 404 for easier detection
      } else if (e.response?.statusCode == 401) {
        final message = e.response?.data['message'] ?? 'Invalid Google credentials';
        throw Exception(message);
      } else if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Google login failed';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء تسجيل الدخول باستخدام Google');
      }
    }
  }

  /// Register with Google
  Future<String> registerWithGoogle({
    required String idToken,
    required String accessToken,
    String? notificationToken,
  }) async {
    try {
      final response = await remoteDataSource.registerWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
        notificationToken: notificationToken,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if user needs OTP verification or is directly logged in
        dynamic token;
        dynamic userId;
        String? email;

        if (response.data is Map) {
          token = response.data['data']?['token'] ??
              response.data['token'] ??
              response.data['data']?['access_token'] ??
              response.data['access_token'];

          userId = response.data['data']?['user']?['id']?.toString() ??
              response.data['user']?['id']?.toString() ??
              response.data['data']?['userInfo']?['id']?.toString() ??
              response.data['userInfo']?['id']?.toString();

          email = response.data['data']?['user']?['email'] ??
              response.data['user']?['email'] ??
              response.data['data']?['userInfo']?['email'] ??
              response.data['userInfo']?['email'];
        }

        // If token exists, user is logged in directly
        if (token != null && token.toString().isNotEmpty) {
          await AuthService.saveAuthData(
            token: token.toString(),
            userId: userId,
            email: email,
          );

          DioHelper.instance.setAccessToken(token.toString());

          try {
            await startBackgroundLocationTracking();
          } catch (e) {
            print('⚠️ Error starting background location tracking: $e');
          }

          return response.data["message"] ?? "Registration successful.";
        } else {
          // User needs OTP verification
          return response.data["message"] ?? "OTP sent successfully.";
        }
      } else {
        throw Exception(response.data["message"] ?? "Google registration failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Google registration failed';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء التسجيل باستخدام Google');
      }
    }
  }

  /// Login with Apple
  Future<String> loginWithApple({
    required String idToken,
    String? authorizationCode,
    String? notificationToken,
  }) async {
    try {
      final response = await remoteDataSource.loginWithApple(
        idToken: idToken,
        authorizationCode: authorizationCode,
        notificationToken: notificationToken,
      );

      if (response.statusCode == 200) {
        // Extract token and user data
        dynamic token;
        dynamic userId;
        String? email;

        if (response.data is Map) {
          token = response.data['data']?['token'] ??
              response.data['token'] ??
              response.data['data']?['access_token'] ??
              response.data['access_token'];

          userId = response.data['data']?['user']?['id']?.toString() ??
              response.data['user']?['id']?.toString() ??
              response.data['data']?['userInfo']?['id']?.toString() ??
              response.data['userInfo']?['id']?.toString();

          email = response.data['data']?['user']?['email'] ??
              response.data['user']?['email'] ??
              response.data['data']?['userInfo']?['email'] ??
              response.data['userInfo']?['email'];
        }

        if (token != null && token.toString().isNotEmpty) {
          await AuthService.saveAuthData(
            token: token.toString(),
            userId: userId,
            email: email,
          );

          DioHelper.instance.setAccessToken(token.toString());

          try {
            await startBackgroundLocationTracking();
          } catch (e) {
            print('⚠️ Error starting background location tracking: $e');
          }
        }

        return response.data["message"] ?? "Login successful.";
      } else {
        throw Exception(response.data["message"] ?? "Apple login failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // User not found - this is expected for new users
        final message = e.response?.data['message'] ?? 'User not found. Please register first.';
        throw Exception('404: $message'); // Prefix with 404 for easier detection
      } else if (e.response?.statusCode == 401) {
        final message = e.response?.data['message'] ?? 'Invalid Apple credentials';
        throw Exception(message);
      } else if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Apple login failed';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء تسجيل الدخول باستخدام Apple');
      }
    }
  }

  /// Register with Apple
  Future<String> registerWithApple({
    required String idToken,
    String? authorizationCode,
    String? notificationToken,
  }) async {
    try {
      final response = await remoteDataSource.registerWithApple(
        idToken: idToken,
        authorizationCode: authorizationCode,
        notificationToken: notificationToken,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if user needs OTP verification or is directly logged in
        dynamic token;
        dynamic userId;
        String? email;

        if (response.data is Map) {
          token = response.data['data']?['token'] ??
              response.data['token'] ??
              response.data['data']?['access_token'] ??
              response.data['access_token'];

          userId = response.data['data']?['user']?['id']?.toString() ??
              response.data['user']?['id']?.toString() ??
              response.data['data']?['userInfo']?['id']?.toString() ??
              response.data['userInfo']?['id']?.toString();

          email = response.data['data']?['user']?['email'] ??
              response.data['user']?['email'] ??
              response.data['data']?['userInfo']?['email'] ??
              response.data['userInfo']?['email'];
        }

        // If token exists, user is logged in directly
        if (token != null && token.toString().isNotEmpty) {
          await AuthService.saveAuthData(
            token: token.toString(),
            userId: userId,
            email: email,
          );

          DioHelper.instance.setAccessToken(token.toString());

          try {
            await startBackgroundLocationTracking();
          } catch (e) {
            print('⚠️ Error starting background location tracking: $e');
          }

          return response.data["message"] ?? "Registration successful.";
        } else {
          // User needs OTP verification
          return response.data["message"] ?? "OTP sent successfully.";
        }
      } else {
        throw Exception(response.data["message"] ?? "Apple registration failed");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Apple registration failed';
        throw Exception(message);
      } else {
        throw Exception('حدث خطأ أثناء التسجيل باستخدام Apple');
      }
    }
  }
}
