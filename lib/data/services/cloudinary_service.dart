import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dkcz4v94a';
  static const String _apiKey = '153279666527326';
  static const String _apiSecret = 'GzTXBVob3gEjdC8KcjLVOFaItNA';
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

      print('Uploading to Cloudinary with preset: $_uploadPreset'); // Debug log
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Cloudinary response status: ${response.statusCode}'); // Debug log
      print('Cloudinary response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final secureUrl = responseData['secure_url'] as String;
        print('Upload successful, URL: $secureUrl'); // Debug log
        return secureUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Cloudinary upload error: $e'); // Debug log
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  /// Delete image from Cloudinary (optional - requires signed requests)
  static Future<bool> deleteImage(String publicId) async {
    try {
      // Note: This requires signed requests which need crypto library
      // For now, we'll just return false as unsigned preset doesn't support deletion
      print('Image deletion not supported with unsigned preset');
      return false;
    } catch (e) {
      print('Error deleting image: $e');
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
      print('Error extracting public ID: $e');
      return null;
    }
  }
}
