import 'package:flutter/material.dart';
import 'package:asv_client/screens/room/components/chat_view.dart';
import 'package:asv_client/data/room_client_socket_impl.dart';
import 'package:asv_client/data/room_client.dart';
import 'package:asv_client/screens/room/components/meet_view.dart';

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
    // double width = MediaQuery.of(context).size.width;

    return Scaffold(
      drawer: SizedBox(
        width: 300,
        child: ChatView(
          client: roomClient,
        ),
      ),
      appBar: AppBar(
        title: Text('Room ${widget.roomId}'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          Builder(builder: (context) {
            return IconButton(
              icon: Icon(Icons.chat_outlined),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }),
        ],
      ),
      body: SizedBox.expand(
        child: SafeArea(
            child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
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
                ],
              ),
            ),
            // SizedBox(
            //   width: 300,
            //   child: ChatView(
            //     client: roomClient,
            //   ),
            // )
          ],
        )),
      ),
    );
  }
}
