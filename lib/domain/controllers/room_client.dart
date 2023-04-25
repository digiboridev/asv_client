// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum PcType { tx, rx }

abstract class RoomClient extends ChangeNotifier {
  bool get isConnected;
  bool get isDisconnected;
  bool get isActive;
  String get roomId;
  String get clientId;
  Stream<RoomEvent> get eventStream;
  Future sendMessage(String message);
  Future sendTyping();
  Future sendTypingCancel();
  // Future sendWarmup(String toClientId);
  Future<String> sendWarmupAck(String toClientId);
  Future sendReady(String toClientId);
  Future sendOffer(String toClientId, RTCSessionDescription offer);
  Future sendAnswer(String toClientId, RTCSessionDescription answer);
  Future sendCandidate(String toClientId, PcType pcType, RTCIceCandidate candidate);
}

abstract class RoomEvent {}

abstract class ChatEvent extends RoomEvent {
  ChatEvent({required this.clientId});
  final String clientId;
}

class ChatMessage extends ChatEvent with EquatableMixin {
  ChatMessage({required this.message, required super.clientId, required this.time});
  final String message;
  final DateTime time;

  @override
  List<Object> get props => [message, clientId, time];
}

class ClientTyping extends ChatEvent with EquatableMixin {
  ClientTyping({required super.clientId});

  @override
  List<Object> get props => [clientId];
}

class ClientTypingCancel extends ChatEvent with EquatableMixin {
  ClientTypingCancel({required super.clientId});

  @override
  List<Object> get props => [clientId];
}

abstract class PresenceEvent extends RoomEvent with EquatableMixin {
  PresenceEvent({required this.clientId, required this.time});
  final String clientId;
  final DateTime time;

  @override
  List<Object> get props => [clientId, time];
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

abstract class RTCEvent extends RoomEvent {}

// class MeetConnectionWarmup extends RTCEvent {
//   MeetConnectionWarmup({required this.clientId});
//   final String clientId;
// }

class MeetConnectionWarmupAck extends RTCEvent {
  MeetConnectionWarmupAck({required this.clientId, required this.callback});
  final String clientId;
  final Function(String) callback;
}

class MeetConnectionReady extends RTCEvent {
  MeetConnectionReady({required this.clientId});
  final String clientId;
}

class MeetConnectionOffer extends RTCEvent {
  MeetConnectionOffer({required this.offer, required this.clientId});
  final RTCSessionDescription offer;
  final String clientId;
}

class MeetConnectionAnswer extends RTCEvent {
  MeetConnectionAnswer({required this.answer, required this.clientId});
  final RTCSessionDescription answer;
  final String clientId;
}

class MeetConnectionCandidate extends RTCEvent {
  MeetConnectionCandidate({required this.pcType, required this.clientId, required this.candidate});
  final PcType pcType;
  final String clientId;
  final RTCIceCandidate candidate;
}
