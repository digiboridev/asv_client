import 'package:asv_client/app/controllers/meet_view_controller.dart';
import 'package:flutter/material.dart';

class MeetViewControllerProvider extends InheritedNotifier<MeetViewController> {
  const MeetViewControllerProvider({super.key, required super.child, super.notifier});

  static MeetViewController watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MeetViewControllerProvider>()!.notifier!;
  }

  static MeetViewController read(BuildContext context) {
    return context.findAncestorWidgetOfExactType<MeetViewControllerProvider>()!.notifier!;
  }
}
