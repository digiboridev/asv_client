import 'package:asv_client/app/providers/root_router_provider.dart';
import 'package:asv_client/app/router/path.dart';
import 'package:asv_client/app/screens/home/components/room_join_dialog.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  toRoom(BuildContext context) async {
    String? roomId = await showDialog(context: context, builder: (context) => const RoomJoinDialog());
    if (roomId != null) {
      if (!mounted) return;
      RouterProvider.read(context).push(RoomPath(roomId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          children: [
            Spacer(),
            ElevatedButton(
                onPressed: () => toRoom(context),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('JOIN ROOM'),
                )),
            Spacer(),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(padding: const EdgeInsets.all(8), child: appVersion()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget appVersion() {
    return FutureBuilder(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(
              (snapshot.data as PackageInfo).version,
              style: const TextStyle(color: Colors.blueGrey),
            );
          }
          return SizedBox();
        });
  }
}
