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
              child: AnimatedBuilder(
                  animation: roomClient,
                  builder: (context, _) {
                    if (roomClient.isConnected) {
                      return MeetView(
                        roomClient: roomClient,
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  }),
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
