import 'package:flutter_webrtc/flutter_webrtc.dart';

class TrueStreamTrack {
  final MediaStreamTrack track;
  final MediaStream stream;
  TrueStreamTrack({
    required this.track,
    required this.stream,
  });
}
