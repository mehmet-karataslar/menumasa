import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // =============================================================================
  // PRODUCT IMAGE OPERATIONS
  // =============================================================================

  /// Uploads a product image to Firebase Storage
  Future<String> uploadProductImage({
    required String businessId,
    required String productId,
    required dynamic imageFile, // File for mobile, Uint8List for web
    required String fileName,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('businesses')
          .child(businessId)
          .child('products')
          .child(productId)
          .child(fileName);

      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Web platform - use putData with Uint8List
        uploadTask = ref.putData(imageFile as Uint8List);
      } else {
        // Mobile platform - use putFile with File
        uploadTask = ref.putFile(imageFile as File);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Ürün resmi yüklenirken hata oluştu: $e');
    }
  }

  /// Deletes a product image from Firebase Storage
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting product image: $e');
      // Don't throw error for image deletion failures
    }
  }

  /// Uploads multiple product images
  Future<List<String>> uploadMultipleProductImages({
    required String businessId,
    required String productId,
    required List<dynamic> imageFiles,
  }) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      try {
        final url = await uploadProductImage(
          businessId: businessId,
          productId: productId,
          imageFile: imageFiles[i],
          fileName: fileName,
        );
        uploadedUrls.add(url);
      } catch (e) {
        print('Error uploading image $i: $e');
        // Continue with other images even if one fails
      }
    }
    
    return uploadedUrls;
  }

  // =============================================================================
  // BUSINESS IMAGE OPERATIONS
  // =============================================================================

  /// Uploads a business logo to Firebase Storage
  Future<String> uploadBusinessLogo({
    required String businessId,
    required dynamic imageFile,
    required String fileName,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('businesses')
          .child(businessId)
          .child('logo')
          .child(fileName);

      UploadTask uploadTask;
      
      if (kIsWeb) {
        uploadTask = ref.putData(imageFile as Uint8List);
      } else {
        uploadTask = ref.putFile(imageFile as File);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('İşletme logosu yüklenirken hata oluştu: $e');
    }
  }

  /// Uploads business gallery images
  Future<List<String>> uploadBusinessGallery({
    required String businessId,
    required List<dynamic> imageFiles,
  }) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      try {
        final ref = _storage
            .ref()
            .child('businesses')
            .child(businessId)
            .child('gallery')
            .child(fileName);

        UploadTask uploadTask;
        
        if (kIsWeb) {
          uploadTask = ref.putData(imageFiles[i] as Uint8List);
        } else {
          uploadTask = ref.putFile(imageFiles[i] as File);
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading gallery image $i: $e');
      }
    }
    
    return uploadedUrls;
  }

  // =============================================================================
  // CATEGORY IMAGE OPERATIONS
  // =============================================================================

  /// Uploads a category image to Firebase Storage
  Future<String> uploadCategoryImage({
    required String businessId,
    required String categoryId,
    required dynamic imageFile,
    required String fileName,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('businesses')
          .child(businessId)
          .child('categories')
          .child(categoryId)
          .child(fileName);

      UploadTask uploadTask;
      
      if (kIsWeb) {
        uploadTask = ref.putData(imageFile as Uint8List);
      } else {
        uploadTask = ref.putFile(imageFile as File);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Kategori resmi yüklenirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // USER PROFILE IMAGE OPERATIONS
  // =============================================================================

  /// Uploads a user avatar to Firebase Storage
  Future<String> uploadUserAvatar({
    required String userId,
    required dynamic imageFile,
    required String fileName,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('avatar')
          .child(fileName);

      UploadTask uploadTask;
      
      if (kIsWeb) {
        uploadTask = ref.putData(imageFile as Uint8List);
      } else {
        uploadTask = ref.putFile(imageFile as File);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Kullanıcı avatarı yüklenirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // GENERAL OPERATIONS
  // =============================================================================

  /// Deletes an image from Firebase Storage using its URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
      // Don't throw error for image deletion failures
    }
  }

  /// Deletes multiple images from Firebase Storage
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }

  /// Gets download progress for upload tasks
  Stream<double> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  /// Validates file size (max 5MB)
  bool isValidFileSize(int fileSizeInBytes) {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    return fileSizeInBytes <= maxSizeInBytes;
  }

  /// Validates file type for images
  bool isValidImageType(String fileName) {
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return allowedExtensions.contains(extension);
  }

  /// Generates a unique file name
  String generateFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFileName.substring(originalFileName.lastIndexOf('.'));
    return 'img_${timestamp}$extension';
  }

  // =============================================================================
  // GENERAL FILE OPERATIONS
  // =============================================================================

  /// Uploads a general file to Firebase Storage
  Future<String> uploadFile(File file, String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Dosya yüklenirken hata oluştu: $e');
    }
  }

  /// Uploads a file from bytes (for web)
  Future<String> uploadFileFromBytes(Uint8List bytes, String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Dosya yüklenirken hata oluştu: $e');
    }
  }

  /// Uploads a profile image for a customer
  Future<String> uploadProfileImage({
    required String customerId,
    required dynamic imageFile, // File for mobile, Uint8List for web
    String? fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'profile_$timestamp.jpg';
      final storagePath = 'customers/$customerId/profile/$finalFileName';

      if (kIsWeb) {
        return await uploadFileFromBytes(imageFile as Uint8List, storagePath);
      } else {
        return await uploadFile(imageFile as File, storagePath);
      }
    } catch (e) {
      throw Exception('Profil resmi yüklenirken hata oluştu: $e');
    }
  }

  /// Deletes a file from Firebase Storage
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } catch (e) {
      throw Exception('Dosya silinirken hata oluştu: $e');
    }
  }

  /// Deletes a file from Firebase Storage using URL
  Future<void> deleteFileByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Dosya silinirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // PREDEFINED CATEGORIES AND IMAGES
  // =============================================================================

  /// Returns predefined category images for common food categories
  Map<String, String> getPredefinedCategoryImages() {
    return {
      'Ana Yemekler': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fmain-dishes.jpg?alt=media',
      'Başlangıçlar': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fappetizers.jpg?alt=media',
      'Çorbalar': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fsoups.jpg?alt=media',
      'Salatalar': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fsalads.jpg?alt=media',
      'Tatlılar': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fdesserts.jpg?alt=media',
      'İçecekler': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fdrinks.jpg?alt=media',
      'Pizza': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fpizza.jpg?alt=media',
      'Burger': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fburger.jpg?alt=media',
      'Makarna': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fpasta.jpg?alt=media',
      'Sushi': 'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fcategories%2Fsushi.jpg?alt=media',
    };
  }

  /// Returns predefined product images for common food items
  Map<String, List<String>> getPredefinedProductImages() {
    return {
      'Pizza': [
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fpizza1.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fpizza2.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fpizza3.jpg?alt=media',
      ],
      'Burger': [
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fburger1.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fburger2.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fburger3.jpg?alt=media',
      ],
      'Salata': [
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fsalad1.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fsalad2.jpg?alt=media',
      ],
      'Makarna': [
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fpasta1.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fpasta2.jpg?alt=media',
      ],
      'Tatlı': [
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fdessert1.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fdessert2.jpg?alt=media',
      ],
      'İçecek': [
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fdrink1.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/masamenu-app.appspot.com/o/predefined%2Fproducts%2Fdrink2.jpg?alt=media',
      ],
    };
  }
}
