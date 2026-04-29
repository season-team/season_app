import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:season_app/core/localization/generated/l10n.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickFromGallery({bool compress = true}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: compress ? 75 : 100);
    if (image == null) return null;
    return File(image.path);
  }

  static Future<File?> pickFromCamera({bool compress = true}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: compress ? 75 : 100);
    if (image == null) return null;
    return File(image.path);
  }

  static Future<List<File>> pickMultipleImages({bool compress = true}) async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: compress ? 75 : 100);
    return images.map((e) => File(e.path)).toList();
  }

  static Future<void> showPickerDialog(
    BuildContext context,
    Function(File?) onImagePicked,
    AppLocalizations loc,
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(loc.imagePickerGallery),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickFromGallery();
                  onImagePicked(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(loc.imagePickerCamera),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickFromCamera();
                  onImagePicked(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
