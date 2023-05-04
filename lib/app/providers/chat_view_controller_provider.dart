import 'package:asv_client/app/controllers/chat_view_controller.dart';
import 'package:flutter/material.dart';

class ChatViewControllerProvider extends InheritedNotifier<ChatViewController> {
  const ChatViewControllerProvider({super.key, required super.child, super.notifier});

  static ChatViewController watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChatViewControllerProvider>()!.notifier!;
  }

  static ChatViewController read(BuildContext context) {
    return context.findAncestorWidgetOfExactType<ChatViewControllerProvider>()!.notifier!;
  }
}
