import 'dart:math';
import 'package:flutter/material.dart';
import 'package:asv_client/screens/room/room_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASV Client',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const Main(),
    );
  }
}

// Main app widget
class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  MainState createState() => MainState();
}

class MainState extends State<Main> {
  @override
  void initState() {
    super.initState();
  }

  toRoom() {
    showDialog(context: context, builder: (context) => const RoomIdDialog());
    // Navigator.of(context).push(MaterialPageRoute(builder: (context) => RoomScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          children: [
            const Text('48'),
            ElevatedButton(onPressed: toRoom, child: const Text('To Room')),
          ],
        ),
      ),
    );
  }
}

// Dialog for entering room id
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
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => RoomScreen(roomId: roomId)));
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
