import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/logger.dart';
import '../../game/config/balance_config.dart';
import 'purchase_service.dart';

/// Google Play Billing / Apple StoreKit via the `in_app_purchase` plugin.
///
/// Test vs production is handled by the stores themselves: debug/internal
/// builds purchase with license-tester (Play) or Sandbox (App Store)
/// accounts. No purchase is ever simulated in code.
///
/// NOTE: receipts are not verified server-side in the MVP. Before scaling
/// paid UA, add server verification (see docs/DESIGN.md §7).
class StorePurchaseService implements PurchaseService {
  StorePurchaseService(this.shop, this.platform, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final ShopConfig shop;
  final String platform;
  final InAppPurchase _iap;

  bool _available = false;
  final Map<String, StoreProduct> _products = {};
  final Map<String, ProductDetails> _details = {};
  final _events = StreamController<PurchaseEvent>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;

  String? _productIdForStoreId(String storeId) {
    for (final p in shop.products) {
      if (p.storeIds[platform] == storeId) return p.id;
    }
    return null;
  }

  @override
  Future<void> initialize() async {
    try {
      _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e, StackTrace st) {
        log.error('Purchase stream error', e, st);
      });
      _available = await _iap.isAvailable();
      if (!_available) return;
      final ids = shop.products
          .map((p) => p.storeIds[platform])
          .whereType<String>()
          .toSet();
      final resp = await _iap.queryProductDetails(ids);
      if (resp.error != null) {
        log.warn('Product query error: ${resp.error!.message}');
      }
      if (resp.notFoundIDs.isNotEmpty) {
        log.warn('Products not found in store: ${resp.notFoundIDs}');
      }
      for (final d in resp.productDetails) {
        final pid = _productIdForStoreId(d.id);
        if (pid == null) continue;
        _details[pid] = d;
        _products[pid] =
            StoreProduct(productId: pid, storeId: d.id, title: d.title, price: d.price);
      }
    } catch (e, st) {
      log.error('Store init failed', e, st);
      _available = false;
    }
  }

  void _onPurchases(List<PurchaseDetails> list) {
    for (final p in list) {
      final pid = _productIdForStoreId(p.productID);
      if (pid == null) {
        log.warn('Purchase for unknown store id ${p.productID}');
        continue;
      }
      Future<void> complete() async {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      }

      switch (p.status) {
        case PurchaseStatus.pending:
          _events.add(PurchaseEvent(productId: pid, status: PurchaseEventStatus.pending));
        case PurchaseStatus.purchased:
          _events.add(PurchaseEvent(
            productId: pid,
            status: PurchaseEventStatus.purchased,
            transactionId: p.purchaseID ?? '',
            complete: complete,
          ));
        case PurchaseStatus.restored:
          _events.add(PurchaseEvent(
            productId: pid,
            status: PurchaseEventStatus.restored,
            transactionId: p.purchaseID ?? '',
            complete: complete,
          ));
        case PurchaseStatus.canceled:
          _events.add(PurchaseEvent(
              productId: pid, status: PurchaseEventStatus.cancelled, complete: complete));
        case PurchaseStatus.error:
          _events.add(PurchaseEvent(
            productId: pid,
            status: PurchaseEventStatus.error,
            message: p.error?.message,
            complete: complete,
          ));
      }
    }
  }

  @override
  bool get isAvailable => _available;

  @override
  Map<String, StoreProduct> get products => Map.unmodifiable(_products);

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  @override
  Future<BuyStartResult> buy(String productId) async {
    if (!_available) return BuyStartResult.unavailable;
    final d = _details[productId];
    final cfg = shop.byId(productId);
    if (d == null || cfg == null) return BuyStartResult.unknownProduct;
    try {
      final param = PurchaseParam(productDetails: d);
      final ok = cfg.kind == ProductKind.consumable
          ? await _iap.buyConsumable(purchaseParam: param)
          : await _iap.buyNonConsumable(purchaseParam: param);
      return ok ? BuyStartResult.started : BuyStartResult.error;
    } catch (e, st) {
      log.error('buy($productId) failed', e, st);
      return BuyStartResult.error;
    }
  }

  @override
  Future<bool> restore() async {
    if (!_available) return false;
    try {
      await _iap.restorePurchases();
      return true;
    } catch (e, st) {
      log.error('restorePurchases failed', e, st);
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _events.close();
  }
}
