import 'package:asv_client/ui/router/router.dart';
import 'package:flutter/material.dart';

class RouterProvider extends InheritedNotifier<AppRouteDelegate> {
  const RouterProvider({super.key, required super.child, required AppRouteDelegate router}) : super(notifier: router);

  static AppRouteDelegate watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RouterProvider>()!.notifier!;
  }

  static AppRouteDelegate read(BuildContext context) {
    return context.findAncestorWidgetOfExactType<RouterProvider>()!.notifier!;
  }
}
