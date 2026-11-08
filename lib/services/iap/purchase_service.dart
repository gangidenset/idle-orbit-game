/// Price/name info as provided by the store.
class StoreProduct {
  const StoreProduct({
    required this.productId,
    required this.storeId,
    required this.title,
    required this.price,
  });

  /// Our product id (balance.json).
  final String productId;
  final String storeId;
  final String title;

  /// Localised price string from the store, e.g. "¥480".
  final String price;
}

enum PurchaseEventStatus { purchased, restored, pending, cancelled, error }

class PurchaseEvent {
  PurchaseEvent({
    required this.productId,
    required this.status,
    this.transactionId = '',
    this.message,
    this.complete,
  });

  final String productId;
  final PurchaseEventStatus status;
  final String transactionId;
  final String? message;

  /// Must be called after the content has been granted and saved, so the
  /// store does not refund/redeliver it.
  final Future<void> Function()? complete;
}

enum BuyStartResult { started, unavailable, unknownProduct, error }

/// Store abstraction. Grants happen only from [events] with status
/// purchased/restored — never from [buy]'s return value.
abstract class PurchaseService {
  Future<void> initialize();
  bool get isAvailable;

  /// Products the store returned, keyed by our product id.
  Map<String, StoreProduct> get products;
  Stream<PurchaseEvent> get events;
  Future<BuyStartResult> buy(String productId);
  Future<bool> restore();
  void dispose();
}

/// Used when the store is disabled or unreachable. Never reports success.
class UnavailablePurchaseService implements PurchaseService {
  @override
  Future<void> initialize() async {}
  @override
  bool get isAvailable => false;
  @override
  Map<String, StoreProduct> get products => const {};
  @override
  Stream<PurchaseEvent> get events => const Stream.empty();
  @override
  Future<BuyStartResult> buy(String productId) async => BuyStartResult.unavailable;
  @override
  Future<bool> restore() async => false;
  @override
  void dispose() {}
}
