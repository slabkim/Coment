import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/ad_config.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/logger.dart';
import '../../../state/monetization_provider.dart';

/// Reusable banner ad slot that hides itself when the user has paid
/// for an ad-free experience.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.backgroundColor,
  });

  final EdgeInsets margin;
  final Color? backgroundColor;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _maybeLoadAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleAdToggle();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _handleAdToggle() {
    final monetization = context.read<MonetizationProvider>();
    if (!monetization.adsEnabled) {
      if (_bannerAd != null) {
        _bannerAd?.dispose();
        _bannerAd = null;
        _isLoaded = false;
      }
    } else {
      _maybeLoadAd();
    }
  }

  Future<void> _maybeLoadAd() async {
    final monetization = context.read<MonetizationProvider>();
    if (!monetization.adsEnabled || _bannerAd != null || _isLoading) return;
    _isLoading = true;
    try {
      await AdService.initialize();
      final ad = BannerAd(
        adUnitId: AdConfig.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
            AppLogger.warning(
              'Banner ad failed to load',
              '${error.code} ${error.message}',
              StackTrace.current,
            );
          },
        ),
      );
      await ad.load();
      if (!mounted) {
        ad.dispose();
        return;
      }
      setState(() {
        _bannerAd = ad;
      });
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsEnabled = context.watch<MonetizationProvider>().adsEnabled;
    if (!adsEnabled) return const SizedBox.shrink();

    final height = AdSize.banner.height.toDouble();
    Widget child;
    if (_bannerAd != null && _isLoaded) {
      child = SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: height,
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      child = Container(
        width: double.infinity,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AdConfig.usingTestIds ? 'Ad (test)' : 'Loading sponsored content...',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
    }

    return Padding(
      padding: widget.margin,
      child: child,
    );
  }
}
