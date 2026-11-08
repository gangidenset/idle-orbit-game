import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_env.dart';
import '../../app/theme.dart';
import '../../game/config/balance_config.dart';
import '../../game/game_controller.dart';
import '../../ui/widgets.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final store = c.purchaseService;
    return Scaffold(
      appBar: AppBar(title: const Text('ショップ')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!AppEnv.isProd)
            const Card(
              color: Color(0xFF3A2A00),
              child: ListTile(
                leading: Icon(Icons.science, color: OrbitColors.accent),
                title: Text('テスト環境'),
                subtitle: Text('ストアのテストアカウント（Playライセンステスター / App Store Sandbox）でのみ購入できます。'),
              ),
            ),
          if (!store.isAvailable)
            const Card(
              child: ListTile(
                leading: Icon(Icons.cloud_off, color: OrbitColors.danger),
                title: Text('ストアに接続できません'),
                subtitle: Text('現在は購入できません。ゲームはこのままお楽しみいただけます。'),
              ),
            ),
          const SizedBox(height: 4),
          for (final p in c.config.shop.products) _ProductCard(product: p),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: store.isAvailable ? c.restorePurchases : null,
            icon: const Icon(Icons.restore),
            label: const Text('購入を復元'),
          ),
          const SizedBox(height: 8),
          const Text(
            '価格はストアに表示される金額（税込）です。購入した非消耗型アイテムは、同じストアアカウントで「購入を復元」できます。',
            style: TextStyle(fontSize: 11, color: OrbitColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final ProductConfig product;

  IconData get _icon => switch (product.id) {
        'remove_ads' => Icons.block,
        'starter_pack' => Icons.inventory_2,
        'boost_24h' => Icons.flash_on,
        'premium_pack' => Icons.workspace_premium,
        _ => Icons.shopping_bag,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final storeProduct = c.purchaseService.products[product.id];
    final owned = c.ownsProduct(product);
    final pending = c.isPurchasePending(product.id);
    // Only real store prices are shown; never a fake "purchasable" state.
    final price = storeProduct?.price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(_icon, size: 36, color: OrbitColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(product.description, style: const TextStyle(fontSize: 12, color: OrbitColors.textDim)),
                if (product.id == 'boost_24h' && c.engine.boostRemaining(c.state, 'iap', c.nowMs) > Duration.zero)
                  Text('有効中：残り ${c.engine.boostRemaining(c.state, 'iap', c.nowMs).inHours}時間',
                      style: const TextStyle(fontSize: 11, color: OrbitColors.success)),
              ]),
            ),
            const SizedBox(width: 8),
            if (owned)
              const Chip(label: Text('購入済み'))
            else if (pending)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              FilledButton(
                onPressed: price == null
                    ? null
                    : () {
                        tapFeedback(context);
                        c.buy(product.id);
                      },
                child: Text(price ?? '準備中'),
              ),
          ]),
        ),
      ),
    );
  }
}
