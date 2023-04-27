import 'dart:async';
import 'dart:math';
import 'package:asv_client/data/room_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/core/constants.dart';
import 'package:asv_client/data/room_client.dart';
import 'package:socket_io_client/socket_io_client.dart';

class RoomClientSocketImpl extends ChangeNotifier implements RoomClient {
  RoomClientSocketImpl({
    required String roomId,
  }) : _roomId = roomId {
    init();
  }

  late final Socket _socket;
  late final Timer _signalTimer;
  final String _roomId;
  final String _clientId = Random().nextInt(1000000).toString();

  @override
  String get roomId => _roomId;
  @override
  String get clientId => _clientId;

  // Connection status section
  @override
  bool get isConnected => _socket.connected;
  @override
  bool get isDisconnected => _socket.disconnected;
  @override
  bool get isActive => _socket.active;
  // End of connection status section

  final _eventsStreamController = StreamController<RoomEvent>.broadcast();
  @override
  Stream<RoomEvent> get eventStream => _eventsStreamController.stream;

  init() {
    _socket = io(
      'https://asv-socket.onrender.com',
      // 'http://localhost:3000',
      OptionBuilder().enableForceNew().setTransports(['websocket']).setAuth(
        {'token': kRoomSocketToken, 'roomId': roomId, 'clientId': clientId},
      ).build(),
    );

    _socket.onAny((event, data) {
      RoomEvent? roomEvent = _eventParser(event: event, data: data);
      if (roomEvent != null) _eventsStreamController.add(roomEvent);
      if (roomEvent is ClientJoin) _socket.emit('presence_signal', clientId);
      notifyListeners();
    });

    _signalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _socket.emit('presence_signal', clientId);
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    _eventsStreamController.close();
    _signalTimer.cancel();
    super.dispose();
  }

  @override
  Future sendMessage(String message) async => _socket.emit('msg', {
        'text': message,
        'clientId': clientId,
        'time': DateTime.now().millisecondsSinceEpoch,
      });

  @override
  Future sendTyping() async => _socket.emit('typing', clientId);

  @override
  Future sendTypingCancel() async => _socket.emit('typing_cancel', clientId);

  // RTC section
  @override
  Future<String> sendWarmupAck(String toClientId) async {
    final c = Completer<String>();
    Timer(const Duration(seconds: 2), () {
      if (!c.isCompleted) c.complete('timeout');
    });

    _socket.emitWithAck('rtc_warmup_ack', {
      'from': clientId,
      'to': toClientId,
    }, ack: (String data) {
      if (!c.isCompleted) c.complete(data);
    });

    return c.future;
  }

  @override
  Future sendOffer(String toClientId, RTCSessionDescription offer) async {
    _socket.emit('rtc_offer', {
      'from': clientId,
      'to': toClientId,
      'offer': offer.toMap(),
    });
  }

  @override
  Future sendAnswer(String toClientId, RTCSessionDescription answer) async {
    _socket.emit('rtc_answer', {
      'from': clientId,
      'to': toClientId,
      'answer': answer.toMap(),
    });
  }

  @override
  Future sendCandidate(String toClientId, PcType pcType, RTCIceCandidate candidate) async {
    _socket.emit('rtc_candidate', {
      'from': clientId,
      'to': toClientId,
      'pc_type': pcType.name,
      'candidate': candidate.toMap(),
    });
  }
}

RoomEvent? _eventParser({required String event, required dynamic data}) {
  try {
    switch (event) {
      case 'presence_join':
        return ClientJoin(
          clientId: data['clientId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'presence_leave':
        return ClientLeave(
          clientId: data['clientId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'presence_signal':
        return ClientSignal(
          clientId: data['clientId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'msg':
        return NewMessage(
          message: data['text'],
          clientId: data['clientId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'typing':
        return ClientTyping(
          clientId: data['clientId'],
        );
      case 'typing_cancel':
        return ClientTypingCancel(
          clientId: data['clientId'],
        );
      case 'rtc_warmup_ack':
        var d = data as List;
        return RTCWarmup(
          clientId: d.first['from'],
          callback: d.last,
        );
      case 'rtc_offer':
        return RTCOffer(
          clientId: data['from'],
          offer: RTCSessionDescription(
            data['offer']['sdp'],
            data['offer']['type'],
          ),
        );
      case 'rtc_answer':
        return RTCAnswer(
          clientId: data['from'],
          answer: RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          ),
        );
      case 'rtc_candidate':
        return RTCCandidate(
          clientId: data['from'],
          pcType: PcType.values.byName(data['pc_type']),
          candidate: RTCIceCandidate(
            data['candidate']['candidate'],
            data['candidate']['sdpMid'],
            data['candidate']['sdpMLineIndex'],
          ),
        );
      default:
        return null;
    }
  } catch (e) {
    return null;
  }
}
