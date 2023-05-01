// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:asv_client/app/router/provider.dart';
import 'package:asv_client/app/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const TheApp());
}

class TheApp extends StatefulWidget {
  const TheApp({super.key});

  @override
  State<TheApp> createState() => _TheAppState();
}

class _TheAppState extends State<TheApp> {
  late final AppRouteParser appRouteParser;
  late final AppRouteDelegate appRouteDelegate;

  @override
  void initState() {
    appRouteParser = AppRouteParser();
    appRouteDelegate = AppRouteDelegate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ASV Client',
      theme: ThemeData(primarySwatch: Colors.pink),
      backButtonDispatcher: RootBackButtonDispatcher(),
      routeInformationParser: appRouteParser,
      routerDelegate: appRouteDelegate,
      builder: (context, child) {
        return RouterProvider(router: appRouteDelegate, child: child!);
      },
    );
  }
}
