// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';
import 'package:asv_client/controllers/peer_controller/connection_state.dart';
import 'package:asv_client/screens/room/components/meet_buttons.dart';
import 'package:asv_client/screens/room/room_screen.dart';
import 'package:flutter/material.dart';
import 'package:asv_client/controllers/meet_view_controller.dart';
import 'package:asv_client/controllers/peer_controller/peer_controller.dart';
import 'package:asv_client/controllers/peer_controller/rtc_stream_track.dart';
import 'package:asv_client/widgets/rtc_stream_renderer.dart';
import 'package:flutter_fadein/flutter_fadein.dart';

class MeetView extends StatelessWidget {
  const MeetView({super.key});

  @override
  Widget build(BuildContext context) {
    MeetViewController meetViewController = MeetViewControllerProvider.watch(context);
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          SizedBox(height: 16),
          Expanded(child: MeetViewBody(meetViewController: meetViewController)),
          SizedBox(height: 16),
          MeetButtons(meetViewController: meetViewController),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class MeetViewBody extends StatelessWidget {
  const MeetViewBody({
    super.key,
    required MeetViewController meetViewController,
  }) : _meetViewController = meetViewController;

  final MeetViewController _meetViewController;

  @override
  Widget build(BuildContext context) {
    int tilesCount = _meetViewController.peers.length + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxHeight = constraints.maxHeight;
        double maxWidth = constraints.maxWidth;
        double squareSize = 0;

        if (tilesCount == 1) {
          if (maxHeight > maxWidth) {
            squareSize = maxWidth;
          } else {
            squareSize = maxHeight;
          }
        } else {
          double area = maxHeight * maxWidth;
          double squareArea = area / tilesCount;
          double squareSide = sqrt(squareArea);
          squareSize = squareSide * 0.75;
        }

        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TileWrapper(
                squareSize: squareSize,
                child: ClientTile(
                  meetViewController: _meetViewController,
                )),
            ..._meetViewController.peers.map((p) {
              return TileWrapper(
                squareSize: squareSize,
                child: PeerTile(
                  peer: p,
                ),
              );
            })
          ],
        );
      },
    );
  }
}

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
    return Container(
      color: Colors.amber,
      child: Builder(builder: (_) {
        RTCStreamTrack? videoTrack = widget._meetViewController.videoTrack;
        if (videoTrack != null) {
          return RTCStreamRenderer(
            stream: videoTrack.stream,
            mirror: true,
          );
        }
        return const SizedBox.shrink();
      }),
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
    return Container(
        color: Colors.pink,
        child: AnimatedBuilder(
          animation: widget.peer,
          builder: (context, child) {
            return Stack(
              children: [
                SizedBox.expand(
                  child: placeholder(),
                ),
                if (widget.peer.audioStream != null)
                  RTCStreamRenderer(
                    stream: widget.peer.audioStream!,
                  ),
                if (widget.peer.videoStream != null)
                  RTCStreamRenderer(
                    stream: widget.peer.videoStream!,
                    fit: fit,
                  ),
                overlay(),
              ],
            );
          },
        ));
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
                  widget.peer.clientId,
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
