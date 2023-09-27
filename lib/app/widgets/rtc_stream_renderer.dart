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
  late final bool hasVideo = widget.stream.getVideoTracks().isNotEmpty;

  OverlayEntry? overlayEntry;

  openFullScreenOverlay() {
    if (!hasVideo) return;
    if (overlayEntry != null) return;

    OverlayState overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(builder: (context) {
      return Stack(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            color: Colors.black.withOpacity(0.9),
            child: RTCVideoView(
              rtcVideoRenderer,
              mirror: widget.mirror,
            ),
          ),
          Positioned(
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: closeOverlay,
              ),
            ),
          ),
        ],
      );
    });

    overlayState.insert(overlayEntry!);
    setState(() {});
  }

  closeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
    setState(() {});
  }

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
    overlayEntry?.remove();
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
    if (overlayEntry != null) {
      return SizedBox(
        width: 0,
        height: 0,
      );
    }

    return SizedBox.expand(
      child: GestureDetector(
        onDoubleTap: () => openFullScreenOverlay(),
        child: Tooltip(
          waitDuration: Duration(seconds: 2),
          message: 'Double tap to open full screen',
          child: RTCVideoView(
            rtcVideoRenderer,
            objectFit: _objectFit,
            mirror: widget.mirror,
          ),
        ),
      ),
    );
  }
}
