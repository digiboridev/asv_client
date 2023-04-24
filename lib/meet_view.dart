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
  MediaStream? localStream;
  final localRenderer = RTCVideoRenderer();
  List<MeetConnection> connections = [];

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
          txStream: localStream,
        ));
      }

      if (event is ClientSignal) {
        MeetConnection? connection = connections.firstWhereOrNull((connection) => connection.clientId == event.clientId);
        if (connection != null) return;
        connections.add(MeetConnection(
          clientId: event.clientId,
          roomClient: widget.roomClient,
          txStream: localStream,
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

  Future streamCamera() async {
    stopStream();
    final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
    localStream = stream;
    localRenderer.srcObject = stream;
    for (var connection in connections) {
      connection.setTxStream = stream;
    }
  }

  Future streamDisplay() async {
    stopStream();
    final stream = await navigator.mediaDevices.getDisplayMedia({'audio': false, 'video': true});
    localStream = stream;
    localRenderer.srcObject = stream;
    for (var connection in connections) {
      connection.setTxStream = stream;
    }
  }

  stopStream() async {
    for (var connection in connections) {
      connection.setTxStream = null;
    }
    if (kIsWeb) {
      localStream?.getTracks().forEach((track) => track.stop());
    }
    localRenderer.srcObject = null;
    localStream?.dispose();
    localStream = null;
  }

  @override
  void deactivate() {
    super.deactivate();
    stopStream();
    eventSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: streamCamera,
          child: const Text('Start camera'),
        ),
        TextButton(
          onPressed: streamDisplay,
          child: const Text('Start display'),
        ),
        TextButton(
          onPressed: stopStream,
          child: const Text('Stop stream'),
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
                      (connection) => Container(
                        color: Colors.blue,
                        width: 200,
                        height: 200,
                        child: RTCVideoView(connection.renderer),
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
