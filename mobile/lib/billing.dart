import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'api.dart';
import 'store.dart';

/// Subscription product ids — must match the ones you create in Play Console
/// (and the backend's PLAY_PRODUCT_* env vars).
const String kProductResearch = 'qmol_research_monthly';
const String kProductCommercial = 'qmol_commercial_monthly';
const Set<String> kProductIds = {kProductResearch, kProductCommercial};

/// Wraps Google Play Billing (via in_app_purchase) and the server-side
/// purchase verification that provisions the API key.
class Billing {
  Billing(this.api);
  final QmolApi api;

  /// In-app purchase is only supported on the mobile plaforms in_app_purchase
  /// ships (Android here). On Flutter web there is no plugin, and touching
  /// `InAppPurchase.instance` throws — so we never access it unless [supported].
  bool get supported => !kIsWeb;

  InAppPurchase? _iapCached;
  InAppPurchase get _iap => _iapCached ??= InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// True only where Play Billing can actually run. Returns false (never throws)
  /// on web or any device without a billing backend, so callers can show a
  /// graceful "use the website" fallback instead of crashing.
  Future<bool> available() async {
    if (!supported) return false;
    try {
      return await _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<List<ProductDetails>> products() async {
    if (!supported) return const [];
    try {
      final resp = await _iap.queryProductDetails(kProductIds);
      return resp.productDetails;
    } catch (_) {
      return const [];
    }
  }

  /// Begin listening for purchase updates. On a completed purchase the token is
  /// sent to the backend (`/billing/play/verify`), which returns an API key.
  void start({
    required void Function(String apiKey) onKey,
    required void Function(String error) onError,
  }) {
    if (!supported) return;
    _sub ??= _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        switch (p.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            try {
              final key = await api.playVerify(p.productID, _purchaseToken(p));
              await Store.setKey(key);
              onKey(key);
            } catch (e) {
              onError(e.toString());
            } finally {
              if (p.pendingCompletePurchase) await _iap.completePurchase(p);
            }
          case PurchaseStatus.error:
            onError(p.error?.message ?? 'purchase error');
          case PurchaseStatus.canceled:
          case PurchaseStatus.pending:
            break;
        }
      }
    });
  }

  Future<void> buy(ProductDetails product) async {
    if (!supported) return;
    await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product));
  }

  /// The purchase token the Play Developer API verifies against. NOTE: confirm
  /// this against your installed in_app_purchase_android version before release.
  String _purchaseToken(PurchaseDetails p) {
    if (p is GooglePlayPurchaseDetails) {
      return p.billingClientPurchase.purchaseToken;
    }
    return p.verificationData.serverVerificationData;
  }

  void dispose() => _sub?.cancel();
}
