import 'package:asv_client/app/router/path.dart';
import 'package:flutter/material.dart';

class RootRouterParser extends RouteInformationParser<AppPath> {
  @override
  Future<AppPath> parseRouteInformation(RouteInformation routeInformation) async {
    return AppPath.fromUri(routeInformation.uri);
  }

  @override
  RouteInformation restoreRouteInformation(AppPath configuration) {
    return RouteInformation(uri: configuration.uri);
  }
}

class RootRouterDelegate extends RouterDelegate<AppPath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppPath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  RootRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: paths.map((path) => path.page).toList(),
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        pop();
        return true;
      },
    );
  }

  @override
  Future setNewRoutePath(AppPath configuration) async {
    paths = [configuration];
    notifyListeners();
  }

  Future push(AppPath configuration) async {
    paths.add(configuration);
    notifyListeners();
  }

  Future pop() async {
    paths.removeLast();
    if (paths.isEmpty) paths = [HomePath()];
    notifyListeners();
  }

  @override
  AppPath get currentConfiguration => paths.last;

  List<AppPath> paths = [HomePath()];
}

class RootRouter {
  final delegate = RootRouterDelegate();
  final parser = RootRouterParser();
}
