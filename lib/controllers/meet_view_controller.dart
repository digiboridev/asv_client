// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'package:asv_client/controllers/peer_controller/peer_controller.dart';
import 'package:asv_client/controllers/peer_controller/true_stream_track.dart';
import 'package:asv_client/data/room_events.dart';
import 'package:asv_client/utils/first_where_or_null.dart';
import 'package:flutter/material.dart';
import 'package:asv_client/data/room_client.dart';
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

  TrueStreamTrack? _audioTrack;
  TrueStreamTrack? _videoTrack;
  TrueStreamTrack? get audioTrack => _audioTrack;
  TrueStreamTrack? get videoTrack => _videoTrack;

  Future enableAudio() async {
    if (_audioTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    _audioTrack = TrueStreamTrack(track: stream.getAudioTracks().first, stream: stream);
    for (var peer in _peers) {
      await peer.setAudioTrack(_audioTrack);
    }
  }

  Future disableAudio() async {
    _audioTrack?.track.stop();
    _audioTrack = null;
    for (var peer in _peers) {
      await peer.setAudioTrack(null);
    }
  }

  Future enableCamera() async {
    if (_videoTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getUserMedia({'audio': false, 'video': true});
    _videoTrack = TrueStreamTrack(track: stream.getVideoTracks().first, stream: stream);
    for (var peer in _peers) {
      await peer.setVideoTrack(_videoTrack);
    }
    // localRenderer.srcObject = stream;
  }

  Future enableDisplay() async {
    if (_videoTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getDisplayMedia({'audio': false, 'video': true});
    _videoTrack = TrueStreamTrack(track: stream.getVideoTracks().first, stream: stream);
    for (var peer in _peers) {
      await peer.setVideoTrack(_videoTrack);
    }
    // localRenderer.srcObject = stream;
  }

  Future disableVideo() async {
    await _videoTrack?.track.stop();
    _videoTrack = null;
    for (var peer in _peers) {
      await peer.setVideoTrack(null);
    }
    // localRenderer.srcObject = null;
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
