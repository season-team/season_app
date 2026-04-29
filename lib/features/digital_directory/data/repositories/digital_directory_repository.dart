import 'package:season_app/features/digital_directory/data/datasources/digital_directory_remote_datasource.dart';
import 'package:season_app/features/digital_directory/data/models/category_app_model.dart';
import 'package:season_app/features/digital_directory/data/models/category_model.dart';

class DigitalDirectoryRepository {
  final DigitalDirectoryRemoteDataSource _remoteDataSource;

  DigitalDirectoryRepository(this._remoteDataSource);

  Future<List<CategoryModel>> getCategories() => _remoteDataSource.getCategories();

  Future<List<CategoryAppModel>> getCategoryApps(int categoryId) =>
      _remoteDataSource.getCategoryApps(categoryId);
}
