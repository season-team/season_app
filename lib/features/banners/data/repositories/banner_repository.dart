import 'package:season_app/features/banners/data/datasources/banner_remote_datasource.dart';
import 'package:season_app/features/banners/data/models/banner_model.dart';

class BannerRepository {
  final BannerRemoteDataSource remoteDataSource;

  BannerRepository(this.remoteDataSource);

  Future<List<BannerModel>> getAllBanners(String language) =>
      remoteDataSource.getAllBanners(language);
}
