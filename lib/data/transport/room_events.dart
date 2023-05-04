import 'package:asv_client/data/transport/room_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class RoomEvent {}

class ConnectionStateChanged extends RoomEvent {
  ConnectionStateChanged({required this.state});
  final RoomConnectionState state;
}

abstract class PresenceEvent extends RoomEvent {
  PresenceEvent({required this.memberId, required this.time});
  final String memberId;
  final DateTime time;
}

class ClientJoin extends PresenceEvent {
  ClientJoin({required super.memberId, required super.time});
}

class ClientLeave extends PresenceEvent {
  ClientLeave({required super.memberId, required super.time});
}

class ClientSignal extends PresenceEvent {
  ClientSignal({required super.memberId, required super.time});
}

abstract class ChatEvent extends RoomEvent {
  ChatEvent({required this.memberId});
  final String memberId;
}

class NewMessage extends ChatEvent {
  NewMessage({required this.message, required super.memberId, required this.time});
  final String message;
  final DateTime time;
}

class ClientTyping extends ChatEvent {
  ClientTyping({required super.memberId});
}

class ClientTypingCancel extends ChatEvent {
  ClientTypingCancel({required super.memberId});
}

abstract class RTCEvent extends RoomEvent {
  RTCEvent({required this.memberId});
  final String memberId;
}

class RTCWarmup extends RTCEvent {
  RTCWarmup({required super.memberId, required this.callback});
  final Function(String) callback;
}

class RTCOffer extends RTCEvent {
  RTCOffer({required super.memberId, required this.offer});
  final RTCSessionDescription offer;
}

class RTCAnswer extends RTCEvent {
  RTCAnswer({required super.memberId, required this.answer});
  final RTCSessionDescription answer;
}

class RTCCandidate extends RTCEvent {
  RTCCandidate({required super.memberId, required this.pcType, required this.candidate});
  final PcType pcType;
  final RTCIceCandidate candidate;
}
