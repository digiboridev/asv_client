// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:asv_client/data/transport/room_events.dart';
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
  Stream<RoomEvent> get eventStream;
  Future sendMessage(String message);
  Future sendTyping();
  Future sendTypingCancel();
  Future<String> sendWarmupAck({required String memberId});
  Future sendOffer({required String memberId, required RTCSessionDescription offer});
  Future sendAnswer({required String memberId, required RTCSessionDescription answer});
  Future sendCandidate({required String memberId, required PcType pcType, required RTCIceCandidate candidate});
}
