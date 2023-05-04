
import 'package:asv_client/app/router/router.dart';
import 'package:flutter/material.dart';

class RouterProvider extends InheritedNotifier<RootRouterDelegate> {
  const RouterProvider({super.key, required super.child, required RootRouterDelegate router}) : super(notifier: router);

  static RootRouterDelegate watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RouterProvider>()!.notifier!;
  }

  static RootRouterDelegate read(BuildContext context) {
    return context.findAncestorWidgetOfExactType<RouterProvider>()!.notifier!;
  }
}
