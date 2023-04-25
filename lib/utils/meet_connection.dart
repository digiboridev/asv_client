// ignore_for_file: prefer_final_fields
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/core/constants.dart';
import 'package:asv_client/domain/controllers/room_client.dart';

class Transmitter {
  Transmitter({
    required this.clientId,
    required this.roomClient,
    required this.stream,
  }) {
    _init();
  }

  final String clientId;
  final RoomClient roomClient;
  final MediaStream stream;

  bool _disposed = false;
  RTCPeerConnection? _pc;

  Future _warmup() async {
    if (_disposed) return;

    debugPrint('warming up');

    String result = await roomClient.sendWarmupAck(clientId);
    if (result != 'ready') {
      debugPrint('Warmup ack failed, retrying');
      return await _warmup();
    }

    debugPrint('Warmup ack: $result');
  }

  Future _setup() async {
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

    for (var track in stream.getTracks()) {
      await _pc!.addTrack(track, stream);
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
    await _setup();
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
    required this.renderer,
  }) {
    _setup();
  }

  final String clientId;
  final RoomClient roomClient;
  final RTCVideoRenderer renderer;

  bool _disposed = false;
  RTCPeerConnection? _pc;

  Future _setup() async {
    debugPrint('rx setting up');

    _pc = await createPeerConnection(peerConfig);

    _pc!.onIceCandidate = (candidate) {
      debugPrint('tx onIceCandidate: $candidate');
      roomClient.sendCandidate(clientId, PcType.rx, candidate);
    };

    _pc!.onConnectionState = (state) {
      debugPrint('rx onConnectionState: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        renderer.srcObject = null;
      }
    };

    _pc!.onTrack = (track) async {
      debugPrint('rx onTrack');
      renderer.srcObject = track.streams.first;
    };

    roomClient.sendReady(clientId);
  }

  connect(RTCSessionDescription offer) async {
    if (_disposed) return;
    debugPrint('rx connect');

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
    if (event is MeetConnectionWarmupAck && event.clientId == clientId) {
      initReceiver();
      event.callback('ready');
    }
    if (event is MeetConnectionOffer && event.clientId == clientId) {
      _receiver?.connect(event.offer);
    }

    if (event is MeetConnectionAnswer && event.clientId == clientId) {
      _transmitter?.setRemoteDescription(event.answer);
    }

    if (event is MeetConnectionCandidate && event.clientId == clientId) {
      // Pay attention to the pcType here
      // RX candidate is for TX pc and vice versa
      if (event.pcType == PcType.tx) {
        debugPrint('RX candidate is received');
        _receiver?.addCandidate(event.candidate);
      } else {
        debugPrint('TX candidate is received');
        _transmitter?.addCandidate(event.candidate);
      }
    }
  }

  dispose() {
    _transmitter?.dispose();
    _receiver?.dispose();
    _eventSubscription.cancel();
    renderer.srcObject = null;
    renderer.dispose();
  }
}
