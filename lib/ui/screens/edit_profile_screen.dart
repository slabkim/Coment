import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

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

  @override
  void dispose() {
    _nameC.dispose();
    _bioC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                : const Text('Save', style: TextStyle(color: AppColors.purpleAccent)),
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
                child: _picked == null
                    ? const Icon(Icons.camera_alt, color: Colors.white70)
                    : ClipOval(child: Image.file(
                        // ignore: deprecated_member_use
                        File(_picked!.path),
                        fit: BoxFit.cover,
                      )),
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
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': _nameC.text.trim(),
        'bio': _bioC.text.trim(),
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _picked = img);
  }
}


