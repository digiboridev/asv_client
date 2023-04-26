// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: prefer_final_fields
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/core/constants.dart';
import 'package:asv_client/domain/controllers/room_client.dart';

class TrueStreamTrack {
  final MediaStreamTrack track;
  final MediaStream stream;
  TrueStreamTrack({
    required this.track,
    required this.stream,
  });
}

class Transmitter {
  Transmitter({
    required this.clientId,
    required this.roomClient,
    required this.notifyListeners,
    TrueStreamTrack? audioTrack,
    TrueStreamTrack? videoTrack,
  }) {
    _audioTrack = audioTrack;
    _videoTrack = videoTrack;
    _init();
  }

  final String clientId;
  final RoomClient roomClient;
  final VoidCallback notifyListeners;

  bool _disposed = false;
  RTCPeerConnection? _pc;

  TrueStreamTrack? _audioTrack;
  TrueStreamTrack? _videoTrack;
  RTCRtpSender? _audioSender;
  RTCRtpSender? _videoSender;

  Future _warmup() async {
    if (_disposed) return;

    debugPrint('warming up');

    String result = await roomClient.sendWarmupAck(clientId);
    if (result != 'ready') {
      debugPrint('Warmup failed, retrying');
      return await _warmup();
    }

    debugPrint('Warmup: $result');
  }

  Future _start() async {
    if (_disposed) return;
    debugPrint('tx setting up');

    _pc = await createPeerConnection(peerConfig);

    _pc!.onIceCandidate = (candidate) {
      debugPrint('tx onIceCandidate: $candidate');
      roomClient.sendCandidate(clientId, PcType.tx, candidate);
    };

    _pc!.onRenegotiationNeeded = () {
      debugPrint('tx onRenegotiationNeeded');
      _negotiate();
    };

    _pc!.onConnectionState = (state) {
      debugPrint('tx onConnectionState: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _pc!.restartIce();
      }
    };

    attachAudioTrack();
    attachVideoTrack();
  }

  Future setAudioTrack(TrueStreamTrack? track) async {
    _audioTrack = track;
    if (_pc != null) await attachAudioTrack();
  }

  Future attachAudioTrack() async {
    if (_audioTrack != null) _audioSender = await _pc!.addTrack(_audioTrack!.track, _audioTrack!.stream);
    if (_audioTrack == null && _audioSender != null) {
      await _pc!.removeTrack(_audioSender!);
      _audioSender = null;
    }
  }

  Future setVideoTrack(TrueStreamTrack? track) async {
    _videoTrack = track;
    if (_pc != null) await attachVideoTrack();
  }

  Future attachVideoTrack() async {
    if (_videoTrack != null) _videoSender = await _pc!.addTrack(_videoTrack!.track, _videoTrack!.stream);
    if (_videoTrack == null && _videoSender != null) {
      await _pc!.removeTrack(_videoSender!);
      _videoSender = null;
    }
  }

  Future _negotiate() async {
    if (_disposed) return;
    debugPrint('tx negotiating');

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    roomClient.sendOffer(clientId, offer);
  }

  setRemoteDescription(RTCSessionDescription description) async {
    if (_disposed) return;
    debugPrint('tx setRemoteDescription: $description');

    await _pc!.setRemoteDescription(description);
  }

  addCandidate(RTCIceCandidate candidate) async {
    if (_disposed) return;
    await _pc!.addCandidate(candidate);
  }

  _init() async {
    await _warmup();
    await _start();
  }

  void dispose() {
    _disposed = true;
    _pc?.close();
  }
}

class Receiver {
  Receiver({
    required this.clientId,
    required this.roomClient,
    required this.notifyListeners,
  }) {
    _setup();
  }

  final String clientId;
  final RoomClient roomClient;
  final VoidCallback notifyListeners;

  bool _disposed = false;
  RTCPeerConnection? _pc;
  MediaStream? _audioStream;
  MediaStream? _videoStream;

  MediaStream? get audioStream => _audioStream;
  MediaStream? get videoStream => _videoStream;

  Future _setup() async {
    debugPrint('rx setting up');

    _pc = await createPeerConnection(peerConfig);

    _pc!.onIceCandidate = (candidate) {
      debugPrint('tx onIceCandidate: $candidate');
      roomClient.sendCandidate(clientId, PcType.rx, candidate);
    };

    _pc!.onConnectionState = (state) {
      debugPrint('rx onConnectionState: $state');
    };

    _pc!.onTrack = (track) async {
      debugPrint('rx onTrack');

      if (track.streams.isEmpty) return;

      if (track.track.kind == 'audio') {
        _audioStream = track.streams.first;
      }
      if (track.track.kind == 'video') {
        _videoStream = track.streams.first;
      }

      notifyListeners();
    };

    _pc!.onRemoveTrack = (stream, track) {
      debugPrint('rx onRemoveTrack');

      if (track.kind == 'audio') {
        _audioStream = null;
      }

      if (track.kind == 'video') {
        _videoStream = null;
      }
      notifyListeners();
    };
  }

  answer(RTCSessionDescription offer) async {
    if (_disposed) return;
    debugPrint('rx answer');

    await _pc!.setRemoteDescription(offer);
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    roomClient.sendAnswer(clientId, answer);
  }

  addCandidate(RTCIceCandidate candidate) async {
    if (_disposed) return;
    debugPrint('rx addCandidate: $candidate');

    await _pc!.addCandidate(candidate);
  }

  void dispose() {
    _disposed = true;
    _pc?.close();
  }
}

class MeetConnection extends ChangeNotifier {
  MeetConnection({
    required this.clientId,
    required this.roomClient,
    TrueStreamTrack? audioTrack,
    TrueStreamTrack? videoTrack,
  }) {
    _eventSubscription = roomClient.eventStream.listen(eventHandler);

    _transmitter = Transmitter(
      clientId: clientId,
      roomClient: roomClient,
      notifyListeners: () => notifyListeners(),
      audioTrack: audioTrack,
      videoTrack: videoTrack,
    );

    _receiver = Receiver(
      clientId: clientId,
      roomClient: roomClient,
      notifyListeners: () => notifyListeners(),
    );
  }

  final String clientId;
  final RoomClient roomClient;

  late final StreamSubscription<RoomEvent> _eventSubscription;
  late final Transmitter _transmitter;
  late final Receiver _receiver;

  MediaStream? get audioStream => _receiver.audioStream;
  MediaStream? get videoStream => _receiver.videoStream;

  Future setAudioTrack(TrueStreamTrack? track) => _transmitter.setAudioTrack(track);
  Future setVideoTrack(TrueStreamTrack? track) => _transmitter.setVideoTrack(track);

  eventHandler(RoomEvent event) async {
    if (event is MeetConnectionWarmupAck && event.clientId == clientId) {
      event.callback('ready');
    }

    if (event is MeetConnectionOffer && event.clientId == clientId) {
      _receiver.answer(event.offer);
    }

    if (event is MeetConnectionAnswer && event.clientId == clientId) {
      _transmitter.setRemoteDescription(event.answer);
    }

    if (event is MeetConnectionCandidate && event.clientId == clientId) {
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
