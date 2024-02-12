// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';
import 'package:asv_client/app/controllers/rtc_peer_controller/peer_controller.dart';
import 'package:asv_client/app/controllers/rtc_peer_controller/rtc_stream_track.dart';
import 'package:asv_client/data/transport/room_events.dart';
import 'package:asv_client/utils/first_where_or_null.dart';
import 'package:flutter/material.dart';
import 'package:asv_client/data/transport/room_client.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MeetViewController extends ChangeNotifier {
  MeetViewController({
    required RoomClient roomClient,
  }) : _roomClient = roomClient {
    _eventSubscription = _roomClient.eventStream.listen(_roomEventHandler);
  }

  final RoomClient _roomClient;
  late final StreamSubscription<RoomEvent> _eventSubscription;
  final List<RTCPeerController> _peers = [];
  RTCStreamTrack? _audioTrack;
  RTCStreamTrack? _videoTrack;

  /// Current active audio track.
  RTCStreamTrack? get audioTrack => _audioTrack;

  /// Current active video track.
  RTCStreamTrack? get videoTrack => _videoTrack;

  /// List of peer connections.
  List<RTCPeerController> get peers => List.unmodifiable(_peers);

  /// Enables audio and sends track to all peer connections.
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

  /// Disables audio and remove track from all peer connections.
  Future disableAudio() async {
    _audioTrack?.track.stop();
    _audioTrack = null;
    for (var peer in _peers) {
      await peer.setAudioTrack(null);
    }
    notifyListeners();
  }

  /// Enables camera video and sends track to all peer connections.
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

  /// Enables screen share video and remove track from all peer connections.
  Future enableDisplay() async {
    if (_videoTrack != null) await disableVideo();

    if (Platform.isAndroid && !FlutterBackground.isBackgroundExecutionEnabled) {
      final foreEnabled = await startForegroundService();
      if (!foreEnabled) throw Exception('Failed to start projection service');
    }

    final stream = await navigator.mediaDevices.getDisplayMedia({'audio': false, 'video': true});
    final track = stream.getVideoTracks().first;
    track.onEnded = () => disableVideo();

    _videoTrack = RTCStreamTrack(track: track, stream: stream, kind: RTCTrackKind.display);
    for (var peer in _peers) {
      await peer.setVideoTrack(_videoTrack);
    }
    notifyListeners();
  }

  /// Disables video and remove track from all peer connections.
  Future disableVideo() async {
    if (Platform.isAndroid && FlutterBackground.isBackgroundExecutionEnabled) {
      FlutterBackground.disableBackgroundExecution();
    }

    await _videoTrack?.track.stop();
    _videoTrack = null;
    for (var peer in _peers) {
      await peer.setVideoTrack(null);
    }
    notifyListeners();
  }

  _roomEventHandler(RoomEvent event) {
    // Creates a new peer connection for new client that joins the room.
    if (event is ClientJoin) {
      RTCPeerController? peer = _peers.firstWhereOrNull((connection) => connection.memberId == event.memberId);
      if (peer != null) return;
      _peers.add(RTCPeerController(
        memberId: event.memberId,
        memberName: event.client.name,
        roomClient: _roomClient,
        audioTrack: _audioTrack,
        videoTrack: _videoTrack,
      ));
    }

    // Creates a new peer connection for client that already in the room.
    if (event is ClientSignal) {
      RTCPeerController? peer = _peers.firstWhereOrNull((connection) => connection.memberId == event.memberId);
      if (peer != null) return;
      _peers.add(RTCPeerController(
        memberId: event.memberId,
        memberName: event.client.name,
        roomClient: _roomClient,
        audioTrack: _audioTrack,
        videoTrack: _videoTrack,
      ));
    }

    // Removes peer connection for client that leaves the room.
    if (event is ClientLeave) {
      RTCPeerController? peer = _peers.firstWhereOrNull((connection) => connection.memberId == event.memberId);
      peer?.dispose();
      _peers.remove(peer);
    }

    // Removes all peer connections when youre disconnected for prevent collisions.
    // When room connection is restored, new fresh peer connections will be created for all clients in the room.
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

Future<bool> startForegroundService() async {
  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Service is running',
    notificationText: 'Tap to return to the app',
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  return FlutterBackground.enableBackgroundExecution();
}
