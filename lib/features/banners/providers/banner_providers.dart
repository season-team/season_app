import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/banners/data/datasources/banner_remote_datasource.dart';
import 'package:season_app/features/banners/data/models/banner_model.dart';
import 'package:season_app/features/banners/data/repositories/banner_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = BannerRemoteDataSource(dio);
  return BannerRepository(dataSource);
});

class BannerState {
  final List<BannerModel> banners;
  final bool isLoading;
  final String? error;

  const BannerState({
    this.banners = const [],
    this.isLoading = false,
    this.error,
  });

  BannerState copyWith({
    List<BannerModel>? banners,
    bool? isLoading,
    String? error,
  }) {
    return BannerState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BannerNotifier extends Notifier<BannerState> {
  // Lazily read repository from provider; safe across rebuilds
  BannerRepository get _repository => ref.read(bannerRepositoryProvider);
  String? _currentLanguage;

  @override
  BannerState build() {
    final language = ref.watch(localeProvider).languageCode;
    
    // Reload banners if language changed
    if (_currentLanguage != language) {
      _currentLanguage = language;
      Future.microtask(() => _loadBanners(language));
    }
    
    return const BannerState();
  }

  Future<void> _loadBanners(String language) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final banners = await _repository.getAllBanners(language);
      state = state.copyWith(
        banners: banners,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh(String language) async {
    await _loadBanners(language);
  }
}

final bannerControllerProvider =
    NotifierProvider<BannerNotifier, BannerState>(BannerNotifier.new);
