import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class ImageService {
  static const String _imagesKey = 'stored_images';

  // Singleton pattern
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  /// Resmi yükle ve sakla
  Future<String> uploadImage(dynamic imageSource, {String? fileName}) async {
    try {
      String finalFileName =
          fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}';

      // Firebase Storage'a yükle
      try {
        final storageRef = _storage.ref().child('images/$finalFileName');
        UploadTask uploadTask;

        if (imageSource is File) {
          uploadTask = storageRef.putFile(imageSource);
        } else if (imageSource is Uint8List) {
          uploadTask = storageRef.putData(imageSource);
        } else if (imageSource is String) {
          // Base64 string'i Uint8List'e çevir
          String base64String = imageSource;
          if (imageSource.startsWith('data:image')) {
            base64String = imageSource.split(',')[1];
          }
          final bytes = base64Decode(base64String);
          uploadTask = storageRef.putData(bytes);
        } else {
          throw Exception('Desteklenmeyen resim formatı');
        }

        // Metadata ekle
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_by': _auth.currentUser?.uid ?? 'anonymous',
            'upload_time': DateTime.now().toIso8601String(),
          },
        );

        uploadTask = storageRef.putData(
          imageSource is Uint8List
              ? imageSource
              : imageSource is String
              ? base64Decode(
                  imageSource.contains(',')
                      ? imageSource.split(',')[1]
                      : imageSource,
                )
              : await (imageSource as File).readAsBytes(),
          metadata,
        );

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Yerel backup'ı da sakla
        await _storeImageLocally(downloadUrl, finalFileName, 'jpeg');

        return downloadUrl;
      } catch (e) {
        debugPrint('Firebase Storage upload error: $e');
        // Fallback to local storage
        return await _uploadImageLocally(imageSource, finalFileName);
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      throw Exception('Resim yükleme hatası: $e');
    }
  }

  /// Resmi URL'den yükle
  Future<String> uploadImageFromUrl(String url, {String? fileName}) async {
    try {
      // Firebase Storage'a kopyala
      final finalFileName =
          fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}';

      // Bu gerçek uygulamada HTTP request ile resmi indirip Firebase'e yükleyecek
      // Şimdilik URL'yi olduğu gibi döndürüyoruz
      return url;
    } catch (e) {
      debugPrint('Image upload from URL error: $e');
      throw Exception('URL\'den resim yükleme hatası: $e');
    }
  }

  /// Resmi al
  Future<String?> getImage(String imageId) async {
    try {
      if (imageId.startsWith('https://firebasestorage.googleapis.com')) {
        // Firebase Storage URL'si
        return imageId;
      } else if (imageId.startsWith('local://')) {
        // Yerel depolamadan al
        final localId = imageId.substring(8);
        return await _getImageFromLocal(localId);
      } else if (imageId.startsWith('http')) {
        // Harici URL
        return imageId;
      } else {
        // Varsayılan olarak URL olarak kabul et
        return imageId;
      }
    } catch (e) {
      debugPrint('Get image error: $e');
      return null;
    }
  }

  /// Resmi sil
  Future<void> deleteImage(String imageId) async {
    try {
      if (imageId.startsWith('https://firebasestorage.googleapis.com')) {
        // Firebase Storage'dan sil
        try {
          final ref = _storage.refFromURL(imageId);
          await ref.delete();
        } catch (e) {
          debugPrint('Firebase Storage delete error: $e');
        }
      } else if (imageId.startsWith('local://')) {
        final localId = imageId.substring(8);
        await _deleteImageFromLocal(localId);
      }
    } catch (e) {
      debugPrint('Delete image error: $e');
    }
  }

  /// Tüm yerel resimleri temizle
  Future<void> clearAllImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_imagesKey);
    } catch (e) {
      debugPrint('Clear images error: $e');
    }
  }

  /// Birden fazla resim yükle
  Future<List<String>> uploadMultipleImages(List<dynamic> imageSources) async {
    final uploadTasks = imageSources.map(
      (imageSource) => uploadImage(imageSource),
    );
    return await Future.wait(uploadTasks);
  }

  /// Resim boyutunu optimize et
  Future<Uint8List> optimizeImageSize(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int quality = 80,
  }) async {
    try {
      // Bu gerçek uygulamada image processing library kullanılacak
      // Şimdilik resmi olduğu gibi döndürüyoruz
      return imageBytes;
    } catch (e) {
      debugPrint('Image optimization error: $e');
      return imageBytes;
    }
  }

  /// Local storage'a fallback yükleme
  Future<String> _uploadImageLocally(
    dynamic imageSource,
    String fileName,
  ) async {
    try {
      String base64String;

      if (imageSource is File) {
        final bytes = await imageSource.readAsBytes();
        base64String = base64Encode(bytes);
      } else if (imageSource is Uint8List) {
        base64String = base64Encode(imageSource);
      } else if (imageSource is String) {
        if (imageSource.startsWith('data:image')) {
          base64String = imageSource.split(',')[1];
        } else {
          base64String = imageSource;
        }
      } else {
        throw Exception('Desteklenmeyen resim formatı');
      }

      final imageFormat = _detectImageFormat(base64String);
      if (imageFormat == null) {
        throw Exception('Geçersiz resim formatı');
      }

      final optimizedBase64 = await _optimizeImage(base64String);
      final imageId = await _storeImageLocally(
        optimizedBase64,
        fileName,
        imageFormat,
      );

      return 'local://$imageId';
    } catch (e) {
      debugPrint('Local image upload error: $e');
      throw Exception('Yerel resim yükleme hatası: $e');
    }
  }

  /// Yerel depolamada sakla
  Future<String> _storeImageLocally(
    String base64String,
    String fileName,
    String format,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingImagesJson = prefs.getString(_imagesKey) ?? '{}';
      final existingImages = Map<String, dynamic>.from(
        jsonDecode(existingImagesJson),
      );

      final imageId =
          'img_${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}';

      existingImages[imageId] = {
        'data': base64String,
        'fileName': fileName,
        'format': format,
        'timestamp': DateTime.now().toIso8601String(),
        'size': base64String.length,
      };

      await prefs.setString(_imagesKey, jsonEncode(existingImages));
      return imageId;
    } catch (e) {
      debugPrint('Store image locally error: $e');
      throw Exception('Yerel depolamada resim saklanamadı');
    }
  }

  /// Yerel depolamadan al
  Future<String?> _getImageFromLocal(String imageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingImagesJson = prefs.getString(_imagesKey) ?? '{}';
      final existingImages = Map<String, dynamic>.from(
        jsonDecode(existingImagesJson),
      );

      if (existingImages.containsKey(imageId)) {
        final imageData = existingImages[imageId];
        final base64String = imageData['data'] as String;
        final format = imageData['format'] as String;
        return 'data:image/$format;base64,$base64String';
      }
      return null;
    } catch (e) {
      debugPrint('Get image from local error: $e');
      return null;
    }
  }

  /// Yerel depolamadan sil
  Future<void> _deleteImageFromLocal(String imageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingImagesJson = prefs.getString(_imagesKey) ?? '{}';
      final existingImages = Map<String, dynamic>.from(
        jsonDecode(existingImagesJson),
      );

      existingImages.remove(imageId);
      await prefs.setString(_imagesKey, jsonEncode(existingImages));
    } catch (e) {
      debugPrint('Delete image from local error: $e');
    }
  }

  /// Resim formatını tespit et
  String? _detectImageFormat(String base64String) {
    try {
      final bytes = base64Decode(base64String);

      // JPEG magic bytes
      if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'jpeg';
      }

      // PNG magic bytes
      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }

      // GIF magic bytes
      if (bytes.length >= 6 &&
          bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46) {
        return 'gif';
      }

      // WebP magic bytes
      if (bytes.length >= 12 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'webp';
      }

      return null;
    } catch (e) {
      debugPrint('Detect image format error: $e');
      return null;
    }
  }

  /// Resmi optimize et
  Future<String> _optimizeImage(String base64String) async {
    try {
      final bytes = base64Decode(base64String);
      if (bytes.length > 1024 * 1024) {
        debugPrint('Warning: Large image detected (${bytes.length} bytes)');
      }

      // Gerçek uygulamada burada resim sıkıştırma yapılacak
      return base64String;
    } catch (e) {
      debugPrint('Image optimization error: $e');
      return base64String;
    }
  }

  /// Firebase Storage durumunu kontrol et
  Future<bool> isFirebaseStorageAvailable() async {
    try {
      final ref = _storage.ref().child('test');
      await ref.getMetadata();
      return true;
    } catch (e) {
      debugPrint('Firebase Storage availability check failed: $e');
      return false;
    }
  }

  /// Kullanıcıya ait resimleri listele
  Future<List<String>> listUserImages() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final ref = _storage.ref().child('images');
        final listResult = await ref.listAll();

        final imageUrls = await Future.wait(
          listResult.items.map((item) => item.getDownloadURL()),
        );

        return imageUrls;
      }
      return [];
    } catch (e) {
      debugPrint('List user images error: $e');
      return [];
    }
  }
}

/// Resim bilgisi sınıfı
class ImageInfo {
  final String id;
  final String fileName;
  final String format;
  final int size;
  final DateTime timestamp;

  ImageInfo({
    required this.id,
    required this.fileName,
    required this.format,
    required this.size,
    required this.timestamp,
  });

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}';
  }

  @override
  String toString() {
    return 'ImageInfo(id: $id, fileName: $fileName, format: $format, size: $formattedSize)';
  }
}

/// Resim yükleme durumu
enum ImageUploadStatus { idle, uploading, success, error }

/// Resim yükleme sonucu
class ImageUploadResult {
  final ImageUploadStatus status;
  final String? imageId;
  final String? errorMessage;

  ImageUploadResult({required this.status, this.imageId, this.errorMessage});

  factory ImageUploadResult.success(String imageId) {
    return ImageUploadResult(
      status: ImageUploadStatus.success,
      imageId: imageId,
    );
  }

  factory ImageUploadResult.error(String errorMessage) {
    return ImageUploadResult(
      status: ImageUploadStatus.error,
      errorMessage: errorMessage,
    );
  }

  bool get isSuccess => status == ImageUploadStatus.success;
  bool get isError => status == ImageUploadStatus.error;
}
