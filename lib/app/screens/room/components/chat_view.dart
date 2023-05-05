// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:asv_client/app/providers/chat_view_controller_provider.dart';
import 'package:asv_client/app/widgets/chat_tiles.dart';
import 'package:asv_client/data/models/chat_entries.dart';
import 'package:asv_client/data/models/client.dart';
import 'package:flutter/material.dart';

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
          const TypingClients(),
          const Expanded(child: ChatHistory()),
          const MessageField(),
        ],
      ),
    );
  }
}

class ChatHistory extends StatelessWidget {
  const ChatHistory({super.key});

  @override
  Widget build(BuildContext context) {
    List<ChatEntry> chatHistory = ChatViewControllerProvider.watch(context).chatHistory;

    return ListView.separated(
      reverse: true,
      physics: BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      itemCount: chatHistory.length,
      itemBuilder: (context, index) {
        final chatEntry = chatHistory.reversed.toList()[index];

        if (chatEntry is Message) {
          return MessageTile(message: chatEntry);
        }

        if (chatEntry is UserJoined) {
          return JoinTile(event: chatEntry);
        }

        if (chatEntry is UserLeft) {
          return LeaveTile(event: chatEntry);
        }
        return const SizedBox();
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16),
    );
  }
}

class TypingClients extends StatelessWidget {
  const TypingClients({super.key});

  @override
  Widget build(BuildContext context) {
    Set<Client> typingClients = ChatViewControllerProvider.watch(context).typingClients;

    if (typingClients.isEmpty) return const SizedBox();

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Text(
            '${typingClients.map((e) => e.name).join(', ')} ${typingClients.length > 1 ? 'are' : 'is'} typing...',
            style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
      ],
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
