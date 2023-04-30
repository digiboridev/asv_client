import 'package:asv_client/data/room_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class RoomEvent {}

class ConnectionStateChanged extends RoomEvent {
  ConnectionStateChanged({required this.state});
  final RoomConnectionState state;
}

abstract class PresenceEvent extends RoomEvent {
  PresenceEvent({required this.clientId, required this.time});
  final String clientId;
  final DateTime time;
}

class ClientJoin extends PresenceEvent {
  ClientJoin({required super.clientId, required super.time});
}

class ClientLeave extends PresenceEvent {
  ClientLeave({required super.clientId, required super.time});
}

class ClientSignal extends PresenceEvent {
  ClientSignal({required super.clientId, required super.time});
}

abstract class ChatEvent extends RoomEvent {
  ChatEvent({required this.clientId});
  final String clientId;
}

class NewMessage extends ChatEvent {
  NewMessage({required this.message, required super.clientId, required this.time});
  final String message;
  final DateTime time;
}

class ClientTyping extends ChatEvent {
  ClientTyping({required super.clientId});
}

class ClientTypingCancel extends ChatEvent {
  ClientTypingCancel({required super.clientId});
}

abstract class RTCEvent extends RoomEvent {
  RTCEvent({required this.clientId});
  final String clientId;
}

class RTCWarmup extends RTCEvent {
  RTCWarmup({required super.clientId, required this.callback});
  final Function(String) callback;
}

class RTCOffer extends RTCEvent {
  RTCOffer({required super.clientId, required this.offer});
  final RTCSessionDescription offer;
}

class RTCAnswer extends RTCEvent {
  RTCAnswer({required super.clientId, required this.answer});
  final RTCSessionDescription answer;
}

class RTCCandidate extends RTCEvent {
  RTCCandidate({required super.clientId, required this.pcType, required this.candidate});
  final PcType pcType;
  final RTCIceCandidate candidate;
}
