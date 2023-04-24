// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:asv_client/core/constants.dart';
import 'package:asv_client/domain/controllers/room_client.dart';
import 'package:asv_client/utils/first_where_or_null.dart';

class Transmitter {
  Transmitter({
    required this.clientId,
    required this.roomClient,
    required this.stream,
  }) {
    init();
  }

  final String clientId;
  final RoomClient roomClient;
  final MediaStream stream;

  RTCPeerConnection? pc;

  Future setup() async {
    pc = await createPeerConnection(peerConfig);

    for (var track in stream.getTracks()) {
      await pc!.addTrack(track, stream);
    }

    pc!.onIceCandidate = (candidate) {
      debugPrint('onIceCandidate: $candidate');
      roomClient.sendCandidate(clientId, PcType.tx, candidate);
    };

    pc!.onConnectionState = (state) {
      debugPrint('onConnectionState: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        connect();
      }
    };
  }

  Future warmup() async {
    if (_disposed) return;

    roomClient.sendWarmup(clientId);

    try {
      await roomClient.eventStream.firstWhere((event) {
        return event is MeetConnectionReady && event.clientId == clientId;
      }).timeout(const Duration(seconds: 20));
      debugPrint('$clientId is ready for connection ');
    } on TimeoutException {
      debugPrint('Timeout waiting for ready, retrying');
      return await warmup();
    }
  }

  Future connect() async {
    if (_disposed) return;

    final offer = await pc!.createOffer();
    await pc!.setLocalDescription(offer);
    roomClient.sendOffer(clientId, offer);

    try {
      RoomEvent answer = await roomClient.eventStream.firstWhere((event) {
        return event is MeetConnectionAnswer && event.clientId == clientId;
      }).timeout(const Duration(seconds: 20));

      debugPrint('Received answer from $clientId');

      if (_disposed) return;
      await pc!.setRemoteDescription((answer as MeetConnectionAnswer).answer);
    } on TimeoutException {
      debugPrint('Timeout waiting for answer, retrying');
      return await connect();
    }
  }

  init() async {
    await setup();
    await warmup();
    await connect();
  }

  addCandidate(RTCIceCandidate candidate) async {
    await pc?.addCandidate(candidate);
  }

  bool _disposed = false;
  void dispose() {
    _disposed = true;
    pc?.close();
  }
}

class Receiver {
  Receiver({
    required this.clientId,
    required this.roomClient,
    required this.renderer,
  }) {
    setup();
  }

  final String clientId;
  final RoomClient roomClient;
  final RTCVideoRenderer renderer;

  RTCPeerConnection? pc;

  Future setup() async {
    pc = await createPeerConnection(peerConfig);

    pc!.onIceCandidate = (candidate) {
      debugPrint('onIceCandidate rx: $candidate');
      roomClient.sendCandidate(clientId, PcType.rx, candidate);
    };

    pc!.onConnectionState = (state) {
      debugPrint('onConnectionState rx: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        renderer.srcObject = null;
      }
    };

    pc!.onTrack = (track) async {
      debugPrint('onTrack rx: $track');
      renderer.srcObject = track.streams.first;
    };

    roomClient.sendReady(clientId);
  }

  connect(RTCSessionDescription offer) async {
    await pc!.setRemoteDescription(offer);
    final answer = await pc!.createAnswer();
    await pc!.setLocalDescription(answer);
    roomClient.sendAnswer(clientId, answer);
  }

  addCandidate(RTCIceCandidate candidate) async {
    await pc?.addCandidate(candidate);
  }

  bool _disposed = false;
  void dispose() {
    _disposed = true;
    pc?.close();
  }
}

class MeetConnection {
  MeetConnection({
    required this.clientId,
    required this.roomClient,
    MediaStream? txStream,
  }) {
    renderer = RTCVideoRenderer();
    renderer.initialize();
    _eventSubscription = roomClient.eventStream.listen(eventHandler);

    // Start transmitting if tx stream provided
    if (txStream != null) initTransmitter(txStream);
  }

  final String clientId;
  final RoomClient roomClient;

  late final StreamSubscription<RoomEvent> _eventSubscription;
  late final RTCVideoRenderer renderer;

  Transmitter? _transmitter;
  Receiver? _receiver;

  set setTxStream(MediaStream? stream) {
    if (stream != null) {
      initTransmitter(stream);
    } else {
      _transmitter?.dispose();
      _transmitter = null;
    }
  }

  initTransmitter(MediaStream stream) {
    _transmitter?.dispose();

    _transmitter = Transmitter(
      clientId: clientId,
      roomClient: roomClient,
      stream: stream,
    );
  }

  initReceiver() {
    _receiver?.dispose();

    _receiver = Receiver(
      clientId: clientId,
      roomClient: roomClient,
      renderer: renderer,
    );
  }

  eventHandler(RoomEvent event) async {
    if (event is MeetConnectionWarmup && event.clientId == clientId) {
      initReceiver();
    }
    if (event is MeetConnectionOffer && event.clientId == clientId) {
      _receiver?.connect(event.offer);
    }

    if (event is MeetConnectionCandidate) {
      if (event.clientId == clientId) {
        // Pay attention to the pcType here
        // RX candidate is for TX pc and vice versa
        if (event.pcType == PcType.tx) {
          if (_receiver != null) {
            debugPrint('RX candidate is received');
            _receiver!.addCandidate(event.candidate);
          } else {
            debugPrint('RX candidate is loss');
          }
        } else {
          if (_transmitter != null) {
            debugPrint('TX candidate is received');
            _transmitter!.addCandidate(event.candidate);
          } else {
            debugPrint('TX candidate is loss');
          }
        }
      }
    }
  }

  bool _disposed = false;
  dispose() {
    _disposed = true;
    _transmitter?.dispose();
    _receiver?.dispose();
    _eventSubscription.cancel();
    renderer.srcObject = null;
    renderer.dispose();
  }
}

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

    // Timer.periodic(const Duration(seconds: 1), (timer) {
    //   setState(() {});
    // });
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
                  width: 100,
                  height: 100,
                  child: RTCVideoView(
                    localRenderer,
                    mirror: true,
                  ),
                ),
                ...connections
                    .map(
                      (connection) => Container(
                        color: Colors.blue,
                        width: 100,
                        height: 100,
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
