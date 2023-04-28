import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum Fit {
  cover,
  contain,
}

class RTCStreamRenderer extends StatefulWidget {
  const RTCStreamRenderer({
    required this.stream,
    this.fit = Fit.contain,
    this.mirror = false,
    super.key,
  });

  final MediaStream stream;
  final Fit fit;
  final bool mirror;

  @override
  State<RTCStreamRenderer> createState() => _RTCStreamRendererState();
}

class _RTCStreamRendererState extends State<RTCStreamRenderer> {
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

  RTCVideoViewObjectFit get _objectFit {
    switch (widget.fit) {
      case Fit.cover:
        return RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
      case Fit.contain:
        return RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
        child: RTCVideoView(
      rtcVideoRenderer,
      objectFit: _objectFit,
      mirror: widget.mirror,
    ));
  }
}
