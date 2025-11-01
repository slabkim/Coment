import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/logger.dart';
import '../../data/services/user_service.dart';
import '../../data/services/cloudinary_service.dart';

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
  XFile? _pickedCover;
  String? _currentPhoto;
  String? _currentCoverPhoto;
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
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          TextButton(
            onPressed: _saving ? null : () {
              AppLogger.debug('Save button pressed');
              _save();
            },
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Photo
            GestureDetector(
              onTap: _pickCoverImage,
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: _coverPhotoPreview(),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Profile Photo (overlapping cover)
            Transform.translate(
              offset: const Offset(0, -40),
              child: Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 4,
                          ),
                        ),
                        child: _avatarPreview(),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Form fields
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameC,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: _decoration('Display name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioC,
                    minLines: 3,
                    maxLines: 5,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: _decoration('Bio'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final newName = _nameC.text.trim();
      final newBio = _bioC.text.trim();

      // Validate input
      if (newName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Display name cannot be empty'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      String? photoUrl;
      String? coverPhotoUrl;
      
      // Upload profile photo
      if (_picked != null) {
        try {
          photoUrl = await CloudinaryService.uploadImage(File(_picked!.path));
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading photo: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      // Upload cover photo
      if (_pickedCover != null) {
        try {
          coverPhotoUrl = await CloudinaryService.uploadImage(File(_pickedCover!.path));
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading cover photo: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Update Firestore document
      try {
        final updates = {
          'username': newName,
          'bio': newBio,
          if (photoUrl != null) 'photoUrl': photoUrl,
          if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
          'usernameLower': newName.toLowerCase(),
          'handle': newName.toLowerCase().replaceAll(' ', ''),
          'handleLower': newName.toLowerCase().replaceAll(' ', ''),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          updates,
          SetOptions(merge: true)
        );

        // Update Firebase Auth profile
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.updateDisplayName(newName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _pickCoverImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) setState(() => _pickedCover = img);
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
    _currentCoverPhoto = profile?.coverPhotoUrl;
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

  Widget _coverPhotoPreview() {
    if (_pickedCover != null) {
      return Image.file(
        File(_pickedCover!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (_currentCoverPhoto != null && _currentCoverPhoto!.isNotEmpty) {
      return Image.network(
        _currentCoverPhoto!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Center(
      child: Icon(
        Icons.add_photo_alternate,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 48,
      ),
    );
  }

}
