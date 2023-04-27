import 'package:asv_client/controllers/peer_controller/connection_state.dart';
import 'package:asv_client/controllers/peer_controller/true_stream_track.dart';
import 'package:asv_client/core/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Transmitter {
  Transmitter({
    required this.notifyListeners,
    required this.sendWarmup,
    required this.sendIceCandy,
    required this.sendOffer,
    TrueStreamTrack? audioTrack,
    TrueStreamTrack? videoTrack,
  }) {
    _audioTrack = audioTrack;
    _videoTrack = videoTrack;
    _init();
  }

  final VoidCallback notifyListeners;
  final Future Function(RTCIceCandidate) sendIceCandy;
  final Future Function(RTCSessionDescription) sendOffer;
  final Future Function() sendWarmup;

  bool _disposed = false;
  RTCPeerConnection? _pc;

  TrueStreamTrack? _audioTrack;
  TrueStreamTrack? _videoTrack;
  RTCRtpSender? _audioSender;
  RTCRtpSender? _videoSender;
  RTCConnectionState _connectionState = RTCConnectionState.idle;

  RTCConnectionState get connectionState => _connectionState;

  Future _warmup() async {
    if (_disposed) return;

    debugPrint('warming up');

    String result = await sendWarmup();
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
      sendIceCandy(candidate);
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

      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          _connectionState = RTCConnectionState.connecting;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _connectionState = RTCConnectionState.connected;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _connectionState = RTCConnectionState.failed;
          break;
        default:
          _connectionState = RTCConnectionState.idle;
      }
      notifyListeners();
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
    await sendOffer(offer);
  }

  Future setRemoteDescription(RTCSessionDescription description) async {
    if (_disposed) return;
    debugPrint('tx setRemoteDescription: $description');

    await _pc!.setRemoteDescription(description);
  }

  Future addCandidate(RTCIceCandidate candidate) async {
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
