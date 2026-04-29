import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/features/events/data/datasources/events_remote_datasource.dart';
import 'package:season_app/features/events/data/models/event_model.dart';
import 'package:season_app/features/events/data/repositories/events_repository.dart';
import 'package:season_app/shared/providers/app_providers.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

final eventsRemoteDataSourceProvider =
    Provider<EventsRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return EventsRemoteDataSource(dio);
});

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final remoteDataSource = ref.watch(eventsRemoteDataSourceProvider);
  return EventsRepository(remoteDataSource);
});

final eventsProvider = FutureProvider<EventsResponse>((ref) async {
  // Watch locale to refetch when language changes
  final locale = ref.watch(localeProvider);
  return ref.read(eventsRepositoryProvider).getEvents(locale.languageCode);
});
