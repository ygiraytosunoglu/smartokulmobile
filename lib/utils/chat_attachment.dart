import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

const int maxChatAttachmentBytes = 50 * 1024 * 1024;

const Set<String> allowedChatExtensions = {
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic',
  'mp4', 'mov', '3gp', 'webm',
  'm4a', 'aac', 'mp3', 'ogg', 'opus', 'wav',
  'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'rar',
};

String chatFileExtension(String path) =>
    p.extension(path).replaceFirst('.', '').toLowerCase();

String ekTuruFromPath(String path) {
  final ext = chatFileExtension(path);
  if ({'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}.contains(ext)) return 'image';
  if ({'mp4', 'mov', '3gp', 'webm'}.contains(ext)) return 'video';
  if ({'m4a', 'aac', 'mp3', 'ogg', 'opus', 'wav'}.contains(ext)) return 'audio';
  if ({'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'rar'}
      .contains(ext)) {
    return 'document';
  }
  return 'file';
}

String? validateChatAttachment(File file) {
  final ext = chatFileExtension(file.path);
  if (ext.isEmpty || !allowedChatExtensions.contains(ext)) {
    return 'ERR_MESAJ_EK_TIP_DESTEKLENMIYOR';
  }
  try {
    if (file.lengthSync() > maxChatAttachmentBytes) {
      return 'ERR_MESAJ_EK_BOYUT_ASIMI';
    }
  } catch (_) {
    return 'ERR_MESAJ_EK_YUKLENEMEDI';
  }
  return null;
}

String formatDosyaBoyut(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

DateTime? chatInsertDate(Map mesaj) {
  final raw = mesaj['InsertDate']?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String chatSaat(Map mesaj) {
  final saat = (mesaj['Saat'] ?? '').toString().trim();
  if (saat.isNotEmpty) return saat;
  final d = chatInsertDate(mesaj);
  if (d == null) return '';
  return DateFormat('HH:mm').format(d.toLocal());
}

String chatGunEtiketi(Map mesaj) {
  final d = chatInsertDate(mesaj)?.toLocal();
  if (d != null) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Bugün';
    if (day == today.subtract(const Duration(days: 1))) return 'Dün';
    return DateFormat('dd.MM.yyyy').format(d);
  }
  final tarih = (mesaj['Tarih'] ?? '').toString().trim();
  return tarih;
}

bool chatAyniGun(Map a, Map b) {
  final da = chatInsertDate(a)?.toLocal();
  final db = chatInsertDate(b)?.toLocal();
  if (da == null || db == null) {
    return (a['Tarih'] ?? '') == (b['Tarih'] ?? '');
  }
  return da.year == db.year && da.month == db.month && da.day == db.day;
}

Future<String?> _pickAttachmentSource(
  BuildContext context, {
  bool includeVideo = true,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeri'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Kamera'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          if (includeVideo)
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video çek'),
              onTap: () => Navigator.pop(ctx, 'camera_video'),
            ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: const Text('Dosya'),
            onTap: () => Navigator.pop(ctx, 'file'),
          ),
        ],
      ),
    ),
  );
}

Future<File?> pickChatAttachment(BuildContext context) async {
  final choice = await _pickAttachmentSource(context);
  if (choice == null) return null;

  final picker = ImagePicker();
  if (choice == 'gallery') {
    final x = await picker.pickMedia();
    if (x == null) return null;
    return File(x.path);
  }
  if (choice == 'camera') {
    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null) return null;
    return File(x.path);
  }
  if (choice == 'camera_video') {
    final x = await picker.pickVideo(source: ImageSource.camera);
    if (x == null) return null;
    return File(x.path);
  }
  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  final path = result?.files.single.path;
  if (path == null) return null;
  return File(path);
}

/// Galeri / kamera / dosya; birden fazla seçime izin verir (iptalde boş liste).
Future<List<File>> pickMultipleAttachments(BuildContext context) async {
  final choice = await _pickAttachmentSource(context, includeVideo: false);
  if (choice == null) return const [];

  final picker = ImagePicker();
  if (choice == 'gallery') {
    final xs = await picker.pickMultiImage();
    return xs.map((x) => File(x.path)).toList();
  }
  if (choice == 'camera') {
    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null) return const [];
    return [File(x.path)];
  }
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: true,
  );
  if (result == null) return const [];
  return result.paths.whereType<String>().map(File.new).toList();
}

class ChatSendPayload {
  final File file;
  final String caption;
  ChatSendPayload({required this.file, required this.caption});
}

Future<ChatSendPayload?> confirmChatAttachment({
  required BuildContext context,
  required File file,
  String initialCaption = '',
}) async {
  final captionCtrl = TextEditingController(text: initialCaption);
  final tur = ekTuruFromPath(file.path);
  final name = p.basename(file.path);
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tur == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, height: 180, fit: BoxFit.cover),
              )
            else
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(name),
                subtitle: Text(formatDosyaBoyut(file.lengthSync())),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: captionCtrl,
              decoration: const InputDecoration(
                hintText: 'Açıklama (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Gönder'),
              ),
            ),
          ],
        ),
      );
    },
  );
  final caption = captionCtrl.text.trim();
  captionCtrl.dispose();
  if (result != true) return null;
  return ChatSendPayload(file: file, caption: caption);
}
