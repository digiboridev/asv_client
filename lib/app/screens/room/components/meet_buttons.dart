// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:asv_client/app/controllers/meet_view_controller.dart';
import 'package:asv_client/app/controllers/peer_controller/rtc_stream_track.dart';

class MeetButtons extends StatefulWidget {
  const MeetButtons({
    Key? key,
    required this.meetViewController,
  }) : super(key: key);

  final MeetViewController meetViewController;

  @override
  State<MeetButtons> createState() => _MeetButtonsState();
}

class _MeetButtonsState extends State<MeetButtons> {
  bool busy = false;

  enableAudio() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.meetViewController.enableAudio();
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
      await widget.meetViewController.enableCamera();
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
      await widget.meetViewController.enableDisplay();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      debugPrint(e.toString());
    }
    setState(() => busy = false);
  }

  disableAudio() => widget.meetViewController.disableAudio();
  disableVideo() => widget.meetViewController.disableVideo();

  bool get audioEnabled => widget.meetViewController.audioTrack != null;
  bool get cameraEnabled => widget.meetViewController.videoTrack != null && widget.meetViewController.videoTrack!.kind == RTCTrackKind.camera;
  bool get displayEnabled => widget.meetViewController.videoTrack != null && widget.meetViewController.videoTrack!.kind == RTCTrackKind.display;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: widget.meetViewController,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (audioEnabled) Button(icon: Icon(Icons.mic_outlined), onPressed: disableAudio, tooltip: 'Disable audio'),
              if (!audioEnabled) Button(icon: Icon(Icons.mic_off_outlined), onPressed: enableAudio, tooltip: 'Enable audio'),
              SizedBox(width: 32),
              if (cameraEnabled) Button(icon: Icon(Icons.videocam_outlined), onPressed: disableVideo, tooltip: 'Disable camera'),
              if (!cameraEnabled) Button(icon: Icon(Icons.videocam_off_outlined), onPressed: enableCamera, tooltip: 'Enable camera'),
              SizedBox(width: 32),
              if (displayEnabled) Button(icon: Icon(Icons.screen_share_outlined), onPressed: disableVideo, tooltip: 'Disable display'),
              if (!displayEnabled) Button(icon: Icon(Icons.stop_screen_share_outlined), onPressed: enableDisplay, tooltip: 'Enable display'),
            ],
          );
        });
  }
}

class Button extends StatelessWidget {
  const Button({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.tooltip = '',
  }) : super(key: key);

  final Icon icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(4, 4), // changes position of shadow
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        iconSize: 24,
        icon: icon,
        color: Colors.pink.shade800,
        onPressed: onPressed,
      ),
    );
  }
}
