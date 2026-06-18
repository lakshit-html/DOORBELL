import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'google_drive_service.dart';

/// Unified file storage.
///
/// **Images** (product photos, shop covers, rider KYC, user avatars, E-Mitra
/// documents) are uploaded to Google Drive via [GoogleDriveService] — this
/// avoids Firebase Storage costs on the free Spark plan.
///
/// **Non-image files** (if any) fall back to Firebase Storage.
class StorageService {
  StorageService(this._firebaseStorage, this._driveService);

  final FirebaseStorage _firebaseStorage;
  final GoogleDriveService _driveService;

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};

  bool _isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _imageExtensions.contains(ext);
  }

  String _driveType(String path) {
    if (path.startsWith('products/')) return 'products';
    if (path.startsWith('shops/')) return 'shops';
    if (path.startsWith('riders/')) return 'riders';
    if (path.startsWith('users/')) return 'users';
    if (path.startsWith('emitra/')) return 'emitra';
    return 'products'; // default bucket
  }

  /// Uploads a file and returns a public URL.
  /// Images go to Google Drive; everything else goes to Firebase Storage.
  Future<String> uploadFile(String path, File file) async {
    final filename = path.split('/').last;
    if (_isImage(filename)) {
      return _driveService.uploadImage(
        file: file,
        type: _driveType(path),
        filename: filename,
      );
    }
    // Non-image fallback → Firebase Storage
    final ref = _firebaseStorage.ref(path);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  /// Uploads to a folder using the file name as the object key.
  Future<String> uploadToFolder(String folder, File file) {
    final name = '${DateTime.now().microsecondsSinceEpoch}_'
        '${file.path.split(Platform.pathSeparator).last}';
    return uploadFile('$folder/$name', file);
  }

  Future<void> deleteByUrl(String url) async {
    // Drive URLs can't be deleted from client; Firebase Storage URLs can.
    if (url.contains('firebasestorage')) {
      try {
        await _firebaseStorage.refFromURL(url).delete();
      } catch (_) {}
    }
    // Drive file deletion would require Drive API — skip for now.
  }
}
