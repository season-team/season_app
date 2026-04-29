import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider =
StreamProvider<ConnectivityResult>((ref) async* {
  final connectivity = Connectivity();

  // نتاكد من الـ type ونرجع أول قيمة لو جاي List
  await for (final result in connectivity.onConnectivityChanged) {
    // ناخد أول نتيجة لو list
    yield result.isNotEmpty ? result.first : ConnectivityResult.none;
    }
});

/// Helper provider بسيط يرجع bool
final isConnectedProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityProvider).value;
  return result != ConnectivityResult.none;
});
