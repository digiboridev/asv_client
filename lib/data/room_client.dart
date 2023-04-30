// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:asv_client/data/room_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum RoomConnectionState {
  connecting,
  connected,
  disconnected,
  connectError,
}

enum PcType { tx, rx }

abstract class RoomClient extends ChangeNotifier {
  RoomConnectionState get connectionState;
  String get roomId;
  String get clientId;
  Stream<RoomEvent> get eventStream;
  Future sendMessage(String message);
  Future sendTyping();
  Future sendTypingCancel();
  Future<String> sendWarmupAck(String toClientId);
  Future sendOffer(String toClientId, RTCSessionDescription offer);
  Future sendAnswer(String toClientId, RTCSessionDescription answer);
  Future sendCandidate(String toClientId, PcType pcType, RTCIceCandidate candidate);
}
