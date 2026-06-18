import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Uploads images to Google Drive and returns a public-shareable URL.
///
/// All DoorBell media is stored in a shared folder on the admin's Google Drive
/// (lakshitsolanki1234@gmail.com) and served as public links — this avoids
/// Firebase Storage costs on the free Spark plan.
///
/// Setup required (one-time):
///   1. Go to https://console.cloud.google.com
///   2. Enable the Google Drive API for your project.
///   3. Add Drive scope to your OAuth client:
///        https://www.googleapis.com/auth/drive.file
///   4. Create a folder in the Drive account and paste the folder ID into
///      [_rootFolderId] below.
///   5. Make that folder "Anyone with the link can view".
class GoogleDriveService {
  GoogleDriveService();

  /// The Google Drive folder ID where all DoorBell media is stored.
  /// Create a folder in Drive → right-click → Share → "Anyone with link" → copy ID from URL.
  static const String _rootFolderId =
      String.fromEnvironment('GDRIVE_FOLDER_ID', defaultValue: 'YOUR_FOLDER_ID_HERE');

  /// Sub-folders by media type.
  static const _subFolders = {
    'products': 'doorbell_products',
    'shops': 'doorbell_shops',
    'riders': 'doorbell_riders',
    'users': 'doorbell_users',
    'emitra': 'doorbell_emitra',
  };

  // Cached sub-folder IDs to avoid re-querying each upload.
  final Map<String, String> _folderIdCache = {};

  static const _driveScopes = ['https://www.googleapis.com/auth/drive.file'];

  Future<drive.DriveApi> _api() async {
    // google_sign_in v7: authenticate first, then authorize Drive scope.
    final user = await GoogleSignIn.instance.authenticate();
    final authorized = await user.authorizationClient.authorizeScopes(_driveScopes);
    final client = authorized.authClient(scopes: _driveScopes);
    return drive.DriveApi(client);
  }

  /// Ensures the named sub-folder exists inside [_rootFolderId] and returns its ID.
  Future<String> _ensureSubFolder(drive.DriveApi api, String type) async {
    if (_folderIdCache.containsKey(type)) return _folderIdCache[type]!;
    final name = _subFolders[type] ?? 'doorbell_misc';

    // Search for existing folder.
    final existing = await api.files.list(
      q: "name='$name' and mimeType='application/vnd.google-apps.folder' "
          "and '$_rootFolderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id)',
    );

    if (existing.files != null && existing.files!.isNotEmpty) {
      final id = existing.files!.first.id!;
      _folderIdCache[type] = id;
      return id;
    }

    // Create it.
    final folder = await api.files.create(
      drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [_rootFolderId],
      $fields: 'id',
    );
    final id = folder.id!;
    // Make it publicly readable.
    await api.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = 'reader',
      id,
    );
    _folderIdCache[type] = id;
    return id;
  }

  /// Uploads [file] to the appropriate sub-folder and returns a direct image URL.
  ///
  /// [type] must be one of: 'products', 'shops', 'riders', 'users', 'emitra'.
  /// [filename] is used as the file name in Drive (include extension, e.g. 'photo.jpg').
  Future<String> uploadImage({
    required File file,
    required String type,
    required String filename,
  }) async {
    final api = await _api();
    final folderId = await _ensureSubFolder(api, type);

    final media = drive.Media(file.openRead(), await file.length());

    final driveFile = await api.files.create(
      drive.File()
        ..name = '${DateTime.now().millisecondsSinceEpoch}_$filename'
        ..mimeType = _mimeType(filename)
        ..parents = [folderId],
      uploadMedia: media,
      $fields: 'id',
    );

    final fileId = driveFile.id!;

    // Make the file publicly readable.
    await api.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = 'reader',
      fileId,
    );

    // Return a direct thumbnail URL that Flutter's Image widget can load.
    // Using the export/thumbnail endpoint gives a stable direct-download link.
    return 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
  }

  String _mimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}
