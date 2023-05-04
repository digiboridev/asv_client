// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';
import 'package:asv_client/app/controllers/rtc_peer_controller/rtc_stream_track.dart';
import 'package:asv_client/app/providers/meet_view_controller_provider.dart';
import 'package:asv_client/app/widgets/meet_button.dart';
import 'package:asv_client/app/widgets/meet_tiles.dart';
import 'package:flutter/material.dart';
import 'package:asv_client/app/controllers/meet_view_controller.dart';

class MeetView extends StatelessWidget {
  const MeetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Expanded(child: MeetArea()),
          const SizedBox(height: 16),
          const Controls(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class MeetArea extends StatelessWidget {
  const MeetArea({super.key});

  @override
  Widget build(BuildContext context) {
    MeetViewController meetViewController = MeetViewControllerProvider.watch(context);
    int tilesCount = meetViewController.peers.length + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxHeight = constraints.maxHeight;
        double maxWidth = constraints.maxWidth;
        double squareSize = 0;

        if (tilesCount == 1) {
          double lowestSide = maxHeight > maxWidth ? maxWidth : maxHeight;
          squareSize = lowestSide;
        } else {
          double area = maxHeight * maxWidth;
          double squareArea = area / tilesCount;
          double squareSide = sqrt(squareArea);
          squareSize = squareSide * 0.75;
        }

        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: maxWidth,
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TileWrapper(
                    squareSize: squareSize,
                    child: ClientTile(
                      meetViewController: meetViewController,
                    )),
                ...meetViewController.peers.map((p) {
                  return TileWrapper(
                    key: ValueKey(p.memberId),
                    squareSize: squareSize,
                    child: PeerTile(
                      peer: p,
                    ),
                  );
                })
              ],
            ),
          ),
        );
      },
    );
  }
}

class Controls extends StatefulWidget {
  const Controls({super.key});

  @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  bool busy = false;

  MeetViewController get meetViewController => MeetViewControllerProvider.read(context);

  enableAudio() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await meetViewController.enableAudio();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      debugPrint(e.toString());
    }
    setState(() => busy = false);
  }

  enableCamera() async {
    if (busy) return;

    setState(() => busy = true);
    try {
      await meetViewController.enableCamera();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      debugPrint(e.toString());
    }
    setState(() => busy = false);
  }

  enableDisplay() async {
    if (busy) return;

    setState(() => busy = true);
    try {
      await meetViewController.enableDisplay();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      debugPrint(e.toString());
    }
    setState(() => busy = false);
  }

  disableAudio() => meetViewController.disableAudio();
  disableVideo() => meetViewController.disableVideo();

  bool get audioEnabled => meetViewController.audioTrack != null;
  bool get cameraEnabled => meetViewController.videoTrack != null && meetViewController.videoTrack!.kind == RTCTrackKind.camera;
  bool get displayEnabled => meetViewController.videoTrack != null && meetViewController.videoTrack!.kind == RTCTrackKind.display;

  @override
  Widget build(BuildContext context) {
    MeetViewControllerProvider.watch(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (audioEnabled) MeetButton(icon: Icon(Icons.mic_outlined), onPressed: disableAudio, tooltip: 'Disable audio'),
        if (!audioEnabled) MeetButton(icon: Icon(Icons.mic_off_outlined), onPressed: enableAudio, tooltip: 'Enable audio'),
        SizedBox(width: 32),
        if (cameraEnabled) MeetButton(icon: Icon(Icons.videocam_outlined), onPressed: disableVideo, tooltip: 'Disable camera'),
        if (!cameraEnabled) MeetButton(icon: Icon(Icons.videocam_off_outlined), onPressed: enableCamera, tooltip: 'Enable camera'),
        SizedBox(width: 32),
        if (displayEnabled) MeetButton(icon: Icon(Icons.screen_share_outlined), onPressed: disableVideo, tooltip: 'Disable display'),
        if (!displayEnabled) MeetButton(icon: Icon(Icons.stop_screen_share_outlined), onPressed: enableDisplay, tooltip: 'Enable display'),
      ],
    );
  }
}
