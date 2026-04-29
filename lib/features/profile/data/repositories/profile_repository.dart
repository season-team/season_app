import 'dart:io';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/features/profile/data/datasources/profile_datasource.dart';
import 'package:season_app/features/profile/data/models/profile_model.dart';

class ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepository(this.remoteDataSource);

  Future<ProfileModel> getProfile() async {
    try {
      final response = await remoteDataSource.getProfile();
      
      if (response.data['status'] == 200) {
        return ProfileModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<ProfileModel> updateProfile({
    required String name,
    String? nickname,
    required String email,
    String? phone,
    String? birthDate,
    String? gender,
    int? avatarId,
    File? photoFile,
  }) async {
    try {
      print('🔄 Repository: photoFile is ${photoFile != null ? "provided" : "null"}');
      print('🔄 Repository: avatarId is $avatarId');

      final response = await remoteDataSource.updateProfile(
        name: name,
        nickname: nickname,
        email: email,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        avatarId: avatarId,
        photoFile: photoFile,
      );

      if (response.data['status'] == 200) {
        return ProfileModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }
}

