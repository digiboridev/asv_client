import 'package:asv_client/controllers/meet_view_controller.dart';
import 'package:asv_client/controllers/peer_controller/true_stream_track.dart';
import 'package:asv_client/controllers/peer_controller/peer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:asv_client/data/room_client.dart';

class MeetView extends StatefulWidget {
  const MeetView({super.key, required this.roomClient});

  final RoomClient roomClient;

  @override
  State<MeetView> createState() => _MeetViewState();
}

class _MeetViewState extends State<MeetView> {
  late final MeetViewController _meetViewController;
  @override
  void initState() {
    super.initState();
    _meetViewController = MeetViewController(roomClient: widget.roomClient);
  }

  @override
  void dispose() {
    _meetViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: _meetViewController.enableAudio,
          child: const Text('Enable audio'),
        ),
        TextButton(
          onPressed: _meetViewController.disableAudio,
          child: const Text('Disable audio'),
        ),
        TextButton(
          onPressed: _meetViewController.enableCamera,
          child: const Text('Enable camera'),
        ),
        TextButton(
          onPressed: _meetViewController.enableDisplay,
          child: const Text('Enable display'),
        ),
        TextButton(
          onPressed: _meetViewController.disableVideo,
          child: const Text('Disable video'),
        ),
        AnimatedBuilder(
            animation: _meetViewController,
            builder: (context, _) {
              return Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ClientTile(meetViewController: _meetViewController),
                      ..._meetViewController.peers
                          .map(
                            (peer) => OpponentTile(
                              peer: peer,
                            ),
                          )
                          .toList()
                    ],
                  ),
                ),
              );
            }),
      ],
    );
  }
}

class ClientTile extends StatelessWidget {
  const ClientTile({
    super.key,
    required MeetViewController meetViewController,
  }) : _meetViewController = meetViewController;

  final MeetViewController _meetViewController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber,
      width: 200,
      height: 200,
      child: Builder(builder: (_) {
        TrueStreamTrack? videoTrack = _meetViewController.videoTrack;
        if (videoTrack != null) {
          return Renderer(
            stream: videoTrack.stream,
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}

class OpponentTile extends StatelessWidget {
  const OpponentTile({
    required this.peer,
    super.key,
  });

  final RTCPeerController peer;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.blue,
        width: 200,
        height: 200,
        child: AnimatedBuilder(
          animation: peer,
          builder: (context, child) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('TX: ${peer.txConnectionState.name}')),
                    Expanded(child: Text('RX: ${peer.rxConnectionState.name}')),
                  ],
                ),
                if (peer.audioStream != null) const Text('Audio'),
                if (peer.videoStream != null) const Text('Video'),
                if (peer.audioStream != null)
                  SizedBox.shrink(
                    child: Renderer(
                      stream: peer.audioStream!,
                    ),
                  ),
                if (peer.videoStream != null)
                  Expanded(
                    child: Renderer(
                      stream: peer.videoStream!,
                    ),
                  ),
              ],
            );
          },
        ));
  }
}

class Renderer extends StatefulWidget {
  const Renderer({
    required this.stream,
    super.key,
  });

  final MediaStream stream;

  @override
  State<Renderer> createState() => _RendererState();
}

class _RendererState extends State<Renderer> {
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

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: RTCVideoView(rtcVideoRenderer));
  }
}
