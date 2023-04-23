import 'dart:math';
import 'package:flutter/material.dart';
import 'package:asv_client/room_screen.dart';
import 'package:socket_io_client/socket_io_client.dart';

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
  late final Socket socket;

  @override
  void initState() {
    super.initState();
    // socket = io('http://localhost:3000', OptionBuilder().setTransports(['websocket']).disableAutoConnect().setAuth({'token': '123'}).build());

    // socket.onAny((event, data) {
    //   print('event: $event, data: $data');
    //   setState(() {});

    //   if (event == 'error') {
    //     // socket.destroy();
    //   }
    // });

    // socket.on('msg', (data) {
    //   print('msg: $data');
    // });
  }

  toRoom() {
    showDialog(context: context, builder: (context) => const RoomIdDialog());
    // Navigator.of(context).push(MaterialPageRoute(builder: (context) => RoomScreen()));
  }

  // connect() {
  //   socket.connect();
  // }

  // disconnect() {
  //   socket.disconnect();
  // }

  // sendMessage(String message) {
  //   socket.emit('msg', message);
  // }

  // sendAkw(String message) {
  //   socket.emitWithAck('ack', message, ack: (data) {
  //     print('ack: $data');
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          children: [
            Text('13'),
            // Text('Connected: ${socket.connected}'),
            // Text('Disconnected: ${socket.disconnected}'),
            // Text('Active: ${socket.active}'),
            // Text('Id: ${socket.id}'),
            // SizedBox(height: 8),
            ElevatedButton(onPressed: toRoom, child: const Text('To Room')),
            // SizedBox(height: 8),
            // ElevatedButton(onPressed: connect, child: const Text('Connect')),
            // SizedBox(height: 8),
            // ElevatedButton(onPressed: disconnect, child: const Text('Disconnect')),
            // SizedBox(height: 8),
            // ElevatedButton(onPressed: () => sendMessage('test'), child: const Text('Send Message')),
            // SizedBox(height: 8),
            // ElevatedButton(onPressed: () => sendAkw('test ack'), child: const Text('Send Message with Ack')),
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
                SizedBox(height: 16),
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
                SizedBox(height: 16),
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
