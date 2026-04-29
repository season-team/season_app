// // core/router/guards/auth_guard.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../features/auth/controllers/signup_controller.dart';
// import '../routes.dart';
//
// Future<bool> authGuard(Ref ref, GoRouterState state) async {
//   final user = ref.read(authControllerProvider).valueOrNull;
//
//   if (user == null) {
//     // المستخدم مش داخل → رجعه على صفحة الـ login
//     return false;
//   }
//   return true;
// }
