import 'package:flutter/material.dart';
import '../../core/constants.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      body: const Center(
        child: Text('Search Screen', style: TextStyle(color: AppColors.white)),
      ),
    );
  }
}
