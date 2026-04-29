import 'package:season_app/features/events/data/datasources/events_remote_datasource.dart';
import 'package:season_app/features/events/data/models/event_model.dart';

class EventsRepository {
  final EventsRemoteDataSource _remoteDataSource;

  EventsRepository(this._remoteDataSource);

  Future<EventsResponse> getEvents(String language) =>
      _remoteDataSource.getEvents(language);
}
