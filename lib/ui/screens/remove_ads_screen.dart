import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../state/monetization_provider.dart';

class RemoveAdsScreen extends StatelessWidget {
  const RemoveAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hilangkan Iklan'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Consumer<MonetizationProvider>(
        builder: (context, monetization, _) {
          final isUnlocked = monetization.adsRemoved;
          final isLoading = monetization.isLoading || monetization.purchasePending;
          final error = monetization.error;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isUnlocked ? Icons.celebration : Icons.workspace_premium_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUnlocked ? 'Ad-free aktif' : 'Upgrade ke pengalaman bebas iklan',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isUnlocked
                                ? 'Terima kasih sudah mendukung. Iklan tidak akan ditampilkan lagi.'
                                : 'Dukung pengembangan aplikasi dengan menghilangkan semua banner iklan Google.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Yang kamu dapatkan:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _benefit(context, 'Tanpa banner iklan di beranda & layar utama'),
              _benefit(context, 'Lebih ringan dan fokus ke konten'),
              _benefit(context, 'Dukungan langsung untuk biaya server & fitur baru'),
              const SizedBox(height: 20),
              if (error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (error != null) const SizedBox(height: 12),
              if (AdConfig.usingTestIds)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Saat ini memakai Test ID AdMob. Ganti dengan ID produksi di .env sebelum rilis.',
                  ),
                ),
              if (AdConfig.usingTestIds) const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: isUnlocked
                    ? const Icon(Icons.check_circle_outline)
                    : const Icon(Icons.lock_open),
                label: Text(isUnlocked ? 'Iklan sudah dimatikan' : 'Bayar & matikan iklan'),
                onPressed: (isUnlocked || isLoading)
                    ? null
                    : () => monetization.buyRemoveAds(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isLoading ? null : () => monetization.restorePurchases(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: Text(isUnlocked ? 'Pulihkan pembelian' : 'Pulihkan jika sudah membeli'),
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _benefit(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
