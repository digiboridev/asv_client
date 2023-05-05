import 'dart:math';
import 'package:asv_client/core/service_locator.dart';
import 'package:asv_client/data/repositories/client_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoomJoinDialog extends StatefulWidget {
  const RoomJoinDialog({super.key});

  @override
  State<RoomJoinDialog> createState() => _RoomJoinDialogState();
}

class _RoomJoinDialogState extends State<RoomJoinDialog> {
  late final ClientRepository clientRepository;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController roomIdController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();

  String roomId = '';
  String nickname = '';

  onJoin() {
    if (formKey.currentState!.validate()) {
      clientRepository.getClient().then((client) => clientRepository.updateClient(client.copyWith(name: nickname)));
      Navigator.of(context).pop(roomId);
    }
  }

  generateRoomId() {
    final random = Random();
    final roomId = random.nextInt(1000000) * 1233254;
    roomIdController.text = (roomId).toString();
    setState(() => this.roomId = roomId.toString());
  }

  @override
  void initState() {
    clientRepository = ServiceLocator.createClientRepository;
    clientRepository.getClient().then((client) {
      if (!mounted) return;
      setState(() => nickname = client.name);
      nicknameController.text = client.name;
    });
    super.initState();
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
                  'Join a room',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nicknameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter nickname';
                    }
                    return null;
                  },
                  maxLength: 16,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                  onChanged: (value) => setState(() => nickname = value),
                  onEditingComplete: () => onJoin(),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(),
                    labelText: 'Nickname',
                    counter: SizedBox(),
                  ),
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
                  maxLength: 16,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                  onChanged: (value) => setState(() => roomId = value),
                  onEditingComplete: () => onJoin(),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(),
                    labelText: 'Room id',
                    counter: SizedBox(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: generateRoomId, child: const Text('Random room id')),
                    ElevatedButton(onPressed: onJoin, child: const Text('Join')),
                  ],
                ),
              ],
            ),
          )),
    );
  }
}
