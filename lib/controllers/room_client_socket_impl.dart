import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/core/constants.dart';
import 'package:asv_client/domain/controllers/room_client.dart';
import 'package:socket_io_client/socket_io_client.dart';

class RoomClientSocketImpl extends ChangeNotifier implements RoomClient {
  RoomClientSocketImpl({
    required this.roomId,
  }) {
    init();
  }

  @override
  final String roomId;
  @override
  final String clientId = Random().nextInt(1000000).toString();

  late final Socket _socket;

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
      'http://localhost:3000',
      OptionBuilder().enableForceNew().setTransports(['websocket']).setAuth(
        {'token': kRoomSocketToken, 'roomId': roomId, 'clientId': clientId},
      ).build(),
    );
    _socket.onAny((event, data) {
      RoomEvent? roomEvent = _eventParser(event: event, data: data);
      if (roomEvent != null) _eventsStreamController.add(roomEvent);
      debugPrint('event: $event, data: $data');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    _eventsStreamController.close();
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
  Future sendCandidate(String toClientId, RTCIceCandidate candidate) async {
    _socket.emit('rtc_candidate', {
      'from': clientId,
      'to': toClientId,
      'candidate': candidate.toMap(),
    });
  }
}

RoomEvent? _eventParser({required String event, required dynamic data}) {
  try {
    switch (event) {
      case 'join':
        return ClientJoin(
          clientId: data['clientId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'leave':
        return ClientLeave(
          clientId: data['clientId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'msg':
        return ChatMessage(
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
      case 'rtc_offer':
        return MeetConnectionOffer(
          clientId: data['from'],
          offer: RTCSessionDescription(
            data['offer']['sdp'],
            data['offer']['type'],
          ),
        );
      case 'rtc_answer':
        return MeetConnectionAnswer(
          clientId: data['from'],
          answer: RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          ),
        );
      case 'rtc_candidate':
        return MeetConnectionCandidate(
          clientId: data['from'],
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
    print(e);
    return null;
  }
}
