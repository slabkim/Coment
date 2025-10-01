import 'package:flutter/material.dart';
import '../../core/constants.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Recommendations'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: () => _openSelector(context),
            icon: const Icon(Icons.person_add, color: AppColors.white),
          )
        ],
      ),
      backgroundColor: AppColors.black,
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E232B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Recommended by User $i', style: const TextStyle(color: AppColors.white)),
            subtitle: const Text('Because you both liked "Sample"', style: TextStyle(color: AppColors.whiteSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.whiteSecondary),
            onTap: () {},
          ),
        ),
      ),
    );
  }

  void _openSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _UserSelectorSheet(),
    );
  }
}

class _UserSelectorSheet extends StatelessWidget {
  const _UserSelectorSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Users', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ListView.separated(
                itemCount: 12,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF22252B)),
                itemBuilder: (context, i) => CheckboxListTile(
                  value: false,
                  onChanged: (_) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('User $i', style: const TextStyle(color: AppColors.white)),
                  secondary: const CircleAvatar(child: Icon(Icons.person)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: AppColors.purpleAccent),
                child: const Text('Apply Selection'),
              ),
            )
          ],
        ),
      ),
    );
  }
}


