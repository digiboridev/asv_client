import 'dart:async';
import 'package:asv_client/core/env.dart';
import 'package:asv_client/data/models/client.dart';
import 'package:asv_client/data/repositories/client_repository.dart';
import 'package:asv_client/data/transport/room_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/data/transport/room_client.dart';
import 'package:socket_io_client/socket_io_client.dart';

class RoomClientSocketImpl extends ChangeNotifier implements RoomClient {
  RoomClientSocketImpl({
    required String roomId,
    required ClientRepository clientRepository,
  })  : _roomId = roomId,
        _clientRepository = clientRepository {
    _init();
  }

  final String _roomId;
  final ClientRepository _clientRepository;
  final _eventsStreamController = StreamController<RoomEvent>.broadcast();
  late final Socket _socket;
  late final Timer _signalTimer;
  RoomConnectionState _connectionState = RoomConnectionState.connecting;
  bool _disposed = false;

  @override
  RoomConnectionState get connectionState => _connectionState;

  @override
  Stream<RoomEvent> get eventStream => _eventsStreamController.stream;

  //
  // Chat Actions
  @override
  Future sendMessage(String message) async => _socket.emit('msg', message);

  @override
  Future sendTyping() async => _socket.emit('typing', _socket.id);

  @override
  Future sendTypingCancel() async => _socket.emit('typing_cancel', _socket.id);
  // End Chat Actions
  //

  //
  // RTC Actions
  @override
  Future<String> sendWarmupAck({required String memberId}) async {
    final c = Completer<String>();
    Timer(const Duration(seconds: 2), () {
      if (!c.isCompleted) c.complete('timeout');
    });

    _socket.emitWithAck('rtc_warmup_ack', {
      'from': _socket.id,
      'to': memberId,
    }, ack: (String data) {
      if (!c.isCompleted) c.complete(data);
    });

    return c.future;
  }

  @override
  Future sendOffer({required String memberId, required RTCSessionDescription offer}) async {
    _socket.emit('rtc_offer', {'from': _socket.id, 'to': memberId, 'offer': offer.toMap()});
  }

  @override
  Future sendAnswer({required String memberId, required RTCSessionDescription answer}) async {
    _socket.emit('rtc_answer', {'from': _socket.id, 'to': memberId, 'answer': answer.toMap()});
  }

  @override
  Future sendCandidate({required String memberId, required PcType pcType, required RTCIceCandidate candidate}) async {
    _socket.emit('rtc_candidate', {'from': _socket.id, 'to': memberId, 'pc_type': pcType.name, 'candidate': candidate.toMap()});
  }
  // End RTC Actions
  //

  _init() async {
    String apiKey = Env.apiKey;
    String url = Env.apiUrl;
    Client client = await _clientRepository.getClient();

    _socket = io(
      url,
      OptionBuilder().enableForceNew().setTransports(['websocket']).setAuth(
        {
          'apiKey': apiKey,
          'roomId': _roomId,
          'client': client.toMap(),
        },
      ).build(),
    );

    _socket.onAny((event, data) {
      if (_disposed) return;
      RoomEvent? roomEvent = _eventParser(event: event, data: data);
      if (roomEvent != null) _eventsStreamController.add(roomEvent);
      if (roomEvent is ClientJoin) _socket.emit('presence_signal', _socket.id);
    });

    _socket.on('error', (data) {
      debugPrint('socket error: $data');
      if (_disposed) return;
      _connectionState = RoomConnectionState.connectError;
      _eventsStreamController.add(ConnectionStateChanged(state: _connectionState));
      notifyListeners();
    });

    _socket.on('connect', (data) {
      debugPrint('socket connect: ${_socket.id}');
      if (_disposed) return;
      _connectionState = RoomConnectionState.connected;
      _eventsStreamController.add(ConnectionStateChanged(state: _connectionState));
      notifyListeners();
    });

    _socket.on('disconnect', (data) {
      debugPrint('socket disconnect');
      if (_disposed) return;
      _connectionState = RoomConnectionState.disconnected;
      _eventsStreamController.add(ConnectionStateChanged(state: _connectionState));
      notifyListeners();
    });

    // start presence signal sender
    // send signal every 5 seconds to keep connection alive and notify members that client is still online
    _signalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _socket.emit('presence_signal', _socket.id);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _socket.dispose();
    _eventsStreamController.close();
    _signalTimer.cancel();
    super.dispose();
  }
}

/// Parses raw socket events into [RoomEvent]
/// Returns null if event is not supported
RoomEvent? _eventParser({required String event, required dynamic data}) {
  try {
    switch (event) {
      case 'presence_join':
        return ClientJoin(
          client: Client.fromMap(data['client']),
          memberId: data['memberId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'presence_leave':
        return ClientLeave(
          client: Client.fromMap(data['client']),
          memberId: data['memberId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'presence_signal':
        return ClientSignal(
          client: Client.fromMap(data['client']),
          memberId: data['memberId'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'msg':
        return NewMessage(
          client: Client.fromMap(data['client']),
          message: data['message'],
          time: DateTime.fromMillisecondsSinceEpoch(data['time']),
        );
      case 'typing':
        return ClientTyping(
          client: Client.fromMap(data['client']),
        );
      case 'typing_cancel':
        return ClientTypingCancel(
          client: Client.fromMap(data['client']),
        );
      case 'rtc_warmup_ack':
        var d = data as List;
        return RTCWarmup(
          memberId: d.first['from'],
          callback: d.last,
        );
      case 'rtc_offer':
        return RTCOffer(
          memberId: data['from'],
          offer: RTCSessionDescription(
            data['offer']['sdp'],
            data['offer']['type'],
          ),
        );
      case 'rtc_answer':
        return RTCAnswer(
          memberId: data['from'],
          answer: RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          ),
        );
      case 'rtc_candidate':
        return RTCCandidate(
          memberId: data['from'],
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
