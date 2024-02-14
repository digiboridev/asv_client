import 'package:asv_client/app/controllers/rtc_peer_controller/connection_state.dart';
import 'package:asv_client/core/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Receiver {
  Receiver({
    required this.notifyListeners,
    required this.sendAnswer,
    required this.sendIceCandy,
  }) {
    _setup();
  }

  final VoidCallback notifyListeners;
  final Future Function(RTCSessionDescription) sendAnswer;
  final Future Function(RTCIceCandidate) sendIceCandy;

  bool _disposed = false;
  RTCPeerConnection? _pc;
  MediaStream? _audioStream;
  MediaStream? _videoStream;
  RTCConnectionState _connectionState = RTCConnectionState.idle;

  RTCConnectionState get connectionState => _connectionState;
  MediaStream? get audioStream => _audioStream;
  MediaStream? get videoStream => _videoStream;

  Future _setup() async {
    debugPrint('rx setting up');

    _pc = await createPeerConnection(kRTCPeerConfig);

    _pc!.onIceCandidate = (candidate) {
      debugPrint('tx onIceCandidate: $candidate');
      sendIceCandy(candidate);
    };

    _pc!.onConnectionState = (state) {
      debugPrint('rx onConnectionState: $state');

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
      if (!_disposed) notifyListeners();
    };

    _pc!.onTrack = (track) async {
      debugPrint('rx onTrack');

      if (track.streams.isEmpty) return;

      if (track.track.kind == 'audio') {
        debugPrint('rx audio onTrack');

        _audioStream = track.streams.first;
        notifyListeners();

        track.track.onEnded = () {
          debugPrint('rx audio onEnded');
          _audioStream = null;
          notifyListeners();
        };

        track.track.onMute = () {
          debugPrint('rx audio onMuted');
          _audioStream = null;
          notifyListeners();
        };
        track.track.onUnMute = () {
          debugPrint('rx audio onUnmuted');
          _audioStream = track.streams.first;
          notifyListeners();
        };
      }

      if (track.track.kind == 'video') {
        debugPrint('rx video onTrack');

        _videoStream = track.streams.first;
        notifyListeners();

        track.track.onEnded = () {
          debugPrint('rx video onEnded');
          _videoStream = null;
          notifyListeners();
        };

        track.track.onMute = () {
          debugPrint('rx video onMuted');
          _videoStream = null;
          notifyListeners();
        };

        track.track.onUnMute = () {
          debugPrint('rx video onUnmuted');
          _videoStream = track.streams.first;
          notifyListeners();
        };
      }
    };

    _pc!.onRemoveTrack = (s, track) {
      debugPrint('rx onRemoveTrack');
      if (track.kind == 'audio') {
        _audioStream = null;
        notifyListeners();
      }
      if (track.kind == 'video') {
        _videoStream = null;
        notifyListeners();
      }
    };
  }

  Future answer(RTCSessionDescription offer) async {
    if (_disposed) return;
    debugPrint('rx answer');

    await _pc!.setRemoteDescription(offer);
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await sendAnswer(answer);
  }

  Future addCandidate(RTCIceCandidate candidate) async {
    if (_disposed) return;
    debugPrint('rx addCandidate: $candidate');

    await _pc!.addCandidate(candidate);
  }

  void dispose() {
    _disposed = true;
    _pc?.close();
  }
}
