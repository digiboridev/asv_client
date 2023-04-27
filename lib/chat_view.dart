import 'dart:async';
import 'package:asv_client/data/room_events.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:asv_client/data/room_client.dart';

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.client,
  });

  final RoomClient client;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController scrollController = ScrollController();
  late final StreamSubscription _messagesSubscription;
  List<RoomEvent> chatHistory = []; // Chat history related events only (join, leave, message)
  Set<String> typingClients = {}; // Clients currently typing

  @override
  void initState() {
    super.initState();
    _messagesSubscription = widget.client.eventStream.listen(eventHandler);
  }

  @override
  void dispose() {
    super.dispose();
    _messagesSubscription.cancel();
  }

  eventHandler(RoomEvent event) {
    // Handle chat history related events
    if (event is NewMessage || event is ClientJoin || event is ClientLeave) {
      setState(() => chatHistory.add(event));

      // Scroll list to bottom
      if (scrollController.position.maxScrollExtent == scrollController.offset) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        });
      }
    }

    // Handle typing related events
    if (event is ClientTyping) {
      setState(() => typingClients.add(event.clientId));
    }

    if (event is ClientTypingCancel && typingClients.contains(event.clientId)) {
      setState(() => typingClients.remove(event.clientId));
    }

    if (event is ClientLeave && typingClients.contains(event.clientId)) {
      setState(() => typingClients.remove(event.clientId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Visibility(
            visible: typingClients.isNotEmpty,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                '${typingClients.join(', ')} ${typingClients.length > 1 ? 'are' : 'is'} typing...',
                style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
              child: ShaderMask(
            shaderCallback: (Rect rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
                stops: [0.0, 0.03, 0.95, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstOut,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 12, top: 12),
              controller: scrollController,
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final chatItem = chatHistory[index];

                if (chatItem is NewMessage) {
                  return CLMessageTile(message: chatItem);
                }

                if (chatItem is ClientJoin) {
                  return CLJoinTile(event: chatItem);
                }

                if (chatItem is ClientLeave) {
                  return CLLeaveTile(event: chatItem);
                }
                return const SizedBox();
              },
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            ),
          )),
          MessageField(client: widget.client),
        ],
      ),
    );
  }
}

class MessageField extends StatefulWidget {
  const MessageField({super.key, required this.client});

  final RoomClient client;

  @override
  State<MessageField> createState() => _MessageFieldState();
}

class _MessageFieldState extends State<MessageField> {
  final TextEditingController _controller = TextEditingController();

  sendMessage() {
    if (_controller.text.isEmpty) return;
    widget.client.sendMessage(_controller.text);
    widget.client.sendTypingCancel();
    _controller.clear();
  }

  startTyping() {
    widget.client.sendTyping();
  }

  stopTyping() {
    widget.client.sendTypingCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (value) {
                if (value.isEmpty) {
                  stopTyping();
                } else {
                  startTyping();
                }
              },
              onEditingComplete: sendMessage,
              decoration: const InputDecoration(
                hintText: 'Type your message',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(onPressed: sendMessage, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}

class CLMessageTile extends StatefulWidget {
  const CLMessageTile({super.key, required this.message});

  final NewMessage message;

  @override
  State<CLMessageTile> createState() => _CLMessageTileState();
}

class _CLMessageTileState extends State<CLMessageTile> {
  late final String formattedDate;

  @override
  void initState() {
    super.initState();
    // Prepare date string
    bool sameDate = DateTime.now().difference(widget.message.time).inDays == 0;
    if (sameDate) {
      formattedDate = DateFormat('HH:mm').format(widget.message.time);
    } else {
      formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(widget.message.time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 4,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Text(
                  widget.message.clientId,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              widget.message.message,
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

class CLJoinTile extends StatefulWidget {
  const CLJoinTile({super.key, required this.event});

  final ClientJoin event;

  @override
  State<CLJoinTile> createState() => _CLJoinTileState();
}

class _CLJoinTileState extends State<CLJoinTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        '${widget.event.clientId} joined',
        style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class CLLeaveTile extends StatefulWidget {
  const CLLeaveTile({super.key, required this.event});

  final ClientLeave event;

  @override
  State<CLLeaveTile> createState() => _CLLeaveTileState();
}

class _CLLeaveTileState extends State<CLLeaveTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        '${widget.event.clientId} left',
        style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
