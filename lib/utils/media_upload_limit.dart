import 'dart:io';
import 'package:flutter/material.dart';

const int maxMediaUploadBytes = 1 * 1024 * 1024 * 1024; // 1 GB

const String mediaUploadLimitMessage =
    'Seçtiğiniz fotoğraf veya videonun boyutu 1 GB sınırını aşıyor.\n\n1 GB üzerindeki dosyalar yüklenemez.';

bool isFileOverMediaLimit(File file) {
  try {
    return file.lengthSync() > maxMediaUploadBytes;
  } catch (_) {
    return false;
  }
}

bool anyFileOverMediaLimit(List<File> files) =>
    files.any(isFileOverMediaLimit);

Future<bool> ensureFilesWithinMediaLimit(
  BuildContext context,
  List<File> files,
) async {
  if (!anyFileOverMediaLimit(files)) return true;
  if (!context.mounted) return false;

  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Dosya Çok Büyük'),
        ],
      ),
      content: const Text(mediaUploadLimitMessage),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
  return false;
}
