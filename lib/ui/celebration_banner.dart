import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../app/theme.dart';

class BannerItem {
  const BannerItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.title,
    this.subtitle,
    this.stars = 0,
    this.maxStars = 0,
  });

  final IconData icon;
  final Color color;

  /// Small caption, e.g. "進化！".
  final String label;
  final String title;
  final String? subtitle;
  final int stars;
  final int maxStars;
}

/// Non-blocking banners that slide in from the top, one at a time.
///
/// They never take input focus, so holding an upgrade button keeps going
/// while an evolution is being celebrated.
class CelebrationBanners {
  CelebrationBanners(this._overlay);

  final OverlayState _overlay;
  final Queue<BannerItem> _queue = Queue();
  OverlayEntry? _entry;

  static const _shown = Duration(milliseconds: 1900);

  void show(BannerItem item) {
    // Bursts (e.g. MAX buying past several tiers) are capped so the queue
    // never lags far behind the action.
    if (_queue.length >= 3) _queue.removeFirst();
    _queue.add(item);
    if (_entry == null) _next();
  }

  void _next() {
    if (_queue.isEmpty) {
      _entry = null;
      return;
    }
    final item = _queue.removeFirst();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Banner(
        item: item,
        duration: _shown,
        onDone: () {
          entry.remove();
          _next();
        },
      ),
    );
    _entry = entry;
    _overlay.insert(entry);
  }

  void dispose() {
    _entry?.remove();
    _entry = null;
    _queue.clear();
  }
}

class _Banner extends StatefulWidget {
  const _Banner({required this.item, required this.duration, required this.onDone});
  final BannerItem item;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280))..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 12,
      right: 12,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0));
            return Opacity(
              opacity: _c.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, reduceMotion ? 0 : (1 - t) * -40),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
              decoration: BoxDecoration(
                color: OrbitColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: item.color.withValues(alpha: 0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(color: item.color.withValues(alpha: 0.35), blurRadius: 24),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color.withValues(alpha: 0.18),
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Text(item.label,
                            style: TextStyle(
                                color: item.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1)),
                        if (item.maxStars > 0) ...[
                          const SizedBox(width: 6),
                          for (var i = 0; i < item.maxStars; i++)
                            Icon(i < item.stars ? Icons.star : Icons.star_border,
                                size: 13,
                                color: i < item.stars ? OrbitColors.accent : OrbitColors.textDim),
                        ],
                      ]),
                      Text(item.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (item.subtitle != null)
                        Text(item.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: OrbitColors.textDim)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
