import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../data/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameC = TextEditingController();
  final _bioC = TextEditingController();
  bool _saving = false;
  XFile? _picked;
  String? _currentPhoto;
  bool _loadingInitial = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _bioC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInitial) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: AppColors.purpleAccent),
                  ),
          ),
        ],
      ),
      backgroundColor: AppColors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3B2A58),
                ),
                child: _avatarPreview(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameC,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Display name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioC,
              minLines: 3,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Bio'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.whiteSecondary),
    filled: true,
    fillColor: const Color(0xFF121316),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      String? photoUrl;
      if (_picked != null) {
        final ref = FirebaseStorage.instance.ref('avatars/${user.uid}.jpg');
        await ref.putData(await _picked!.readAsBytes());
        photoUrl = await ref.getDownloadURL();
      }
      final newName = _nameC.text.trim();
      final newBio = _bioC.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': newName,
        'bio': newBio,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (newName.isNotEmpty) 'usernameLower': newName.toLowerCase(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      if (photoUrl != null) {
        _currentPhoto = photoUrl;
        await user.updatePhotoURL(photoUrl);
      }
      if (newName.isNotEmpty) {
        await user.updateDisplayName(newName);
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'handle': newName.isNotEmpty
            ? newName.toLowerCase().replaceAll(' ', '')
            : user.email?.split('@').first,
        'handleLower': (newName.isNotEmpty
                ? newName.toLowerCase().replaceAll(' ', '')
                : user.email?.split('@').first)
            ?.toLowerCase(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) setState(() => _picked = img);
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingInitial = false);
      return;
    }
    final profile = await UserService().fetchProfile(user.uid);
    if (!mounted) return;
    _nameC.text = profile?.username ?? user.displayName ?? '';
    _bioC.text = profile?.bio ?? '';
    _currentPhoto = profile?.photoUrl;
    setState(() => _loadingInitial = false);
  }

  Widget _avatarPreview() {
    if (_picked != null) {
      return ClipOval(
        child: Image.file(File(_picked!.path), fit: BoxFit.cover),
      );
    }
    if (_currentPhoto != null && _currentPhoto!.isNotEmpty) {
      return ClipOval(child: Image.network(_currentPhoto!, fit: BoxFit.cover));
    }
    return const Icon(Icons.camera_alt, color: Colors.white70);
  }
}
