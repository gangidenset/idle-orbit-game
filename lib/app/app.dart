import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/home/home_shell.dart';
import '../game/game_controller.dart';
import '../ui/widgets.dart';
import 'theme.dart';

class IdleOrbitApp extends StatefulWidget {
  const IdleOrbitApp({super.key, required this.controller});
  final GameController controller;

  @override
  State<IdleOrbitApp> createState() => _IdleOrbitAppState();
}

class _IdleOrbitAppState extends State<IdleOrbitApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.controller.onPaused();
      case AppLifecycleState.resumed:
        widget.controller.onResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.controller),
        ChangeNotifierProvider(create: (_) => BuyMode()),
      ],
      child: MaterialApp(
        title: 'IDLE ORBIT',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
