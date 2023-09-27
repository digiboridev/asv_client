import 'package:asv_client/app/controllers/meet_view_controller.dart';
import 'package:asv_client/app/controllers/rtc_peer_controller/connection_state.dart';
import 'package:asv_client/app/controllers/rtc_peer_controller/peer_controller.dart';
import 'package:asv_client/app/controllers/rtc_peer_controller/rtc_stream_track.dart';
import 'package:asv_client/app/widgets/rtc_stream_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fadein/flutter_fadein.dart';

class TileWrapper extends StatelessWidget {
  const TileWrapper({
    super.key,
    required this.squareSize,
    required this.child,
  });

  final double squareSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: AnimatedContainer(
        width: squareSize,
        height: squareSize,
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.all(8),
        clipBehavior: Clip.antiAlias,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class ClientTile extends StatefulWidget {
  const ClientTile({
    super.key,
    required MeetViewController meetViewController,
  }) : _meetViewController = meetViewController;

  final MeetViewController _meetViewController;

  @override
  State<ClientTile> createState() => _ClientTileState();
}

class _ClientTileState extends State<ClientTile> {
  @override
  Widget build(BuildContext context) {
    RTCStreamTrack? videoTrack = widget._meetViewController.videoTrack;

    return Stack(
      children: [
        SizedBox.expand(child: Container(color: Colors.amber)),
        if (videoTrack != null) RTCStreamRenderer(key: ValueKey(videoTrack.stream.id), stream: videoTrack.stream),
        if (videoTrack == null) SizedBox.expand(child: placeholder()),
        overlay(),
      ],
    );
  }

  Widget placeholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Icon(
          Icons.person_sharp,
          size: constraints.maxWidth / 2,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        );
      },
    );
  }

  Widget overlay() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'You',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class PeerTile extends StatefulWidget {
  const PeerTile({
    required this.peer,
    super.key,
  });

  final RTCPeerController peer;

  @override
  State<PeerTile> createState() => _PeerTileState();
}

class _PeerTileState extends State<PeerTile> {
  Fit fit = Fit.contain;
  bool muted = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onDoubleTap: () => showFS(),
      child: AnimatedBuilder(
        animation: widget.peer,
        builder: (context, child) {
          return Stack(
            children: [
              SizedBox.expand(child: Container(color: Colors.pink)),
              if (widget.peer.audioStream != null) RTCStreamRenderer(key: ValueKey(widget.peer.audioStream!.id), stream: widget.peer.audioStream!),
              if (widget.peer.videoStream != null) RTCStreamRenderer(key: ValueKey(widget.peer.videoStream!.id), stream: widget.peer.videoStream!, fit: fit),
              if (widget.peer.videoStream == null) SizedBox.expand(child: placeholder()),
              overlay(),
            ],
          );
        },
      ),
    );
  }

  Color signalColor(RTCConnectionState state) {
    switch (state) {
      case RTCConnectionState.connecting:
        return Colors.blue;
      case RTCConnectionState.connected:
        return Colors.yellow;
      case RTCConnectionState.failed:
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  toggleFit() {
    setState(() {
      if (fit == Fit.contain) {
        fit = Fit.cover;
      } else {
        fit = Fit.contain;
      }
    });
  }

  toggleAudio() {
    setState(() {
      muted = !muted;
    });
  }

  Widget overlay() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.peer.memberName,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.peer.videoStream != null)
                Tooltip(
                  message: 'Toggle video fit',
                  child: GestureDetector(
                    onTap: toggleFit,
                    child: Icon(
                      Icons.fit_screen,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          Spacer(),
          Row(
            children: [
              if (widget.peer.audioStream != null) Icon(Icons.mic_outlined, color: Colors.white),
              SizedBox(width: 8),
              if (widget.peer.videoStream != null) Icon(Icons.videocam_outlined, color: Colors.white),
              Spacer(),
              Icon(Icons.circle, size: 8, color: signalColor(widget.peer.txConnectionState)),
              SizedBox(width: 4),
              Icon(Icons.circle, size: 8, color: signalColor(widget.peer.rxConnectionState)),
            ],
          )
        ],
      ),
    );
  }

  Widget placeholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Icon(
          Icons.person_sharp,
          size: constraints.maxWidth / 2,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        );
      },
    );
  }
}
