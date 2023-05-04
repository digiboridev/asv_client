import 'dart:async';
import 'package:asv_client/data/models/chat_entries.dart';
import 'package:asv_client/data/transport/room_client.dart';
import 'package:asv_client/data/transport/room_events.dart';
import 'package:flutter/foundation.dart';

class ChatViewController extends ChangeNotifier {
  ChatViewController({
    required this.roomClient,
  }) {
    _roomEventSubscription = roomClient.eventStream.listen(roomEventsHandler);
  }

  final RoomClient roomClient;
  final List<ChatEntry> _chatHistory = [];
  List<ChatEntry> get chatHistory => _chatHistory;
  final Set<String> _typingClients = {};
  Set<String> get typingClients => _typingClients;
  late final StreamSubscription _roomEventSubscription;

  roomEventsHandler(RoomEvent event) {
    if (event is NewMessage) {
      chatHistory.add(ChatEntry.message(event.memberId, event.message));
      if (typingClients.contains(event.memberId)) typingClients.remove(event.memberId);
    }

    if (event is ClientJoin) {
      chatHistory.add(ChatEntry.userJoined(event.memberId));
    }

    if (event is ClientLeave) {
      chatHistory.add(ChatEntry.userLeft(event.memberId));
      if (typingClients.contains(event.memberId)) typingClients.remove(event.memberId);
    }

    if (event is ClientTyping) {
      typingClients.add(event.memberId);
    }

    if (event is ClientTypingCancel && typingClients.contains(event.memberId)) {
      typingClients.remove(event.memberId);
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
