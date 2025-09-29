import 'package:flutter/material.dart';
import '../../core/constants.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      body: const Center(
        child: Text('Library Screen', style: TextStyle(color: AppColors.white)),
      ),
    );
  }
}
