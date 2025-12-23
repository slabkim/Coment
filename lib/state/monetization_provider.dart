import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/ads/ad_config.dart';
import '../core/logger.dart';

/// Handles ad-free entitlement and purchase state.
class MonetizationProvider extends ChangeNotifier {
  MonetizationProvider({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _init();
  }

  final InAppPurchase _inAppPurchase;
  final List<ProductDetails> _products = [];

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _adsRemoved = false;
  bool _isStoreAvailable = false;
  bool _isLoading = true;
  bool _purchasePending = false;
  String? _error;

  static const _prefsKey = 'ads_removed';

  bool get adsRemoved => _adsRemoved;
  bool get adsEnabled => !_adsRemoved;
  bool get isLoading => _isLoading;
  bool get purchasePending => _purchasePending;
  bool get isStoreAvailable => _isStoreAvailable;
  String? get error => _error;
  List<ProductDetails> get products => List.unmodifiable(_products);

  Future<void> _init() async {
    await _loadLocalEntitlement();

    if (kIsWeb) {
      // IAP not available on web
      _isLoading = false;
      notifyListeners();
      return;
    }

    await _connectStore();
  }

  Future<void> _loadLocalEntitlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adsRemoved = prefs.getBool(_prefsKey) ?? false;
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to load ad-free preference', error, stackTrace);
    }
  }

  Future<void> _connectStore() async {
    try {
      _isStoreAvailable = await _inAppPurchase.isAvailable();
      if (_isStoreAvailable) {
        _purchaseSub?.cancel();
        _purchaseSub = _inAppPurchase.purchaseStream.listen(
          _handlePurchaseUpdates,
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.warning('Purchase stream error', error, stackTrace);
            _error = 'Terjadi kesalahan saat memproses pembelian.';
            _purchasePending = false;
            notifyListeners();
          },
        );
        await _queryProducts();
      }
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to connect to IAP store', error, stackTrace);
      _error = 'Toko tidak tersedia. Coba lagi nanti.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _queryProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(
        {AdConfig.removeAdsProductId},
      );
      if (response.error != null) {
        _error = response.error!.message;
      } else {
        _products
          ..clear()
          ..addAll(response.productDetails);
      }
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to query IAP products', error, stackTrace);
      _error = 'Produk tidak tersedia.';
    }
  }

  Future<void> buyRemoveAds() async {
    if (!_isStoreAvailable) {
      _error = 'Toko belum tersedia. Pastikan Play Store/App Store aktif.';
      notifyListeners();
      return;
    }
    final product = _products.where((p) => p.id == AdConfig.removeAdsProductId).firstOrNull;
    if (product == null) {
      _error = 'Produk remove ads belum tersedia.';
      notifyListeners();
      return;
    }
    _purchasePending = true;
    _error = null;
    notifyListeners();
    try {
      final param = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: param);
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to start purchase', error, stackTrace);
      _purchasePending = false;
      _error = 'Pembelian gagal dimulai.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_isStoreAvailable) return;
    _purchasePending = true;
    _error = null;
    notifyListeners();
    try {
      await _inAppPurchase.restorePurchases();
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to restore purchases', error, stackTrace);
      _purchasePending = false;
      _error = 'Gagal restore pembelian.';
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grantAdFree();
          _completePurchaseSafe(purchase);
          _purchasePending = false;
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _error = purchase.error?.message ?? 'Pembelian gagal.';
          break;
        default:
          // Fallback for any future/unknown status
          _purchasePending = false;
          break;
      }
    }
    notifyListeners();
  }

  Future<void> _grantAdFree() async {
    if (_adsRemoved) return;
    _adsRemoved = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to persist ad-free flag', error, stackTrace);
    }
  }

  Future<void> _completePurchaseSafe(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      try {
        await _inAppPurchase.completePurchase(purchase);
      } catch (error, stackTrace) {
        AppLogger.warning('Failed to complete purchase', error, stackTrace);
      }
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
