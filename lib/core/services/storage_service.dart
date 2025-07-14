import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload a file to Firebase Storage
  Future<String> uploadFile(File file, String folderPath) async {
    try {
      // Generate unique file name
      final fileName = _uuid.v4() + path.extension(file.path);
      final storageRef = _storage.ref().child('$folderPath/$fileName');

      // Upload file
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Dosya yüklenirken bir hata oluştu: $e');
    }
  }

  // Upload web file (Uint8List) to Firebase Storage
  Future<String> uploadWebFile(
    Uint8List fileBytes,
    String fileName,
    String folderPath,
  ) async {
    try {
      // Generate unique file name
      final uniqueFileName = _uuid.v4() + path.extension(fileName);
      final storageRef = _storage.ref().child('$folderPath/$uniqueFileName');

      // Upload file
      final uploadTask = storageRef.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Dosya yüklenirken bir hata oluştu: $e');
    }
  }

  // Delete a file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      if (fileUrl.isEmpty) return;

      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Dosya silinirken bir hata oluştu: $e');
    }
  }

  // Upload a profile image
  Future<String> uploadProfileImage(File file, String userId) async {
    return uploadFile(file, 'profile_images/$userId');
  }

  // Upload a business logo
  Future<String> uploadBusinessLogo(File file, String businessId) async {
    return uploadFile(file, 'business_logos/$businessId');
  }

  // Upload a product image
  Future<String> uploadProductImage(
    File file,
    String businessId,
    String productId,
  ) async {
    return uploadFile(file, 'product_images/$businessId/$productId');
  }

  // Upload a category image
  Future<String> uploadCategoryImage(
    File file,
    String businessId,
    String categoryId,
  ) async {
    return uploadFile(file, 'category_images/$businessId/$categoryId');
  }

  // Web specific upload methods
  Future<String> uploadWebProfileImage(
    Uint8List fileBytes,
    String fileName,
    String userId,
  ) async {
    return uploadWebFile(fileBytes, fileName, 'profile_images/$userId');
  }

  Future<String> uploadWebBusinessLogo(
    Uint8List fileBytes,
    String fileName,
    String businessId,
  ) async {
    return uploadWebFile(fileBytes, fileName, 'business_logos/$businessId');
  }

  Future<String> uploadWebProductImage(
    Uint8List fileBytes,
    String fileName,
    String businessId,
    String productId,
  ) async {
    return uploadWebFile(
      fileBytes,
      fileName,
      'product_images/$businessId/$productId',
    );
  }

  Future<String> uploadWebCategoryImage(
    Uint8List fileBytes,
    String fileName,
    String businessId,
    String categoryId,
  ) async {
    return uploadWebFile(
      fileBytes,
      fileName,
      'category_images/$businessId/$categoryId',
    );
  }
}
