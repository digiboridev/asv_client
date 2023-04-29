import 'package:asv_client/controllers/chat_view_controller.dart';
import 'package:asv_client/controllers/meet_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:asv_client/screens/room/components/chat_view.dart';
import 'package:asv_client/data/room_client_socket_impl.dart';
import 'package:asv_client/data/room_client.dart';
import 'package:asv_client/screens/room/components/meet_view.dart';

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

    // TODO move to declarative
    roomClient.addListener(() {
      if (roomClient.connectionState == RoomConnectionState.connecting) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
          content: Text('Connecting to room: ${widget.roomId}'),
          actions: [
            TextButton(
              child: Text(''),
              onPressed: () {},
            ),
          ],
        ));
      }

      if (roomClient.connectionState == RoomConnectionState.connected) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        final banner = ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          leading: Icon(Icons.sync, color: Colors.pink),
          content: Text('Connected to room ${widget.roomId}'),
          actions: [
            TextButton(
              child: Text(''),
              onPressed: () {},
            ),
          ],
        ));
        Future.delayed(Duration(seconds: 2), () => banner.close());
      }

      if (roomClient.connectionState == RoomConnectionState.disconnected) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        final banner = ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          leading: Icon(Icons.sync_disabled, color: Colors.pink),
          content: Text('Disconnected from room ${widget.roomId}'),
          actions: [
            TextButton(
              child: Text(''),
              onPressed: () {},
            ),
          ],
        ));
        Future.delayed(Duration(seconds: 2), () => banner.close());
      }

      if (roomClient.connectionState == RoomConnectionState.connectError) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          leading: Icon(Icons.sync_problem, color: Colors.pink),
          content: Text('Cannot connect to room ${widget.roomId}'),
          actions: [
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                roomClient.connect();
              },
            ),
          ],
        ));
      }
    });
  }

  @override
  void dispose() {
    // ScaffoldMessenger.of(context).hideCurrentMaterialBanner();

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
            // AnimatedBuilder(
            //     animation: roomClient,
            //     builder: (context, child) {
            //       return Text('Connection status: ${roomClient.connectionState.name}');
            //     }),
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
}

// class RoomClientProvider extends InheritedNotifier<RoomClient> {
//   const RoomClientProvider({super.key, required super.child, super.notifier});

//   static RoomClient watch(BuildContext context) {
//     return context.dependOnInheritedWidgetOfExactType<RoomClientProvider>()!.notifier!;
//   }

//   static RoomClient read(BuildContext context) {
//     return context.findAncestorWidgetOfExactType<RoomClientProvider>()!.notifier!;
//   }
// }

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
