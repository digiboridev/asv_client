import 'dart:async';
import 'package:asv_client/controllers/peer_controller/connection_state.dart';
import 'package:asv_client/controllers/peer_controller/receiver.dart';
import 'package:asv_client/controllers/peer_controller/transmitter.dart';
import 'package:asv_client/controllers/peer_controller/rtc_stream_track.dart';
import 'package:asv_client/data/room_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/data/room_client.dart';

class RTCPeerController extends ChangeNotifier {
  RTCPeerController({
    required this.clientId,
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

  final String clientId;
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

  Future<String> _sendWarmup() => roomClient.sendWarmupAck(clientId);
  Future _sendOffer(RTCSessionDescription offer) => roomClient.sendOffer(clientId, offer);
  Future _sendAnswer(RTCSessionDescription answer) => roomClient.sendAnswer(clientId, answer);
  Future _sendIceCandy(RTCIceCandidate candidate, PcType pctype) => roomClient.sendCandidate(clientId, pctype, candidate);

  _eventHandler(RoomEvent event) async {
    if (event is RTCWarmup && event.clientId == clientId) {
      event.callback('ready');
    }

    if (event is RTCOffer && event.clientId == clientId) {
      _receiver.answer(event.offer);
    }

    if (event is RTCAnswer && event.clientId == clientId) {
      _transmitter.setRemoteDescription(event.answer);
    }

    if (event is RTCCandidate && event.clientId == clientId) {
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
