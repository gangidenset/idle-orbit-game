import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/game_controller.dart';
import '../../game/model/resources.dart';
import '../../ui/widgets.dart';
import '../base/base_screen.dart';
import '../facilities/facilities_screen.dart';
import '../missions/missions_screen.dart';
import '../offline/offline_reward_dialog.dart';
import '../planets/planet_unlocked_dialog.dart';
import '../planets/planets_screen.dart';
import '../prestige/prestige_screen.dart';
import '../research/research_screen.dart';
import '../robots/robots_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  StreamSubscription<GameEvent>? _sub;
  bool _offlineDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<GameController>();
    _sub = c.events.listen(_onEvent);
    // Show a reward computed before the UI subscribed (cold start).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (c.state.pendingOfflineReward != null) _showOffline();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(GameEvent e) {
    if (!mounted) return;
    switch (e) {
      case MessageEvent(:final text, :final isError):
        showMessage(context, text, error: isError);
      case OfflineRewardEvent():
        _showOffline();
      case PlanetUnlockedEvent(:final planet):
        showPlanetUnlocked(context, planet).then((_) {
          if (mounted) context.read<GameController>().maybeShowInterstitial('planet_unlock');
        });
      case PurchaseGrantedEvent(:final product, :final restored):
        showMessage(context, restored ? '「${product.name}」を復元しました' : '「${product.name}」を購入しました。ありがとうございます！');
    }
  }

  Future<void> _showOffline() async {
    if (_offlineDialogOpen) return;
    _offlineDialogOpen = true;
    await showOfflineRewardDialog(context);
    _offlineDialogOpen = false;
  }

  Future<void> _push(Widget screen, {bool interstitialOnClose = false}) async {
    final c = context.read<GameController>();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (interstitialOnClose) await c.maybeShowInterstitial('screen_close');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final missionBadge = c.progression.claimableMissionCount(s) +
        c.progression.claimableAchievementCount(s) +
        (c.progression.canClaimLogin(s) ? 1 : 0);
    final next = c.engine.nextLockedPlanet(s);
    final planetReady = next != null && c.engine.canUnlockPlanet(s, next.id);

    final pages = [
      BaseScreen(onOpenPlanets: () => _push(const PlanetsScreen(), interstitialOnClose: true)),
      const FacilitiesScreen(),
      const RobotsScreen(),
      const ResearchScreen(),
      const MissionsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const _ResourceBar(),
        toolbarHeight: 64,
        actions: [
          PopupMenuButton<String>(
            icon: CountBadge(count: planetReady ? 1 : 0, child: const Icon(Icons.menu)),
            tooltip: 'メニュー',
            onSelected: (v) => switch (v) {
              'planets' => _push(const PlanetsScreen(), interstitialOnClose: true),
              'prestige' => _push(const PrestigeScreen(), interstitialOnClose: true),
              'shop' => _push(const ShopScreen()),
              'settings' => _push(const SettingsScreen()),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'planets',
                child: ListTile(
                  leading: CountBadge(count: planetReady ? 1 : 0, child: const Icon(Icons.public)),
                  title: const Text('惑星'),
                ),
              ),
              const PopupMenuItem(
                  value: 'prestige',
                  child: ListTile(leading: Icon(Icons.rocket_launch), title: Text('転生（星系ワープ）'))),
              const PopupMenuItem(
                  value: 'shop', child: ListTile(leading: Icon(Icons.storefront), title: Text('ショップ'))),
              const PopupMenuItem(
                  value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('設定'))),
            ],
          ),
        ],
      ),
      body: SafeArea(top: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.public), label: '基地'),
          const NavigationDestination(icon: Icon(Icons.factory), label: '施設'),
          const NavigationDestination(icon: Icon(Icons.smart_toy), label: 'ロボット'),
          NavigationDestination(
            icon: Icon(c.engine.isResearchAvailable(s) ? Icons.science : Icons.lock_outline),
            label: '研究',
          ),
          NavigationDestination(
              icon: CountBadge(count: missionBadge, child: const Icon(Icons.flag)), label: 'ミッション'),
        ],
      ),
    );
  }
}

/// Always-visible resource strip with amounts, rates and storage fill.
class _ResourceBar extends StatelessWidget {
  const _ResourceBar();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    return Row(children: [
      for (final r in ResourceType.values)
        Expanded(
          child: _ResourceCell(
            type: r,
            amount: s.resources[r],
            rate: c.snap.net[r],
            cap: c.engine.storageCap(s, r, c.mods),
          ),
        ),
    ]);
  }
}

class _ResourceCell extends StatelessWidget {
  const _ResourceCell({required this.type, required this.amount, required this.rate, required this.cap});
  final ResourceType type;
  final double amount;
  final double rate;
  final double cap;

  @override
  Widget build(BuildContext context) {
    final fill = cap.isFinite ? (amount / cap).clamp(0.0, 1.0) : 0.0;
    final full = cap.isFinite && amount >= cap * 0.999;
    return Tooltip(
      message: '${type.label}${cap.isFinite ? '（上限 ${fmt(cap)}）' : ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(OrbitIcons.resource(type), size: 16, color: OrbitColors.resource(type)),
              const SizedBox(width: 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(fmt(amount),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: full ? OrbitColors.danger : null)),
                ),
              ),
            ]),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(full ? '保管上限' : fmtRate(rate),
                  style: TextStyle(
                      fontSize: 10,
                      color: full
                          ? OrbitColors.danger
                          : (rate < 0 ? OrbitColors.danger : OrbitColors.textDim))),
            ),
            if (cap.isFinite)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: LinearProgressIndicator(
                  value: fill,
                  minHeight: 2,
                  backgroundColor: OrbitColors.outline,
                  color: full ? OrbitColors.danger : OrbitColors.resource(type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
