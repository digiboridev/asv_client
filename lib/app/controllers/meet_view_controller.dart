// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'package:asv_client/app/controllers/peer_controller/peer_controller.dart';
import 'package:asv_client/app/controllers/peer_controller/rtc_stream_track.dart';
import 'package:asv_client/data/transport/room_events.dart';
import 'package:asv_client/utils/first_where_or_null.dart';
import 'package:flutter/material.dart';
import 'package:asv_client/data/transport/room_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MeetViewController extends ChangeNotifier {
  MeetViewController({
    required RoomClient roomClient,
  }) : _roomClient = roomClient {
    _eventSubscription = _roomClient.eventStream.listen(roomEventHandler);
  }

  final RoomClient _roomClient;
  late final StreamSubscription<RoomEvent> _eventSubscription;

  final List<RTCPeerController> _peers = [];
  List<RTCPeerController> get peers => List.unmodifiable(_peers);

  RTCStreamTrack? _audioTrack;
  RTCStreamTrack? _videoTrack;
  RTCStreamTrack? get audioTrack => _audioTrack;
  RTCStreamTrack? get videoTrack => _videoTrack;

  Future enableAudio() async {
    if (_audioTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    final track = stream.getAudioTracks().first;
    track.onEnded = () => disableAudio();

    _audioTrack = RTCStreamTrack(track: track, stream: stream, kind: RTCTrackKind.audio);
    for (var peer in _peers) {
      await peer.setAudioTrack(_audioTrack);
    }
    notifyListeners();
  }

  Future disableAudio() async {
    _audioTrack?.track.stop();
    _audioTrack = null;
    for (var peer in _peers) {
      await peer.setAudioTrack(null);
    }
    notifyListeners();
  }

  Future enableCamera() async {
    if (_videoTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getUserMedia({'audio': false, 'video': true});
    final track = stream.getVideoTracks().first;
    track.onEnded = () => disableVideo();

    _videoTrack = RTCStreamTrack(track: track, stream: stream, kind: RTCTrackKind.camera);
    for (var peer in _peers) {
      await peer.setVideoTrack(_videoTrack);
    }
    notifyListeners();
  }

  Future enableDisplay() async {
    if (_videoTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getDisplayMedia({'audio': false, 'video': true});
    final track = stream.getVideoTracks().first;
    track.onEnded = () => disableVideo();

    _videoTrack = RTCStreamTrack(track: track, stream: stream, kind: RTCTrackKind.display);
    for (var peer in _peers) {
      await peer.setVideoTrack(_videoTrack);
    }
    notifyListeners();
  }

  Future disableVideo() async {
    await _videoTrack?.track.stop();
    _videoTrack = null;
    for (var peer in _peers) {
      await peer.setVideoTrack(null);
    }
    notifyListeners();
  }

  roomEventHandler(RoomEvent event) {
    if (event is ClientJoin) {
      RTCPeerController? peer = _peers.firstWhereOrNull((connection) => connection.clientId == event.clientId);
      if (peer != null) return;
      _peers.add(RTCPeerController(
        clientId: event.clientId,
        roomClient: _roomClient,
        audioTrack: _audioTrack,
        videoTrack: _videoTrack,
      ));
    }

    if (event is ClientSignal) {
      RTCPeerController? peer = _peers.firstWhereOrNull((connection) => connection.clientId == event.clientId);
      if (peer != null) return;
      _peers.add(RTCPeerController(
        clientId: event.clientId,
        roomClient: _roomClient,
        audioTrack: _audioTrack,
        videoTrack: _videoTrack,
      ));
    }

    if (event is ClientLeave) {
      RTCPeerController? peer = _peers.firstWhereOrNull((connection) => connection.clientId == event.clientId);
      peer?.dispose();
      _peers.remove(peer);
    }

    if (event is ConnectionStateChanged && event.state == RoomConnectionState.disconnected) {
      for (var peer in _peers) {
        peer.dispose();
      }
      _peers.clear();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    for (var peer in _peers) {
      peer.dispose();
    }
    _audioTrack?.track.stop();
    _videoTrack?.track.stop();
    super.dispose();
  }
}
