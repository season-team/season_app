import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/digital_directory/data/datasources/digital_directory_remote_datasource.dart';
import 'package:season_app/features/digital_directory/data/models/category_app_model.dart';
import 'package:season_app/features/digital_directory/data/models/category_model.dart';
import 'package:season_app/features/digital_directory/data/repositories/digital_directory_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

final digitalDirectoryRemoteDataSourceProvider =
    Provider<DigitalDirectoryRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DigitalDirectoryRemoteDataSource(dio);
});

final digitalDirectoryRepositoryProvider =
    Provider<DigitalDirectoryRepository>((ref) {
  final remoteDataSource = ref.watch(digitalDirectoryRemoteDataSourceProvider);
  return DigitalDirectoryRepository(remoteDataSource);
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  ref.watch(localeProvider); // Watch locale to refetch when language changes
  return ref.read(digitalDirectoryRepositoryProvider).getCategories();
});

final categoryAppsProvider =
    FutureProvider.family<List<CategoryAppModel>, int>((ref, categoryId) async {
  ref.watch(localeProvider); // Watch locale to refetch when language changes
  return ref.read(digitalDirectoryRepositoryProvider).getCategoryApps(categoryId);
});
