import 'dart:io';

import 'package:season_app/features/geographical_guides/data/datasources/geographical_guides_remote_datasource.dart';
import 'package:season_app/features/geographical_guides/data/models/geographical_guide_models.dart';

class GeographicalGuidesRepository {
  final GeographicalGuidesRemoteDataSource _remoteDataSource;

  GeographicalGuidesRepository(this._remoteDataSource);

  Future<List<City>> getCities(String? countryCode) async {
    return await _remoteDataSource.getCities(countryCode);
  }

  Future<List<GeographicalCategory>> getGeographicalCategories() async {
    return await _remoteDataSource.getGeographicalCategories();
  }

  Future<GeographicalCategory> getGeographicalCategory(int id) async {
    return await _remoteDataSource.getGeographicalCategory(id);
  }

  Future<List<GeographicalSubCategory>> getGeographicalSubCategories({
    int? geographicalCategoryId,
  }) async {
    return await _remoteDataSource.getGeographicalSubCategories(
      geographicalCategoryId: geographicalCategoryId,
    );
  }

  Future<GeographicalSubCategory> getGeographicalSubCategory(int id) async {
    return await _remoteDataSource.getGeographicalSubCategory(id);
  }

  Future<List<GeographicalGuide>> getGeographicalGuides({
    String? countryCode,
    int? cityId,
    int? geographicalCategoryId,
    int? geographicalSubCategoryId,
  }) async {
    return await _remoteDataSource.getGeographicalGuides(
      countryCode: countryCode,
      cityId: cityId,
      geographicalCategoryId: geographicalCategoryId,
      geographicalSubCategoryId: geographicalSubCategoryId,
    );
  }

  Future<List<GeographicalGuide>> getMyGeographicalGuides() async {
    return await _remoteDataSource.getMyGeographicalGuides();
  }

  Future<GeographicalGuide> getMyGeographicalGuide(int id) async {
    return await _remoteDataSource.getMyGeographicalGuide(id);
  }

  Future<GeographicalGuide> getGeographicalGuide(int id) async {
    return await _remoteDataSource.getGeographicalGuide(id);
  }

  Future<GeographicalGuide> createGeographicalGuide({
    required int geographicalCategoryId,
    int? geographicalSubCategoryId,
    required String serviceName,
    String? description,
    String? phone1,
    String? phone2,
    required int countryId,
    required int cityId,
    String? address,
    double? latitude,
    double? longitude,
    String? website,
    File? commercialRegister,
    String? establishmentNumber,
  }) async {
    return await _remoteDataSource.createGeographicalGuide(
      geographicalCategoryId: geographicalCategoryId,
      geographicalSubCategoryId: geographicalSubCategoryId,
      serviceName: serviceName,
      description: description,
      phone1: phone1,
      phone2: phone2,
      countryId: countryId,
      cityId: cityId,
      address: address,
      latitude: latitude,
      longitude: longitude,
      website: website,
      commercialRegister: commercialRegister,
      establishmentNumber: establishmentNumber,
    );
  }

  Future<GeographicalGuide> updateGeographicalGuide({
    required int id,
    int? geographicalCategoryId,
    int? geographicalSubCategoryId,
    String? serviceName,
    String? description,
    String? phone1,
    String? phone2,
    int? countryId,
    int? cityId,
    String? address,
    double? latitude,
    double? longitude,
    String? website,
    File? commercialRegister,
    String? establishmentNumber,
  }) async {
    return await _remoteDataSource.updateGeographicalGuide(
      id: id,
      geographicalCategoryId: geographicalCategoryId,
      geographicalSubCategoryId: geographicalSubCategoryId,
      serviceName: serviceName,
      description: description,
      phone1: phone1,
      phone2: phone2,
      countryId: countryId,
      cityId: cityId,
      address: address,
      latitude: latitude,
      longitude: longitude,
      website: website,
      commercialRegister: commercialRegister,
      establishmentNumber: establishmentNumber,
    );
  }

  Future<void> deleteGeographicalGuide(int id) async {
    return await _remoteDataSource.deleteGeographicalGuide(id);
  }
}

