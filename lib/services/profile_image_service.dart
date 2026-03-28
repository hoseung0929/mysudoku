import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _profileNameKey = 'profile_name';

  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_profileImagePathKey);
    if (savedPath == null || savedPath.isEmpty) {
      return null;
    }

    if (await File(savedPath).exists()) {
      return savedPath;
    }

    await prefs.remove(_profileImagePathKey);
    return null;
  }

  Future<String?> pickAndSaveProfileImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (pickedFile == null) {
      return null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final extension = p.extension(pickedFile.path);
    final savedPath = p.join(directory.path, 'profile_image$extension');
    final savedFile = await File(pickedFile.path).copy(savedPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, savedFile.path);
    return savedFile.path;
  }

  Future<void> clearProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_profileImagePathKey);
    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await prefs.remove(_profileImagePathKey);
  }

  Future<String?> getProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_profileNameKey);
    if (name == null) {
      return null;
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_profileNameKey);
      return null;
    }
    return trimmed;
  }

  Future<void> saveProfileName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_profileNameKey);
      return;
    }
    await prefs.setString(_profileNameKey, trimmed);
  }
}
