import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Platform-aware dosya yükleme
  Future<String> uploadFile(dynamic file, String fileName) async {
    try {
      final ref = _storage.ref().child(fileName);
      UploadTask uploadTask;

      if (kIsWeb) {
        // Web için
        if (file is XFile) {
          final bytes = await file.readAsBytes();
          uploadTask = ref.putData(bytes);
        } else if (file is Uint8List) {
          uploadTask = ref.putData(file);
        } else {
          throw Exception('Web platformunda desteklenmeyen dosya türü');
        }
      } else {
        // Mobil/Desktop için
        if (file is File) {
          uploadTask = ref.putFile(file);
        } else if (file is XFile) {
          final fileData = File(file.path);
          uploadTask = ref.putFile(fileData);
        } else {
          throw Exception('Desteklenmeyen dosya türü');
        }
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Dosya yüklenirken hata: $e');
    }
  }

  /// Bytes'dan dosya yükleme (web için)
  Future<String> uploadBytes(Uint8List bytes, String fileName) async {
    try {
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Dosya yüklenirken hata: $e');
    }
  }

  /// XFile'dan dosya yükleme
  Future<String> uploadXFile(XFile file, String fileName) async {
    try {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        return await uploadBytes(bytes, fileName);
      } else {
        final fileData = File(file.path);
        return await uploadFile(fileData, fileName);
      }
    } catch (e) {
      throw Exception('Dosya yüklenirken hata: $e');
    }
  }

  /// İşletme logosu yükleme
  Future<String> uploadBusinessLogo(dynamic file, String businessId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'business_logos/${businessId}_$timestamp.jpg';
      return await uploadFile(file, fileName);
    } catch (e) {
      throw Exception('Logo yüklenirken hata: $e');
    }
  }

  /// Ürün resmi yükleme
  Future<String> uploadProductImage(dynamic file, String businessId, String productId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_images/$businessId/${productId}_$timestamp.jpg';
      return await uploadFile(file, fileName);
    } catch (e) {
      throw Exception('Ürün resmi yüklenirken hata: $e');
    }
  }

  /// QR kod resmi yükleme
  Future<String> uploadQRCode(dynamic file, String businessId, String qrId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'qr_codes/$businessId/${qrId}_$timestamp.png';
      return await uploadFile(file, fileName);
    } catch (e) {
      throw Exception('QR kod yüklenirken hata: $e');
    }
  }

  /// Dosya silme
  Future<void> deleteFile(String fileName) async {
    try {
      final ref = _storage.ref().child(fileName);
      await ref.delete();
    } catch (e) {
      throw Exception('Dosya silinirken hata: $e');
    }
  }

  /// URL'den dosya silme
  Future<void> deleteFileFromUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Dosya silinirken hata: $e');
    }
  }

  /// Dosya boyutu kontrolü (web için bytes, mobil için file)
  bool isValidFileSize(dynamic file, {int maxSizeInMB = 5}) {
    try {
      int sizeInBytes;
      
      if (kIsWeb) {
        if (file is Uint8List) {
          sizeInBytes = file.length;
        } else {
          return false;
        }
      } else {
        if (file is File) {
          sizeInBytes = file.lengthSync();
        } else {
          return false;
        }
      }
      
      final sizeInMB = sizeInBytes / (1024 * 1024);
      return sizeInMB <= maxSizeInMB;
    } catch (e) {
      return false;
    }
  }

  /// Dosya türü kontrolü
  bool isValidImageType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// XFile için dosya türü kontrolü
  bool isValidImageTypeFromXFile(XFile file) {
    return isValidImageType(file.name);
  }

  /// Güvenli dosya adı oluşturma
  String generateSafeFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last.toLowerCase();
    final baseName = originalName.split('.').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return '${timestamp}_${baseName}.$extension';
  }

  /// Dosya yükleme durumu tracking
  Stream<TaskSnapshot> uploadFileWithProgress(dynamic file, String fileName) {
    try {
      final ref = _storage.ref().child(fileName);
      UploadTask uploadTask;

      if (kIsWeb) {
        if (file is XFile) {
          // Web için async işlemi handle et
          return _uploadXFileWeb(file, ref);
        } else if (file is Uint8List) {
          uploadTask = ref.putData(file);
        } else {
          throw Exception('Web platformunda desteklenmeyen dosya türü');
        }
      } else {
        if (file is File) {
          uploadTask = ref.putFile(file);
        } else if (file is XFile) {
          final fileData = File(file.path);
          uploadTask = ref.putFile(fileData);
        } else {
          throw Exception('Desteklenmeyen dosya türü');
        }
      }

      return uploadTask.snapshotEvents;
    } catch (e) {
      throw Exception('Dosya yükleme başlatılırken hata: $e');
    }
  }

  /// Web için XFile yükleme helper metodu
  Stream<TaskSnapshot> _uploadXFileWeb(XFile file, Reference ref) async* {
    try {
      final bytes = await file.readAsBytes();
      final uploadTask = ref.putData(bytes);
      yield* uploadTask.snapshotEvents;
    } catch (e) {
      throw Exception('Web dosya yükleme hatası: $e');
    }
  }

  /// İşletme klasörü oluşturma
  Future<void> createBusinessFolder(String businessId) async {
    try {
      // Firebase Storage'da boş bir .placeholder dosyası oluştur
      final ref = _storage.ref().child('businesses/$businessId/.placeholder');
      await ref.putString('');
    } catch (e) {
      print('İşletme klasörü oluşturulurken hata: $e');
    }
  }

  /// İşletme dosyalarını silme
  Future<void> deleteBusinessFiles(String businessId) async {
    try {
      final ref = _storage.ref().child('businesses/$businessId');
      final listResult = await ref.listAll();
      
      // Tüm dosyaları sil
      for (final item in listResult.items) {
        await item.delete();
      }
      
      // Alt klasörleri sil
      for (final prefix in listResult.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (e) {
      print('İşletme dosyaları silinirken hata: $e');
    }
  }

  /// Klasör silme helper
  Future<void> _deleteFolder(Reference folderRef) async {
    try {
      final listResult = await folderRef.listAll();
      
      for (final item in listResult.items) {
        await item.delete();
      }
      
      for (final prefix in listResult.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (e) {
      print('Klasör silinirken hata: $e');
    }
  }
}
