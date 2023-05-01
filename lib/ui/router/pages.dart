import 'package:asv_client/screens/home/home_screen.dart';
import 'package:asv_client/screens/room/room_screen.dart';
import 'package:flutter/material.dart';

class HomePage extends Page {
  const HomePage({super.key});

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) {
        return Home();
      },
    );
  }
}

class RoomPage extends Page {
  const RoomPage({super.key, required this.roomId});
  final String roomId;

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) {
        return RoomScreen(
          roomId: roomId,
        );
      },
    );
  }
}
