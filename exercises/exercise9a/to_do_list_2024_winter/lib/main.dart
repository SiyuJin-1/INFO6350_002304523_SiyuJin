import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'backend/firebase/firebase_config.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';
import 'flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  await initFirebase();
  debugPrint('Firebase projectId = ${Firebase.app().options.projectId}');

  await FlutterFlowTheme.initialize();

  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(const MyApp());
}
 class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late final AppStateNotifier _appStateNotifier;
  late final GoRouter _router;

  late final Stream<BaseAuthUser> _userStream;
  StreamSubscription<BaseAuthUser>? _authUserSub;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    _userStream = toDoList2024WinterFirebaseUserStream();
    _authUserSub = _userStream.listen((user) {
      _appStateNotifier.update(user);
    });

    jwtTokenStream.listen((_) {});

    Future.delayed(
      const Duration(milliseconds: 1000),
          () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    _authUserSub?.cancel();
    super.dispose();
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
      FlutterFlowTheme.saveThemeMode(mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ToDoList-2024-Winter',
      routerConfig: _router,
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],

      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
    );
  }
}
