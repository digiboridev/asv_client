import 'package:asv_client/data/repositories/client_repository.dart';
import 'package:asv_client/data/repositories/client_repository_get_impl.dart';
import 'package:asv_client/data/transport/room_client.dart';
import 'package:asv_client/data/transport/room_client_socket_impl.dart';

abstract class ServiceLocator {
  static ClientRepository get createClientRepository => ClientRepositoryGetImpl();
  static RoomClient createRoomClient(String roomId) => RoomClientSocketImpl(roomId: roomId);
}
