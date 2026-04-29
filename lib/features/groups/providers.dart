import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/groups/controllers/groups_controller.dart';
import 'package:season_app/features/groups/data/datasources/groups_datasource.dart';
import 'package:season_app/features/groups/data/repositories/groups_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';

// Datasource Provider
final groupsDataSourceProvider = Provider<GroupsRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider); // Use reactive dioProvider that updates Accept-Language
  return GroupsRemoteDataSource(dio);
});

// Repository Provider
final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final dataSource = ref.watch(groupsDataSourceProvider);
  return GroupsRepository(dataSource);
});

// Controller Provider
final groupsControllerProvider =
    NotifierProvider<GroupsController, GroupsState>(() {
  return GroupsController();
});

