import 'dart:math' as math;

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../flame/orbit_scene.dart';
import '../../game/config/balance_config.dart';
import '../../game/game_controller.dart';
import 'scene_data.dart';

/// Opens the full-screen base view.
Future<void> openBaseView(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const BaseViewScreen(),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(
            begin: 0.96,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    ),
  );
}

/// Full-screen, zoomable view of the base plus a growth summary.
class BaseViewScreen extends StatefulWidget {
  const BaseViewScreen({super.key});

  @override
  State<BaseViewScreen> createState() => _BaseViewScreenState();
}

class _BaseViewScreenState extends State<BaseViewScreen>
    with SingleTickerProviderStateMixin {
  late final OrbitScene _scene;
  final _zoom = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  Animation<Matrix4>? _tween;
  Size _viewport = Size.zero;

  static const _planetY = 0.6;
  static const _planetR = 0.36;
  static const _sheetCollapsed = 0.22;

  @override
  void initState() {
    super.initState();
    final c = context.read<GameController>();
    // Bigger planet than on the main screen; drawn above the summary sheet.
    _scene = OrbitScene(
      () => buildSceneData(c),
      planetCenterY: _planetY,
      planetRadius: _planetR,
    );
    _anim.addListener(() {
      final t = _tween;
      if (t != null) _zoom.value = t.value;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(
      begin: _zoom.value,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic));
    _anim.forward(from: 0);
  }

  void _showAll() => _animateTo(Matrix4.identity());

  /// Zooms onto the buildings on top of the planet.
  void _closeUp() {
    // Buildings sit on the top edge of the planet.
    final w = _viewport.width, h = _viewport.height;
    final (center, r) = OrbitScene.planetGeometry(
      _viewport,
      centerY: _planetY,
      radius: _planetR,
    );
    // Buildings span about ±0.6 rad on the planet's top edge: fit that row
    // (plus a little room for the outer buildings) into the width, but
    // always zoom in at least 1.5x so it reads as a close-up.
    final focus = Offset(center.dx, center.dy - r - 0.15 * r);
    final halfSpan = r * math.sin(0.6) + 0.25 * r;
    final s = (0.95 * w / (2 * halfSpan)).clamp(1.5, 2.4);
    final m = Matrix4.identity()
      ..translateByDouble(w / 2 - focus.dx * s, h * 0.45 - focus.dy * s, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
    _animateTo(m);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final planet = c.config.planet(c.state.activePlanet);
    return Scaffold(
      backgroundColor: const Color(0xFF050A1A),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: MediaQuery.sizeOf(context).height * _sheetCollapsed - 16,
            child: LayoutBuilder(
              builder: (context, box) {
                _viewport = box.biggest;
                return InteractiveViewer(
                  transformationController: _zoom,
                  minScale: 1,
                  maxScale: 5,
                  child: SizedBox.fromSize(
                    size: box.biggest,
                    child: GameWidget(game: _scene),
                  ),
                );
              },
            ),
          ),
          // Top bar: planet name + close.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planet.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'ピンチで拡大・ドラッグで移動',
                          style: TextStyle(
                            fontSize: 11,
                            color: OrbitColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '閉じる',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
          // Zoom shortcuts, above the summary sheet's collapsed height.
          Positioned(
            right: 12,
            bottom: MediaQuery.sizeOf(context).height * _sheetCollapsed + 12,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.zoom_in,
                  label: '基地をアップ',
                  onTap: _closeUp,
                ),
                const SizedBox(height: 8),
                _ZoomButton(icon: Icons.public, label: '全体', onTap: _showAll),
              ],
            ),
          ),
          const _GrowthSheet(),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: OrbitColors.surface.withValues(alpha: 0.9),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: OrbitColors.outline),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: OrbitColors.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    ),
  );
}

/// Bottom sheet: facility tiers and the decoration collection.
class _GrowthSheet extends StatelessWidget {
  const _GrowthSheet();

