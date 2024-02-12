import 'package:asv_client/app/router/pages.dart';
import 'package:flutter/material.dart';

abstract class AppPath {
  AppPath();

  Page get page;
  Uri get uri;

  factory AppPath.fromUri(Uri uri) {
    if (uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first == HomePath.segment) {
        return HomePath();
      }
      if (uri.pathSegments.first == RoomPath.segment) {
        if (uri.queryParameters.containsKey('roomId') && uri.queryParameters['roomId']!.isNotEmpty) {
          return RoomPath(uri.queryParameters['roomId']!);
        }
      }
    }

    return HomePath();
  }
}

class HomePath extends AppPath {
  HomePath();
  static String get segment => 'home';

  @override
  Page get page => HomePage();

  @override
  Uri get uri => Uri(path: '/$segment');
}

class RoomPath extends AppPath {
  RoomPath(this.roomId);
  final String roomId;
  static String get segment => 'room';

  @override
  Page get page => RoomPage(key: ValueKey(roomId), roomId: roomId);

  @override
  Uri get uri => Uri(path: '/$segment', queryParameters: {'roomId': roomId});
}
