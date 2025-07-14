import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Dosya yükleme
  Future<String> uploadFile(File file, String fileName) async {
    try {
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(file);
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
      final bytes = await file.readAsBytes();
      return await uploadBytes(Uint8List.fromList(bytes), fileName);
    } catch (e) {
      throw Exception('Dosya yüklenirken hata: $e');
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

  /// Dosya boyutu kontrolü
  bool isValidFileSize(File file, {int maxSizeInMB = 5}) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= maxSizeInMB;
  }

  /// Dosya türü kontrolü
  bool isValidImageType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Güvenli dosya adı oluşturma
  String generateSafeFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last.toLowerCase();
    return '${timestamp}_${originalName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.$extension';
  }
}
