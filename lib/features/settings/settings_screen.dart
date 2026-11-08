import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_env.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../data/save_migrator.dart';
import '../../game/game_controller.dart';
import '../../game/model/game_state.dart';
import '../../ui/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final noAds = c.engine.noAds(s);
    final freq = c.config.interstitial.frequencies;
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _Header('広告'),
          ListTile(
            title: const Text('広告の表示頻度'),
            subtitle: Text(noAds
                ? '広告削除を購入済みのため、強制広告は表示されません'
                : '画面の切り替わりなど区切りの良いタイミングでのみ表示されます'),
          ),
          if (!noAds)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: [
                  if (freq.containsKey('low'))
                    ButtonSegment(value: 'low', label: Text('少なめ（${fmtDuration(Duration(seconds: freq['low']!))}毎）')),
                  if (freq.containsKey('standard'))
                    ButtonSegment(
                        value: 'standard',
                        label: Text('標準（${fmtDuration(Duration(seconds: freq['standard']!))}毎）')),
                ],
                selected: {s.settings.adFrequency},
                onSelectionChanged: (v) => c.setAdFrequency(v.first),
              ),
            ),
          const _Header('操作'),
          SwitchListTile(
            title: const Text('振動（ハプティクス）'),
            subtitle: const Text('ボタンを押したときに軽く振動します'),
            value: s.settings.haptics,
            onChanged: c.setHaptics,
          ),
          const _Header('プライバシー'),
          SwitchListTile(
            title: const Text('匿名の利用状況データを送信'),
            subtitle: const Text('ゲーム改善のため、個人を特定しない操作ログのみを利用します'),
            value: s.settings.analyticsConsent,
            onChanged: c.setAnalyticsConsent,
          ),
          const _Header('購入'),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('購入を復元'),
            enabled: c.purchaseService.isAvailable,
            subtitle: c.purchaseService.isAvailable ? null : const Text('ストアに接続できません'),
            onTap: c.restorePurchases,
          ),
          const _Header('データ'),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('今すぐ保存'),
            subtitle: const Text('進行状況は自動でも保存されます'),
            onTap: () async {
              await c.saveNow();
              if (context.mounted) showMessage(context, '保存しました');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: OrbitColors.danger),
            title: const Text('データを初期化', style: TextStyle(color: OrbitColors.danger)),
            subtitle: const Text('購入済みの商品は失われません'),
            onTap: () => _confirmReset(context, c),
          ),
          const _Header('統計'),
          ListTile(
            dense: true,
            title: Text('累計プレイ時間 ${fmtDuration(Duration(seconds: s.stat(Metric.playSeconds).round()))}'
                '・セッション ${s.stat(Metric.sessions).toInt()}回'),
            subtitle: Text('累計鉱石 ${fmt(s.stat(Metric.lifetimeOre))}・施設強化 ${s.stat(Metric.facilityUpgrades).toInt()}回'
                '・ワープ ${s.stat(Metric.prestigeCount).toInt()}回'),
          ),
          ListTile(
            dense: true,
            title: const Text('バージョン情報'),
            subtitle: Text('環境: ${AppEnv.name} / バランス設定 v${c.config.configVersion} / セーブ形式 v$currentSaveVersion'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, GameController c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('データを初期化しますか？'),
        content: const Text('資源・施設・ロボット・転生・実績などすべての進行状況が削除されます。\nこの操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OrbitColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('初期化する'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await c.resetAllData();
      if (context.mounted) showMessage(context, 'データを初期化しました');
    }
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(text,
            style: const TextStyle(color: OrbitColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
      );
}
