import 'dart:async';
import 'package:asv_client/app/controllers/peer_controller/connection_state.dart';
import 'package:asv_client/app/controllers/peer_controller/receiver.dart';
import 'package:asv_client/app/controllers/peer_controller/transmitter.dart';
import 'package:asv_client/app/controllers/peer_controller/rtc_stream_track.dart';
import 'package:asv_client/data/transport/room_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/data/transport/room_client.dart';

class RTCPeerController extends ChangeNotifier {
  RTCPeerController({
    required this.memberId,
    required this.roomClient,
    RTCStreamTrack? audioTrack,
    RTCStreamTrack? videoTrack,
  }) {
    _eventSubscription = roomClient.eventStream.listen(_eventHandler);

    _transmitter = Transmitter(
      notifyListeners: () => notifyListeners(),
      sendWarmup: () async => _sendWarmup(),
      sendIceCandy: (candy) async => _sendIceCandy(candy, PcType.tx),
      sendOffer: (offer) async => _sendOffer(offer),
      audioTrack: audioTrack,
      videoTrack: videoTrack,
    );

    _receiver = Receiver(
      notifyListeners: () => notifyListeners(),
      sendAnswer: (answer) async => _sendAnswer(answer),
      sendIceCandy: (candy) async => _sendIceCandy(candy, PcType.rx),
    );
  }

  final String memberId;
  final RoomClient roomClient;
  late final Transmitter _transmitter;
  late final Receiver _receiver;
  late final StreamSubscription<RoomEvent> _eventSubscription;

  RTCConnectionState get txConnectionState => _transmitter.connectionState;
  RTCConnectionState get rxConnectionState => _receiver.connectionState;

  MediaStream? get audioStream => _receiver.audioStream;
  MediaStream? get videoStream => _receiver.videoStream;

  Future setAudioTrack(RTCStreamTrack? track) => _transmitter.setAudioTrack(track);
  Future setVideoTrack(RTCStreamTrack? track) => _transmitter.setVideoTrack(track);

  Future<String> _sendWarmup() => roomClient.sendWarmupAck(memberId: memberId);
  Future _sendOffer(RTCSessionDescription offer) => roomClient.sendOffer(memberId: memberId, offer: offer);
  Future _sendAnswer(RTCSessionDescription answer) => roomClient.sendAnswer(memberId: memberId, answer: answer);
  Future _sendIceCandy(RTCIceCandidate candidate, PcType pctype) => roomClient.sendCandidate(memberId: memberId, pcType: pctype, candidate: candidate);

  _eventHandler(RoomEvent event) async {
    if (event is RTCWarmup && event.memberId == memberId) {
      event.callback('ready');
    }

    if (event is RTCOffer && event.memberId == memberId) {
      _receiver.answer(event.offer);
    }

    if (event is RTCAnswer && event.memberId == memberId) {
      _transmitter.setRemoteDescription(event.answer);
    }

    if (event is RTCCandidate && event.memberId == memberId) {
      // Pay attention to the pcType here
      // RX candidate is for TX pc and vice versa
      if (event.pcType == PcType.tx) {
        _receiver.addCandidate(event.candidate);
      } else {
        _transmitter.addCandidate(event.candidate);
      }
    }
  }

  @override
  dispose() {
    super.dispose();
    _transmitter.dispose();
    _receiver.dispose();
    _eventSubscription.cancel();
  }
}
