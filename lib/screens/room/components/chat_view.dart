// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:asv_client/data/room_events.dart';
import 'package:asv_client/screens/room/room_screen.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

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
            visible: ChatViewControllerProvider.watch(context).typingClients.isNotEmpty,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                '${ChatViewControllerProvider.watch(context).typingClients.join(', ')} ${ChatViewControllerProvider.watch(context).typingClients.length > 1 ? 'are' : 'is'} typing...',
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
              reverse: true,
              physics: BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 12, top: 12),
              itemCount: ChatViewControllerProvider.watch(context).chatHistory.length,
              itemBuilder: (context, index) {
                final chatItem = ChatViewControllerProvider.watch(context).chatHistory.reversed.toList()[index];

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
          MessageField(),
        ],
      ),
    );
  }
}

class MessageField extends StatefulWidget {
  const MessageField({super.key});

  @override
  State<MessageField> createState() => _MessageFieldState();
}

class _MessageFieldState extends State<MessageField> {
  final TextEditingController _controller = TextEditingController();

  sendMessage() {
    if (_controller.text.isEmpty) return;
    ChatViewControllerProvider.read(context).sendMessage(_controller.text);
    _controller.clear();
  }

  startedTyping() {
    ChatViewControllerProvider.read(context).startedTyping();
  }

  stoppedTyping() {
    ChatViewControllerProvider.read(context).stoppedTyping();
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
                  stoppedTyping();
                } else {
                  startedTyping();
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
