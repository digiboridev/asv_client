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
  /// The current connection state of the room client.
  RoomConnectionState get connectionState;

  /// The stream of incoming room events.
  Stream<RoomEvent> get eventStream;

  /// Sends a chat message to the room.
  Future sendMessage(String message);

  /// Sends a typing notification to the room.
  Future sendTyping();

  /// Cancels a typing notification to the room.
  Future sendTypingCancel();

  /// Send a warmup acknowledgement to member.
  /// Returns a future that completes if member is instantiated and ready for rtc communication.
  Future<String> sendWarmupAck({required String memberId});

  /// Sends an rtc offer to a member.
  Future sendOffer({required String memberId, required RTCSessionDescription offer});

  /// Sends an rtc answer to a member.
  Future sendAnswer({required String memberId, required RTCSessionDescription answer});

  /// Sends an rtc candidate to a member.
  /// The [pcType] is the type ( Transmitter/Receiver ) of peer connection part that the candidate is for.
  Future sendCandidate({required String memberId, required PcType pcType, required RTCIceCandidate candidate});
}
