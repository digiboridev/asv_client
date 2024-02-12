// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:asv_client/app/providers/root_router_provider.dart';
import 'package:asv_client/app/router/router.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const TheApp());
}

class TheApp extends StatefulWidget {
  const TheApp({super.key});

  @override
  State<TheApp> createState() => _TheAppState();
}

class _TheAppState extends State<TheApp> {
  late final RootRouter rootRouter;

  @override
  void initState() {
    rootRouter = RootRouter();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ASV Chat',
      theme: ThemeData(primarySwatch: Colors.pink),
      backButtonDispatcher: RootBackButtonDispatcher(),
      routeInformationParser: rootRouter.parser,
      routerDelegate: rootRouter.delegate,
      builder: (context, child) {
        return RouterProvider(router: rootRouter.delegate, child: child!);
      },
    );
  }
}


// TODO selectable text in chat