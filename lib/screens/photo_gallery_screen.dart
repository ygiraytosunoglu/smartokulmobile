import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
//import 'package:smart_okul_mobile/screens/plan_screen.dart';
//import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../constants.dart';
import 'package:logger/logger.dart';
import 'package:smart_okul_mobile/screens/video_player_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({Key? key}) : super(key: key);

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final logger = Logger();

  final List<Map<String, String>> _galleryMedia = [];

  bool _isLoading = false;
  bool _isUploading = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _take = 36;
  Map<String, List<Map<String, String>>> _groupedMedia = {};

  @override
  void initState() {
    super.initState();
    _loadGalleryMedia();
  }

  Map<String, List<Map<String, String>>> groupByDate(
      List<Map<String, String>> media) {
    final Map<String, List<Map<String, String>>> grouped = {};

    for (var item in media) {
      final url = item["full"]!;
      final fileName = url.split('/').last;

      // Dosya adı "20251124093941565_xxx.jpg"
      final datePart = fileName.split('_').first.substring(0, 8);

      final year = datePart.substring(0, 4);
      final month = datePart.substring(4, 6);
      final day = datePart.substring(6, 8);

      final formattedDate = "$year-$month-$day"; // 2025-11-24 şeklinde

      grouped.putIfAbsent(formattedDate, () => []);
      grouped[formattedDate]!.add(item);
    }

    return grouped;
  }
  Future<void> _loadGalleryMedia({bool isLoadMore = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final media = await _apiService.getGalleryWithThumbnails(
        globals.kullaniciTCKN,
        take: _take,
        skip: _skip,
      );

      if (!mounted) return;

      if (isLoadMore) {
        _galleryMedia.addAll(media);
      } else {
        _galleryMedia
          ..clear()
          ..addAll(media);
      }

      // HER ZAMAN güncelle
      _groupedMedia = groupByDate(_galleryMedia);

      _hasMore = media.length == _take;
      _skip += _take;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Galeri yüklenemedi: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  /*Future<void> _loadGalleryMedia({bool isLoadMore = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final media = await _apiService.getGalleryWithThumbnails(
        globals.kullaniciTCKN,
        take: _take,
        skip: _skip,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _galleryMedia.addAll(media);
            _groupedMedia = groupByDate(_galleryMedia);
          } else {
            _galleryMedia.clear();
            _galleryMedia.addAll(media);
          }

          _hasMore = media.length == _take;
          _skip += _take;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Galeri yüklenemedi: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
*/
  /*
  Future<void> _pickAndUploadMedia() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      final pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);

      List<File> filesToUpload = [];

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        filesToUpload.addAll(pickedFiles.map((x) => File(x.path)));
      }
      if (pickedVideo != null) {
        filesToUpload.add(File(pickedVideo.path));
      }
      if (filesToUpload.isEmpty) return;

      setState(() => _isUploading = true);

      final success = await _apiService.uploadGallery(
        globals.kullaniciTCKN,
        filesToUpload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "Medya başarıyla yüklendi"
                : "Medya yükleme başarısız"),
          ),
        );
      }

      if (success) {
        _skip = 0;
        await _loadGalleryMedia();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Medya yükleme hatası: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
*/
  Future<void> _pickAndUploadMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
      );

      if (result == null) return;

      List<File> filesToUpload = [];
      List<File> selectedFiles = result.paths.map((path) => File(path!)).toList();

      for (var file in selectedFiles) {
        filesToUpload.add(file);

        // Video mu?
        final ext = file.path.split('.').last.toLowerCase();
        if (['mp4', 'mov'].contains(ext)) {
          final thumb = await generateVideoThumbnail(file.path);

          if (thumb != null) {
            filesToUpload.add(thumb);
          }
        }
      }

      setState(() => _isUploading = true);

      final success = await _apiService.uploadGallery(
        globals.kullaniciTCKN,
        filesToUpload, // içine videolar + thumbnail eklenmiş oldu
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "Medya başarıyla yüklendi"
                : "Medya yükleme başarısız"),
          ),
        );
      }

      if (success) {
        _skip = 0;
        await _loadGalleryMedia();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Medya yükleme hatası: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<File?> generateVideoThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        quality: 85,
      );

      if (thumbPath == null) return null;
      return File(thumbPath);
    } catch (e) {
      print("Thumbnail oluşturma hatası: $e");
      return null;
    }
  }

  Future<void> _downloadMedia(String url) async {
    try {
      final status = await Permission.photos.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fotoğraflara erişim izni gerekli")),
        );
        return;
      }

      final result = await GallerySaver.saveImage(
        url,
        albumName: globals.globalOkulAdi?.isNotEmpty == true
            ? globals.globalOkulAdi!
            : "SmartOkul",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == true
                ? "Medya galeriye kaydedildi"
                : "Galeriye kaydetme başarısız"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    }
  }

  void _showFullImage(String fullUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(0),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(
                      child: Icon(Icons.broken_image,
                          size: 50, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 32,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.download, color: Colors.white, size: 30),
                onPressed: () => _downloadMedia(fullUrl),
              ),
            ),
            Positioned(
              top: 32,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMedia(String url) {
    if (globals.globalKullaniciTipi != 'T') return;
   /* setState(() {
      _galleryMedia.removeWhere((img) => img['full'] == url);
    });*/
    // TODO: Sunucu tarafı silme eklenecek
  }

  Widget _buildShimmerPlaceholder() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: const DecoratedBox(
      decoration: BoxDecoration(color: Colors.grey),
    ),
  );

  Future<void> _confirmDelete(String fullUrl) async {
    final fileName = fullUrl.split('/').last;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Medya Sil"),
        content: const Text("Bu medya kalıcı olarak silinecek. Emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteMediaFromServer(fileName, fullUrl);
    }
  }

  String getSafeFileName(String fileName) {
    final match = RegExp(
      r'^.+?\.(jpg|jpeg|png|mp4|mov)',
      caseSensitive: false,
    ).firstMatch(fileName);

    return match?.group(0) ?? fileName;
  }

  Future<void> _deleteMediaFromServer(String fileName, String fullUrl) async {
    logger.i("DeleteGallery çağrılıyor: $fileName");
    logger.i("2.filename: "+getSafeFileName(fileName));

    try {
      final success = await _apiService.deleteGallery(
        tckn: globals.kullaniciTCKN,
        fileName: getSafeFileName(fileName),
      );

      if (!success) {
        throw Exception("Silme başarısız");
      }

      setState(() {
        _galleryMedia.removeWhere((m) => m['full'] == fullUrl);
        _groupedMedia = groupByDate(_galleryMedia);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medya silindi")),
      );
    } catch (e) {
      logger.e("Medya silme hatası", error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme başarısız: $e")),
      );
    }
  }

  Widget _buildMediaItem(Map<String, String> media) {
    final full = media['full']!;
    final thumb = media['thumb'] ?? full;

    final uri = Uri.parse(full);
    final isVideo = uri.path.toLowerCase().endsWith('.mp4');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (isVideo) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(videoUrl: full),
                  ),
                );
              } else {
                _showFullImage(full);
              }
            },
            child: CachedNetworkImage(
              imageUrl: thumb,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildShimmerPlaceholder(),
              errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 40, color: Colors.red),
            ),
          ),

          // ▶️ Video ikonu
          if (isVideo)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.play_circle_fill,
                  size: 32, color: Colors.white),
            ),

          // 🗑️ DELETE BUTONU (SADECE ÖĞRETMEN)
          if (globals.globalKullaniciTipi == 'T')
            Positioned(
              bottom: 6,
              right: 6,
              child: InkWell(
                onTap: () => _confirmDelete(full),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

/*
  Widget _buildMediaItem(Map<String, String> media) {
    final isVideo = media['type'] == 'video';
    return GestureDetector(
      onTap: () {
        if (isVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(videoUrl: media['full']!),
            ),
          );
        } else {
          _showFullImage(media['full']!);
        }
      },
      onLongPress: () => _deleteMedia(media['full']!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isVideo
            ? Stack(
          children: [
            CachedNetworkImage(
              imageUrl: media['thumb']!,
              fit: BoxFit.cover,
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.play_circle_fill,
                  color: Colors.white, size: 30),
            ),
          ],
        )
            : CachedNetworkImage(
          imageUrl: media['thumb']!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
*/
/*
  Widget _buildMediaItem(Map<String, String> media) {
    final url = media['full']!;
    print("_buildMediaItem url:"+url);
    final isVideo = url.toLowerCase().contains(".mp4");
    print("isVideo: "+isVideo.toString());

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          print("video acilacak");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                print("VideoPlayerScreen builder tetiklendi");
                return VideoPlayerScreen(videoUrl: url);
              },
            ),
          );
          print("video acildi");

        } else {
          _showFullImage(url);

        }
      },
      onLongPress: () => _deleteMedia(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isVideo
            ? Stack(
          children: [
            CachedNetworkImage(
              imageUrl: media['thumb']!,
              fit: BoxFit.cover,
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.play_circle_fill,
                  color: Colors.white, size: 30),
            ),
          ],
        )
            : CachedNetworkImage(
          imageUrl: media['thumb']!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
*/
  /*
  Widget _buildMediaItem(Map<String, String> media) {
    final full = media['full']!;
    final thumb = media['thumb'] ?? full;

    final uri = Uri.parse(full);
    final isVideo = uri.path.toLowerCase().endsWith('.mp4');

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(videoUrl: full),
            ),
          );
        } else {
          _showFullImage(full);
        }
      },
      onLongPress: () => _deleteMedia(full),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: thumb,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildShimmerPlaceholder(),
              errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 40, color: Colors.red),
            ),
            if (isVideo)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.play_circle_fill,
                    size: 32, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
*/
  /* Widget _buildMediaItem(Map<String, String> media) {
    final full = media['full']!;
    final thumb = media['thumb'] ?? full;

    /*
    final isVideo = full.toLowerCase().endsWith(".mp4");
*/
    final uri = Uri.parse(full);
    final isVideo = uri.path.toLowerCase().endsWith('.mp4');

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(videoUrl: full),
            ),
          );
        } else {
          _showFullImage(full);
        }
      },
      onLongPress: () => _deleteMedia(full),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: thumb,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildShimmerPlaceholder(),
              errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 40, color: Colors.red),
            ),
            if (isVideo)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.play_circle_fill,
                    size: 32, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const
        Text(
            'Galeri',
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,//Color(0xCC1976D2),
              AppColors.background,//Color(0x991976D2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /*const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Her sınıf sadece son 100 medya öğesini görebilir",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),*/
                if (globals.globalKullaniciTipi == "T")
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadMedia,
                      icon: const Icon(Icons.add_a_photo,
                          color: AppColors.onPrimary),
                      label:  Text("Medya Ekle",
                          style: AppStyles.buttonTextStyle),
                      style: AppStyles.buttonStyle,/*ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),*/
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: _groupedMedia.isEmpty
                      ? const Center(child: Text(" ")) //Center(child: Text("Henüz medya yok"))
                      : ListView(
                    controller: _scrollController,
                    children: _groupedMedia.entries.map((entry) {
                      final date =  DateFormat('dd-MM-yyyy').format(DateTime.parse(entry.key)); ;
                      final items = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📅 Tarih başlığı
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              "📅 $date",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          // Grid alanı
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemBuilder: (_, index) =>
                                _buildMediaItem(items[index]),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                /*Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!_isLoading &&
                          _hasMore &&
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 600) {
                        _loadGalleryMedia(isLoadMore: true);
                      }
                      return false;
                    },
                    child: _isLoading && _galleryMedia.isEmpty
                        ?
                    GridView.builder(
                      itemCount: 9,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (_, __) => _buildShimmerPlaceholder(),
                    )
                        : _galleryMedia.isEmpty
                        ? const Center(child: Text("Henüz medya yok"))
                        : GridView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _galleryMedia.length,
                      itemBuilder: (context, index) {
                        final media = _galleryMedia[index];
                        return _buildMediaItem(media);
                      },
                    ),
                  ),
                ),
             */
              ],
            ),
          ),
        ),
      ),
    );
  }
}
