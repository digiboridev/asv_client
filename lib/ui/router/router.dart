import 'package:asv_client/ui/router/path.dart';
import 'package:flutter/material.dart';

class AppRouteParser extends RouteInformationParser<AppPath> {
  @override
  Future<AppPath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location!);
    return AppPath.fromUri(uri);
  }

  @override
  RouteInformation restoreRouteInformation(AppPath configuration) {
    String location = '/${configuration.uri}';
    return RouteInformation(location: location);
  }
}

class AppRouteDelegate extends RouterDelegate<AppPath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppPath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  AppRouteDelegate() : navigatorKey = GlobalKey<NavigatorState>();

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
  final delegate = AppRouteDelegate();
  final parser = AppRouteParser();
}
