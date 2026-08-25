import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Captures or selects an image and permanently saves it in app storage folder.
  /// Returns the saved absolute file path or null if user cancelled / denied.
  static Future<String?> pickAndSaveImage({required ImageSource source}) async {
    try {
      // Check & request runtime permissions if needed
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          throw Exception('Camera permission is permanently denied. Please enable it in Settings.');
        } else if (status.isDenied) {
          throw Exception('Camera permission was denied.');
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Ensure storage directory in app document directory exists
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'patient_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName = 'patient_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path).isNotEmpty ? p.extension(pickedFile.path) : ".jpg"}';
      final savedImage = File(p.join(photosDir.path, fileName));

      // Copy to persistent application storage
      await File(pickedFile.path).copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Helper to check if file exists
  static bool imageExists(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}
