import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoService {
  static final PhotoService _i = PhotoService._();
  factory PhotoService() => _i;
  PhotoService._();

  // copies photo from temp cache to app permanent doc
  // dir to survive bg/fg cycles and form resets
  Future<String> persistPhoto(String tempPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'lesion_photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File(p.join(photosDir.path, fileName));
    await File(tempPath).copy(dest.path);
    return dest.path;
  }

  // deletes a persisted photo (called after successful upload)
  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
