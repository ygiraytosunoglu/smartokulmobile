import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../constants.dart';
import 'package:logger/logger.dart';

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

  @override
  void initState() {
    super.initState();
    _loadGalleryMedia();
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

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _galleryMedia.addAll(media);
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
    setState(() {
      _galleryMedia.removeWhere((img) => img['full'] == url);
    });
    // TODO: Sunucu tarafı silme eklenecek
  }

  Widget _buildShimmerPlaceholder() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: const DecoratedBox(
      decoration: BoxDecoration(color: Colors.grey),
    ),
  );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xCC1976D2),
              Color(0x991976D2),
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
                          color: AppColors.primary),
                      label: const Text("Medya Ekle",
                          style: TextStyle(color: AppColors.primary)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
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
                        ? GridView.builder(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child:
        Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}

/*import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../constants.dart';
import 'package:logger/logger.dart';

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

  final List<Map<String, String>> _galleryImages = [];

  bool _isLoading = false;
  bool _isUploading = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _take = 36;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages({bool isLoadMore = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final images = await _apiService.getGalleryWithThumbnails(
        globals.kullaniciTCKN,
        take: _take,
        skip: _skip,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _galleryImages.addAll(images);
          } else {
            _galleryImages.clear();
            _galleryImages.addAll(images);
          }

          _hasMore = images.length == _take;
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

  Future<void> _pickAndUploadImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      setState(() => _isUploading = true);

      final success = await _apiService.uploadGallery(
        globals.kullaniciTCKN,
        pickedFiles.map((x) => File(x.path)).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "Fotoğraflar başarıyla yüklendi"
                : "Fotoğraf yükleme başarısız"),
          ),
        );
      }

      logger.i("fotolar yukleme oncesi");

      if (success) {
        _skip = 0; // 👈 ekledik
        await _loadGalleryImages(); // 👈 güncel listeyi al
      }

      logger.i("fotolar yuklendi");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fotoğraf yükleme hatası: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

/*
  Future<void> _pickAndUploadImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      setState(() => _isUploading = true);

      final success = await _apiService.uploadGallery(
        globals.kullaniciTCKN,
        pickedFiles.map((x) => File(x.path)).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "Fotoğraflar başarıyla yüklendi"
                : "Fotoğraf yükleme başarısız"),
          ),
        );
      }
      logger.i( "fotolar yukleme oncesi");

      if (success) await _loadGalleryImages();
      logger.i( "fotolar yuklendi");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fotoğraf yükleme hatası: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }


  }
*/
  Future<void> _downloadImage(String imageUrl) async {
    try {
      final status = await Permission.photos.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fotoğraflara erişim izni gerekli")),
        );
        return;
      }

      final result = await GallerySaver.saveImage(
        imageUrl,
        albumName: globals.globalOkulAdi?.isNotEmpty == true
            ? globals.globalOkulAdi!
            : "SmartOkul",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == true
                ? "Resim galeriye kaydedildi"
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
                onPressed: () => _downloadImage(fullUrl),
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

  void _deletePhoto(String imageUrl) {
    if (globals.globalKullaniciTipi != 'T') return;
    setState(() {
      _galleryImages.removeWhere((img) => img['full'] == imageUrl);
    });
    // TODO: Sunucu tarafı silme eklenecek
  }

  Widget _buildShimmerPlaceholder() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: const DecoratedBox(
      decoration: BoxDecoration(color: Colors.grey),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xCC1976D2),
              Color(0x991976D2),
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Her sınıf sadece son 100 fotoğrafı görebilir",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (globals.globalKullaniciTipi == "T")
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadImages,
                      icon: const Icon(Icons.add_a_photo,
                          color: AppColors.primary),
                      label: const Text("Fotoğraf Ekle",
                          style: TextStyle(color: AppColors.primary)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!_isLoading &&
                          _hasMore &&
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 600) {
                        _loadGalleryImages(isLoadMore: true);
                      }
                      return false;
                    },
                    child: _isLoading && _galleryImages.isEmpty
                        ? GridView.builder(
                      itemCount: 9,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (_, __) => _buildShimmerPlaceholder(),
                    )
                        : _galleryImages.isEmpty
                        ? const Center(child: Text("Henüz fotoğraf yok"))
                        : GridView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _galleryImages.length,
                      itemBuilder: (context, index) {
                        final img = _galleryImages[index];
                        return GestureDetector(
                          onTap: () => _showFullImage(img['full']!),
                          onLongPress: () => _deletePhoto(img['full']!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: img['thumb']!,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              memCacheHeight: 200,
                              maxWidthDiskCache: 300,
                              maxHeightDiskCache: 300,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              placeholder: (context, url) =>
                                  _buildShimmerPlaceholder(),
                              errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

*/