import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/domain/controllers/room_client.dart';
import 'package:asv_client/utils/first_where_or_null.dart';

class MeetConnection {
  MeetConnection({
    required this.clientId,
    // required this.master,
    required this.roomClient,
    this.localstream,
    this.fromOffer,
  }) {
    init();
  }
  final String clientId;
  // final bool master;
  final RoomClient roomClient;
  final RTCSessionDescription? fromOffer;
  final MediaStream? localstream;

  late final RTCPeerConnection _peerConnection;
  late final RTCVideoRenderer _renderer;
  late final StreamSubscription<RoomEvent> _eventSubscription;

  init() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ],
    };
    _renderer = RTCVideoRenderer();
    _renderer.initialize();

    _peerConnection = await createPeerConnection(
      configuration,
      {
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': true,
        },
        'optional': [],
      },
    );

    if (localstream != null) {
      _peerConnection.addStream(localstream!);
      // localstream!.getTracks().forEach((track) async {
      //   await _peerConnection.addTrack(track, localstream!);
      // });
    }

    _eventSubscription = roomClient.eventStream.listen(eventHandler);

    _peerConnection.onIceConnectionState = (state) {
      print('onIceConnectionState: $state');
    };

    _peerConnection.onIceGatheringState = (state) {
      print('onIceGatheringState: $state');
    };

    _peerConnection.onConnectionState = (state) {
      print('onConnectionState: $state');
    };

    _peerConnection.onIceCandidate = (candidate) async {
      print('onIceCandidate: $candidate');
      await Future.delayed(Duration(seconds: 1));
      roomClient.sendCandidate(clientId, candidate);
    };

    _peerConnection.onTrack = (RTCTrackEvent event) {
      print('onTrack: $event');
      // _renderer.srcObject = event.streams[0];
    };

    _peerConnection.onAddStream = (MediaStream stream) {
      print('onAddStream: $stream');
      _renderer.srcObject = stream;
    };

    _peerConnection.onRemoveStream = (MediaStream stream) {
      print('onRemoveStream: $stream');
      _renderer.srcObject = null;
    };

    _peerConnection.onAddTrack = (MediaStream track, MediaStreamTrack stream) {
      print('onAddTrack: $track, $stream');
      // _renderer.srcObject = track;
    };

    if (fromOffer is RTCSessionDescription) {
      await answer();
    } else {
      await call();
    }
  }

  call() async {
    RTCSessionDescription offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);
    await roomClient.sendOffer(clientId, offer);
  }

  answer() async {
    await _peerConnection.setRemoteDescription(fromOffer!);
    RTCSessionDescription answer = await _peerConnection.createAnswer();
    await _peerConnection.setLocalDescription(answer);
    await roomClient.sendAnswer(clientId, answer);
  }

  eventHandler(RoomEvent event) {
    if (event is MeetConnectionAnswer) {
      if (event.clientId == clientId) {
        _peerConnection.setRemoteDescription(event.answer);
        // _peerConnection.onIceCandidate = (candidate) {
        //   print('onIceCandidate: $candidate');
        //   roomClient.sendCandidate(clientId, candidate);
        // };
      }
    }

    if (event is MeetConnectionCandidate) {
      if (event.clientId == clientId) {
        _peerConnection.addCandidate(event.candidate);
      }
    }
  }

  setLocalStream(MediaStream stream) {
    _peerConnection.addStream(stream);
  }

  dispose() {
    _peerConnection.close();
    _renderer.srcObject = null;
    _renderer.dispose();
    _eventSubscription.cancel();
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
  // List<MediaDeviceInfo>? _mediaDevicesList;
  List<MeetConnection> connections = [];

  @override
  void initState() {
    super.initState();
    localRenderer.initialize();
    eventSubscription = widget.roomClient.eventStream.listen((event) async {
      if (event is ClientJoin) {
        MeetConnection? connection = connections.firstWhereOrNull((connection) => connection.clientId == event.clientId);
        if (connection != null) return;
        // if (localStream == null) await streamCamera();
        connections.add(MeetConnection(
          clientId: event.clientId,
          roomClient: widget.roomClient,
          localstream: localStream,
        ));
      }

      if (event is ClientLeave) {
        MeetConnection? connection = connections.firstWhereOrNull((connection) => connection.clientId == event.clientId);
        connection?.dispose();
        connections.remove(connection);
      }

      if (event is MeetConnectionOffer) {
        // if (localStream == null) await streamDisplay();
        connections.add(MeetConnection(
          clientId: event.clientId,
          roomClient: widget.roomClient,
          fromOffer: event.offer,
          localstream: localStream,
        ));
      }
      setState(() {});
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
      print('tick');
    });
  }

  Future streamCamera() async {
    stopStream();
    final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
    // setState(() {
    localStream = stream;
    // });
    localRenderer.srcObject = stream;
    for (var connection in connections) {
      connection.setLocalStream(stream);
    }
  }

  Future streamDisplay() async {
    stopStream();
    final stream = await navigator.mediaDevices.getDisplayMedia({'audio': true, 'video': true});

    // setState(() {
    localStream = stream;
    // });
    localRenderer.srcObject = stream;
    for (var connection in connections) {
      connection.setLocalStream(stream);
    }
  }

  stopStream() async {
    if (kIsWeb) {
      localStream?.getTracks().forEach((track) => track.stop());
    }
    localRenderer.srcObject = null;
    localStream?.dispose();
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
                        child: RTCVideoView(
                          connection._renderer,
                          mirror: true,
                        ),
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
