import 'dart:async';
import 'package:asv_client/data/room_client.dart';
import 'package:asv_client/data/room_events.dart';
import 'package:flutter/foundation.dart';

class ChatViewController extends ChangeNotifier {
  ChatViewController({
    required this.roomClient,
  }) {
    _roomEventSubscription = roomClient.eventStream.listen(roomEventsHandler);
  }

  final RoomClient roomClient;
  final List<RoomEvent> _chatHistory = [];
  List<RoomEvent> get chatHistory => _chatHistory;
  final Set<String> _typingClients = {};
  Set<String> get typingClients => _typingClients;
  late final StreamSubscription _roomEventSubscription;

  roomEventsHandler(RoomEvent event) {
    if (event is NewMessage || event is ClientJoin || event is ClientLeave) {
      chatHistory.add(event);
    }

    if (event is ClientTyping) {
      typingClients.add(event.clientId);
    }

    if (event is ClientTypingCancel && typingClients.contains(event.clientId)) {
      typingClients.remove(event.clientId);
    }

    if (event is ClientLeave && typingClients.contains(event.clientId)) {
      typingClients.remove(event.clientId);
    }

    if (event is NewMessage && typingClients.contains(event.clientId)) {
      typingClients.remove(event.clientId);
    }

    notifyListeners();
  }

  startedTyping() {
    roomClient.sendTyping();
  }

  stoppedTyping() {
    roomClient.sendTypingCancel();
  }

  sendMessage(String message) {
    roomClient.sendMessage(message);
  }

  @override
  void dispose() {
    super.dispose();
    _roomEventSubscription.cancel();
  }
}
