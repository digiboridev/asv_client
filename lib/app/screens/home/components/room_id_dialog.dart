import 'dart:math';
import 'package:asv_client/app/router/path.dart';
import 'package:asv_client/app/providers/root_router_provider.dart';
import 'package:flutter/material.dart';

class RoomIdDialog extends StatefulWidget {
  const RoomIdDialog({super.key});

  @override
  State<RoomIdDialog> createState() => _RoomIdDialogState();
}

class _RoomIdDialogState extends State<RoomIdDialog> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController roomIdController = TextEditingController();
  String roomId = '';

  onJoin() {
    if (formKey.currentState!.validate()) {
      Navigator.of(context).pop();
      RouterProvider.read(context).push(RoomPath(roomId));
    }
  }

  generateRoomId() {
    final random = Random();
    final roomId = random.nextInt(1000000) * 1233254;
    roomIdController.text = (roomId).toString();
    setState(() => this.roomId = roomId.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter room id',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: roomIdController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter room id';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() => roomId = value),
                  onEditingComplete: () => onJoin(),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(),
                    labelText: 'Room id',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: generateRoomId, child: const Text('Generate')),
                    ElevatedButton(onPressed: onJoin, child: const Text('Join')),
                  ],
                ),
              ],
            ),
          )),
    );
  }
}
