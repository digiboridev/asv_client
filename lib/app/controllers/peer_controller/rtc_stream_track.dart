import 'package:flutter_webrtc/flutter_webrtc.dart';

enum RTCTrackKind {
  audio,
  camera,
  display,
}

class RTCStreamTrack {
  final MediaStreamTrack track;
  final MediaStream stream;
  final RTCTrackKind kind;
  RTCStreamTrack({
    required this.track,
    required this.stream,
    required this.kind,
  });
}
