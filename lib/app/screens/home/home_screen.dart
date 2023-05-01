import 'package:asv_client/app/screens/home/components/room_id_dialog.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  toRoom(BuildContext context) {
    showDialog(context: context, builder: (context) => const RoomIdDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          children: [
            const Text('50'),
            ElevatedButton(onPressed: () => toRoom(context), child: const Text('To Room')),
          ],
        ),
      ),
    );
  }
}
