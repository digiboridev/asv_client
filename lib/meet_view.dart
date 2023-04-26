// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'package:asv_client/utils/meet_connection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/domain/controllers/room_client.dart';
import 'package:asv_client/utils/first_where_or_null.dart';

class MeetView extends StatefulWidget {
  const MeetView({super.key, required this.roomClient});

  final RoomClient roomClient;

  @override
  State<MeetView> createState() => _MeetViewState();
}

class _MeetViewState extends State<MeetView> {
  late final StreamSubscription<RoomEvent> eventSubscription;
  final localRenderer = RTCVideoRenderer();
  List<MeetConnection> connections = [];

  TrueStreamTrack? audioTrack;
  TrueStreamTrack? videoTrack;

  @override
  void initState() {
    super.initState();
    localRenderer.initialize();

    eventSubscription = widget.roomClient.eventStream.listen((event) async {
      if (event is ClientJoin) {
        MeetConnection? connection = connections.firstWhereOrNull((connection) => connection.clientId == event.clientId);
        if (connection != null) return;
        connections.add(MeetConnection(
          clientId: event.clientId,
          roomClient: widget.roomClient,
          audioTrack: audioTrack,
          videoTrack: videoTrack,
        ));
      }

      if (event is ClientSignal) {
        MeetConnection? connection = connections.firstWhereOrNull((connection) => connection.clientId == event.clientId);
        if (connection != null) return;
        connections.add(MeetConnection(
          clientId: event.clientId,
          roomClient: widget.roomClient,
          audioTrack: audioTrack,
          videoTrack: videoTrack,
        ));
      }

      if (event is ClientLeave) {
        MeetConnection? connection = connections.firstWhereOrNull((connection) => connection.clientId == event.clientId);
        connection?.dispose();
        connections.remove(connection);
      }

      setState(() {});
    });
  }

  Future enableAudio() async {
    if (audioTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    audioTrack = TrueStreamTrack(track: stream.getAudioTracks().first, stream: stream);
    for (var connection in connections) {
      await connection.setAudioTrack(audioTrack);
    }
  }

  Future disableAudio() async {
    audioTrack?.track.stop();
    audioTrack = null;
    for (var connection in connections) {
      await connection.setAudioTrack(null);
    }
  }

  Future enableCamera() async {
    if (videoTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getUserMedia({'audio': false, 'video': true});
    videoTrack = TrueStreamTrack(track: stream.getVideoTracks().first, stream: stream);
    for (var connection in connections) {
      await connection.setVideoTrack(videoTrack);
    }
    localRenderer.srcObject = stream;
  }

  Future enableDisplay() async {
    if (videoTrack != null) await disableVideo();

    final stream = await navigator.mediaDevices.getDisplayMedia({'audio': false, 'video': true});
    videoTrack = TrueStreamTrack(track: stream.getVideoTracks().first, stream: stream);
    for (var connection in connections) {
      await connection.setVideoTrack(videoTrack);
    }
    localRenderer.srcObject = stream;
  }

  Future disableVideo() async {
    await videoTrack?.track.stop();
    videoTrack = null;
    for (var connection in connections) {
      await connection.setVideoTrack(null);
    }
    localRenderer.srcObject = null;
  }

  @override
  void dispose() {
    super.dispose();
    eventSubscription.cancel();
    for (var connection in connections) {
      connection.dispose();
    }
    localRenderer.srcObject = null;
    localRenderer.dispose();
    audioTrack?.track.stop();
    videoTrack?.track.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: enableAudio,
          child: const Text('Enable audio'),
        ),
        TextButton(
          onPressed: disableAudio,
          child: const Text('Disable audio'),
        ),
        TextButton(
          onPressed: enableCamera,
          child: const Text('Enable camera'),
        ),
        TextButton(
          onPressed: enableDisplay,
          child: const Text('Enable display'),
        ),
        TextButton(
          onPressed: disableVideo,
          child: const Text('Disable video'),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  color: Colors.amber,
                  width: 200,
                  height: 200,
                  child: RTCVideoView(
                    localRenderer,
                    mirror: true,
                  ),
                ),
                ...connections
                    .map(
                      (connection) => OpponentTile(
                        connection: connection,
                      ),
                    )
                    .toList()
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OpponentTile extends StatelessWidget {
  const OpponentTile({
    required this.connection,
    super.key,
  });

  final MeetConnection connection;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.blue,
        width: 200,
        height: 200,
        child: AnimatedBuilder(
          animation: connection,
          builder: (context, child) {
            return Column(
              children: [
                if (connection.audioStream != null) const Text('Audio'),
                if (connection.videoStream != null) const Text('Video'),
                if (connection.audioStream != null)
                  SizedBox.shrink(
                    child: Renderer(
                      stream: connection.audioStream!,
                    ),
                  ),
                if (connection.videoStream != null)
                  Expanded(
                    child: Renderer(
                      stream: connection.videoStream!,
                    ),
                  ),
              ],
            );
          },
        ));
  }
}

class Renderer extends StatefulWidget {
  const Renderer({
    required this.stream,
    super.key,
  });

  final MediaStream stream;

  @override
  State<Renderer> createState() => _RendererState();
}

class _RendererState extends State<Renderer> {
  late final RTCVideoRenderer rtcVideoRenderer;

  @override
  void initState() {
    super.initState();
    rtcVideoRenderer = RTCVideoRenderer();
    rtcVideoRenderer.initialize();
    rtcVideoRenderer.srcObject = widget.stream;
  }

  @override
  void dispose() {
    super.dispose();
    rtcVideoRenderer.srcObject = null;
    rtcVideoRenderer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: RTCVideoView(rtcVideoRenderer));
  }
}
