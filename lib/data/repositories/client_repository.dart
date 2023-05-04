import 'package:asv_client/data/models/client.dart';

abstract class ClientRepository {
  /// Returns the current client information
  Future<Client> getClient();

  /// Updates the current client information
  Future updateClient(Client client);
}