  static String _conditionText(DecorationConfig d) {
    final v = d.value.toInt();
    return switch (d.metric) {
      'researchLevels' => '研究レベル合計 $v',
      'robotsHired' => 'ロボットを$v種類雇用',
      'playerLevel' => '司令官 Lv.$v',
      'planetsUnlocked' => '惑星を$vつ開拓',
      'prestigeCount' => '星系ワープ $v回',
      'premium' => 'プレミアムパック',
      _ => '$v',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final v = c.visuals;
    final decos = c.config.visuals.decorations;
    final active = {for (final d in v.activeDecorations(s)) d.id};
    final totalStars = c.config.facilities.fold<int>(
      0,
      (a, f) => a + v.tierFor(s.facilityLevel(f.id)),
    );
    final maxStars = c.config.facilities.length * v.maxTier();

    return DraggableScrollableSheet(
      initialChildSize: _BaseViewScreenState._sheetCollapsed,
      minChildSize: 0.12,
      maxChildSize: 0.75,
      snap: true,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: OrbitColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: OrbitColors.outline)),
        ),
        // Allow mouse/trackpad drags too, so the sheet opens in desktop
        // browsers (Flutter web only drags scrollables by touch by default).
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OrbitColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Summary row: what someone checking progress wants first.
              Row(
                children: [
                  const Text(
                    '基地の成長',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.star, size: 16, color: OrbitColors.accent),
                  Text(
                    ' $totalStars / $maxStars',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: OrbitColors.primary,
                  ),
                  Text(
                    ' ${active.length} / ${decos.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: maxStars == 0 ? 0 : totalStars / maxStars,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                backgroundColor: OrbitColors.outline,
                color: OrbitColors.accent,
              ),
              const SizedBox(height: 14),
              const Text(
                '施設',
                style: TextStyle(fontSize: 13, color: OrbitColors.textDim),
              ),
              for (final f in c.config.facilities)
                _FacilityRow(facility: f, level: s.facilityLevel(f.id)),
              const SizedBox(height: 14),
              const Text(
                '装飾コレクション',
                style: TextStyle(fontSize: 13, color: OrbitColors.textDim),
              ),
              const SizedBox(height: 6),
              for (final d in decos)
                _DecorationRow(
                  decoration: d,
                  unlocked: active.contains(d.id),
                  condition: _conditionText(d),
                  progress: (v.metric(s, d.metric) / d.value).clamp(0.0, 1.0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityRow extends StatelessWidget {
  const _FacilityRow({required this.facility, required this.level});
  final FacilityConfig facility;
  final int level;

  @override
  Widget build(BuildContext context) {
    final c = context.read<GameController>();
    final v = c.visuals;
    final tier = v.tierFor(level);
    final next = v.nextTierLevel(level);
    final color = level > 0
        ? OrbitColors.facility(facility.icon)
        : OrbitColors.textDim;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(OrbitIcons.facility(facility.icon), color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level > 0
                      ? v.tierName(facility, level)
                      : '${facility.name}（未建設）',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  level == 0
                      ? facility.name
                      : next == null
                      ? 'Lv.$level・最終段階'
                      : 'Lv.$level・あと${next - level}で進化',
                  style: const TextStyle(
                    fontSize: 11,
                    color: OrbitColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < v.maxTier(); i++)
            Icon(
              Icons.star,
              size: 13,
              color: i < tier ? color : OrbitColors.outline,
            ),
        ],
      ),
    );
  }
}

class _DecorationRow extends StatelessWidget {
  const _DecorationRow({
    required this.decoration,
    required this.unlocked,
    required this.condition,
    required this.progress,
  });
  final DecorationConfig decoration;
  final bool unlocked;
  final String condition;
  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(
          unlocked ? Icons.check_circle : Icons.lock_outline,
          size: 20,
          color: unlocked ? OrbitColors.success : OrbitColors.textDim,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unlocked ? decoration.name : '？？？',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: unlocked ? null : OrbitColors.textDim,
                ),
              ),
              Text(
                unlocked ? decoration.description : '解放条件：$condition',
                style: const TextStyle(
                  fontSize: 11,
                  color: OrbitColors.textDim,
                ),
              ),
              if (!unlocked) ...[
                const SizedBox(height: 3),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                  backgroundColor: OrbitColors.outline,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
