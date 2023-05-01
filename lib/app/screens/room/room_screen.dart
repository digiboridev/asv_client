import 'package:flutter/material.dart';
import 'package:asv_client/app/controllers/chat_view_controller.dart';
import 'package:asv_client/app/controllers/meet_view_controller.dart';
import 'package:asv_client/data/transport/room_client.dart';
import 'package:asv_client/data/transport/room_client_socket_impl.dart';
import 'package:asv_client/app/screens/room/components/chat_view.dart';
import 'package:asv_client/app/screens/room/components/meet_view.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({Key? key, required this.roomId}) : super(key: key);

  final String roomId;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late final RoomClient roomClient;
  late final ChatViewController chatViewController;
  late final MeetViewController meetViewController;

  @override
  void initState() {
    super.initState();
    roomClient = RoomClientSocketImpl(roomId: widget.roomId);
    chatViewController = ChatViewController(roomClient: roomClient);
    meetViewController = MeetViewController(roomClient: roomClient);
  }

  @override
  void dispose() {
    super.dispose();
    roomClient.dispose();
    chatViewController.dispose();
    meetViewController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer(),
      appBar: appbar(),
      body: body(),
    );
  }

  AppBar appbar() {
    return AppBar(
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
    );
  }

  Widget drawer() {
    return SizedBox(
      width: 300,
      child: ChatViewControllerProvider(
        notifier: chatViewController,
        child: ChatView(),
      ),
    );
  }

  Widget body() {
    return SizedBox.expand(
      child: SafeArea(
        child: Column(
          children: [
            connectionStatus(),
            Expanded(
              child: MeetViewControllerProvider(
                notifier: meetViewController,
                child: MeetView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget connectionStatus() {
    return Container(
      color: Colors.grey.shade100,
      child: AnimatedBuilder(
          animation: roomClient,
          builder: (context, child) {
            if (roomClient.connectionState == RoomConnectionState.connecting) {
              return Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
                    SizedBox(width: 8),
                    Text('Connecting...'),
                  ],
                ),
              );
            }

            if (roomClient.connectionState == RoomConnectionState.disconnected) {
              return Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 24, height: 24, child: Icon(Icons.sync_disabled, color: Colors.pink)),
                    SizedBox(width: 8),
                    Text('Disconnected'),
                  ],
                ),
              );
            }

            if (roomClient.connectionState == RoomConnectionState.connectError) {
              return Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 24, height: 24, child: Icon(Icons.sync_problem, color: Colors.pink)),
                    SizedBox(width: 8),
                    Text('Cannot connect to server'),
                  ],
                ),
              );
            }
            return SizedBox();
          }),
    );
  }
}

class ChatViewControllerProvider extends InheritedNotifier<ChatViewController> {
  const ChatViewControllerProvider({super.key, required super.child, super.notifier});

  static ChatViewController watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChatViewControllerProvider>()!.notifier!;
  }

  static ChatViewController read(BuildContext context) {
    return context.findAncestorWidgetOfExactType<ChatViewControllerProvider>()!.notifier!;
  }
}

class MeetViewControllerProvider extends InheritedNotifier<MeetViewController> {
  const MeetViewControllerProvider({super.key, required super.child, super.notifier});

  static MeetViewController watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MeetViewControllerProvider>()!.notifier!;
  }

  static MeetViewController read(BuildContext context) {
    return context.findAncestorWidgetOfExactType<MeetViewControllerProvider>()!.notifier!;
  }
}
