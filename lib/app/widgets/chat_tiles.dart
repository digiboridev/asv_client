import 'package:asv_client/data/models/chat_entries.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageTile extends StatefulWidget {
  const MessageTile({super.key, required this.message});

  final Message message;

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
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
                  widget.message.userName,
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

class JoinTile extends StatefulWidget {
  const JoinTile({super.key, required this.event});

  final UserJoined event;

  @override
  State<JoinTile> createState() => _JoinTileState();
}

class _JoinTileState extends State<JoinTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        '${widget.event.userName} joined',
        style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class LeaveTile extends StatefulWidget {
  const LeaveTile({super.key, required this.event});

  final UserLeft event;

  @override
  State<LeaveTile> createState() => _LeaveTileState();
}

class _LeaveTileState extends State<LeaveTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        '${widget.event.userName} left',
        style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
