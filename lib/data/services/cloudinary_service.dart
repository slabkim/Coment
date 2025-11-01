import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/logger.dart';

class CloudinaryService {
  static const String _cloudName = 'dkcz4v94a';
  // Note: _apiKey and _apiSecret are reserved for future signed uploads
  // Currently using unsigned preset, so these are not used
  static const String _uploadPreset = 'android_unsigned';
  
  static const String _baseUrl = 'https://api.cloudinary.com/v1_1/$_cloudName';

  /// Upload image to Cloudinary and return the public URL
  static Future<String> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/image/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      
      // Add image file
      final imageBytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final secureUrl = responseData['secure_url'] as String;
        return secureUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Cloudinary upload error', e, stackTrace);
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  /// Delete image from Cloudinary (optional - requires signed requests)
  static Future<bool> deleteImage(String publicId) async {
    try {
      // Note: This requires signed requests which need crypto library
      // For now, we'll just return false as unsigned preset doesn't support deletion
      AppLogger.info('Image deletion not supported with unsigned preset');
      return false;
    } catch (e) {
      AppLogger.warning('Error deleting image', e);
      return false;
    }
  }

  /// Extract public ID from Cloudinary URL
  static String? extractPublicId(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3 && pathSegments[0] == 'v1_1' && pathSegments[1] == _cloudName) {
        // Extract public ID from path like: /v1_1/cloudname/image/upload/v1234567890/filename
        final uploadIndex = pathSegments.indexOf('upload');
        if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
          return pathSegments[uploadIndex + 2].split('.')[0]; // Remove file extension
        }
      }
      return null;
    } catch (e) {
      AppLogger.warning('Error extracting public ID', e);
      return null;
    }
  }
}
