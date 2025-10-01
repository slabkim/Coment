import 'package:flutter/material.dart';
import '../../core/constants.dart';

class ReadingListScreen extends StatelessWidget {
  const ReadingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Plan to Read', 'Reading', 'Completed', 'Dropped', 'On Hold'];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reading List'),
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.purpleAccent,
            labelColor: AppColors.purpleAccent,
            unselectedLabelColor: AppColors.whiteSecondary,
            tabs: tabs.map((e) => Tab(text: e)).toList(),
          ),
        ),
        backgroundColor: AppColors.black,
        body: TabBarView(
          children: tabs.map((e) => _StatusList(title: e)).toList(),
        ),
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  final String title;
  const _StatusList({required this.title});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 12,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E232B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2E35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book, color: Colors.white70),
            ),
            title: Text(
              '$title Manga #$i',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Chapter 12 of 100',
              style: TextStyle(color: AppColors.whiteSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.whiteSecondary,
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}
