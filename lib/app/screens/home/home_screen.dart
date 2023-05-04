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
            Spacer(),
            ElevatedButton(onPressed: () => toRoom(context), child: const Text('To Room')),
            Spacer(),
            Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.end, children: [
              Padding(padding: const EdgeInsets.all(8.0), child: const Text('1.0.52')),
            ]),
          ],
        ),
      ),
    );
  }
}
