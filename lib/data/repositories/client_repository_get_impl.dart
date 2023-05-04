import 'package:asv_client/data/models/client.dart';
import 'package:asv_client/data/repositories/client_repository.dart';
import 'package:get_storage/get_storage.dart';

class ClientRepositoryGetImpl implements ClientRepository {
  final _storage = GetStorage();

  @override
  Future<Client> getClient() async {
    String? maybeClient = _storage.read('client');

    if (maybeClient != null) {
      return Client.fromJson(maybeClient);
    } else {
      // Create a new default client information
      Client newClient = Client.empty();
      await updateClient(newClient);
      return newClient;
    }
  }

  @override
  Future updateClient(Client client) async {
    await _storage.write('client', client.toJson());
  }
}
