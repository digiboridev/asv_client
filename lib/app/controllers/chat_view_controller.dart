
import 'dart:async';
import 'package:asv_client/data/models/chat_entries.dart';
import 'package:asv_client/data/models/client.dart';
import 'package:asv_client/data/transport/room_client.dart';
import 'package:asv_client/data/transport/room_events.dart';
import 'package:flutter/foundation.dart';

class ChatViewController extends ChangeNotifier {
  ChatViewController({
    required RoomClient roomClient,
  }) : _roomClient = roomClient {
    _roomEventSubscription = roomClient.eventStream.listen(_roomEventsHandler);
  }

  final RoomClient _roomClient;
  late final StreamSubscription _roomEventSubscription;

  final List<ChatEntry> _chatHistory = [];
  List<ChatEntry> get chatHistory => _chatHistory;

  final Set<Client> _typingClients = {};
  Set<Client> get typingClients => _typingClients;

  _roomEventsHandler(RoomEvent event) {
    if (event is NewMessage) {
      chatHistory.add(ChatEntry.message(event.client.name, event.message));
      if (typingClients.contains(event.client)) typingClients.remove(event.client);
    }

    if (event is ClientJoin) {
      chatHistory.add(ChatEntry.userJoined(event.client.name));
    }

    if (event is ClientLeave) {
      chatHistory.add(ChatEntry.userLeft(event.client.name));
      if (typingClients.contains(event.client)) typingClients.remove(event.client);
    }

    if (event is ClientTyping) {
      typingClients.add(event.client);
    }

    if (event is ClientTypingCancel && typingClients.contains(event.client)) {
      typingClients.remove(event.client);
    }

    notifyListeners();
  }

  startedTyping() {
    _roomClient.sendTyping();
  }

  stoppedTyping() {
    _roomClient.sendTypingCancel();
  }

  sendMessage(String message) {
    _roomClient.sendMessage(message);
  }

  @override
  void dispose() {
    super.dispose();
    _roomEventSubscription.cancel();
  }
}
