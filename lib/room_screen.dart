import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/chat_view.dart';
import 'package:asv_client/controllers/room_client_socket_impl.dart';
import 'package:asv_client/domain/controllers/room_client.dart';
import 'package:asv_client/meet_view.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  final String roomId;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late final RoomClient roomClient;

  @override
  void initState() {
    super.initState();
    roomClient = RoomClientSocketImpl(roomId: widget.roomId);
  }

  @override
  void dispose() {
    super.dispose();
    roomClient.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: SafeArea(
            child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text('Room: ${widget.roomId}'),
                  Text('Connection status: ${roomClient.isActive}'),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => roomClient.sendMessage('Hello'),
                    child: const Text('Send message'),
                  ),
                  Expanded(
                      child: MeetView(
                    roomClient: roomClient,
                  )),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: ChatView(
                client: roomClient,
              ),
            )
          ],
        )),
      ),
    );
  }
}
