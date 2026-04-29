import 'package:season_app/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:season_app/features/emergency/data/models/emergency_model.dart';

class EmergencyRepository {
  final EmergencyRemoteDataSource remoteDataSource;

  EmergencyRepository(this.remoteDataSource);

  Future<EmergencyModel> getEmergencyNumbers() =>
      remoteDataSource.getEmergencyNumbers();
}
