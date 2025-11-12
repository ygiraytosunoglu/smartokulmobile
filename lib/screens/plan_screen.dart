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

class PlanScreen extends StatefulWidget {
  const PlanScreen({Key? key}) : super(key: key);

  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
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

  String _secimTipi = 'Günlük';
  int _selectedGun = DateTime.now().day;
  int _selectedAy = DateTime.now().month;
  int _selectedYil = DateTime.now().year;

  List<int> get _gunler => List.generate(31, (index) => index + 1);
  List<int> get _aylar => List.generate(12, (index) => index + 1);
  List<int> get _yillar =>
      [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1];

  @override
  void initState() {
    super.initState();
  }

  // 🔹 Planları getir
  void planlariGetir() async {
    int vyear = _selectedYil;
    int vmonth = _selectedAy;
    int vday = _secimTipi == 'Günlük' ? _selectedGun : 0;

    logger.i("Plan getiriliyor → Yıl: $vyear, Ay: $vmonth, Gün: $vday, Tip: $_secimTipi");

    try {
      final urls = await _apiService.getPlan(
        tckn: globals.kullaniciTCKN,
        year: vyear,
        month: vmonth,
        day: vday,
      );

      logger.i("API'den ${urls.length} plan döndü");

      // 🔹 .jpg öncesine kadar base kısmı çıkar
      List<String> cleanUrls = urls.map((u) {
        final idx = u.toLowerCase().indexOf('.jpg');
        return idx != -1 ? u.substring(0, idx + 4) : u;
      }).toList();

      // 🔹 '_K' içerenleri bul (küçük resimler)
      final smallImages = cleanUrls.where((url) => url.contains('_K')).toList();

      final mappedImages = <Map<String, String>>[];

      for (final kucukUrl in smallImages) {
        final buyukUrl = kucukUrl.replaceFirst('_K', '_B');
        final fullKucuk = urls.firstWhere(
                (u) => u.contains(kucukUrl),
            orElse: () => kucukUrl);
        final fullBuyuk = urls.firstWhere(
                (u) => u.contains(buyukUrl),
            orElse: () => buyukUrl);

        mappedImages.add({
          'thumb': fullKucuk,
          'full': fullBuyuk,
          'type': 'image',
        });
      }

      setState(() {
        _galleryMedia
          ..clear()
          ..addAll(mappedImages);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${mappedImages.length} plan bulundu.")),
        );
      }

      logger.i("Eşleşen küçük-büyük planlar: $mappedImages");
    } catch (e) {
      logger.e("Plan alma hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Plan alınamadı")),
        );
      }
    }
  }

  // 🔹 Fotoğraf indirme
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

  // 🔹 Büyük resmi göster
  void _showFullImage(String fullUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
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

  // 🔹 Grid item
  Widget _buildMediaItem(Map<String, String> media) {
    return GestureDetector(
      onTap: () => _showFullImage(media['full']!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: media['thumb']!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildShimmerPlaceholder(),
          errorWidget: (_, __, ___) =>
          const Icon(Icons.broken_image, color: Colors.white),
        ),
      ),
    );
  }

  // 🔹 Yüklenme placeholder
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
        title: const Text('Planlar'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xCC1976D2), Color(0x991976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔹 Tarih ve tip seçim alanları
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _secimTipi,
                                isExpanded: true,
                                onChanged: (val) {
                                  if (val != null) setState(() => _secimTipi = val);
                                },
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Günlük', child: Text('Günlük')),
                                  DropdownMenuItem(
                                      value: 'Aylık', child: Text('Aylık')),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_secimTipi == 'Günlük')
                      Row(
                        children: [
                          _buildDropdown<int>(
                              value: _selectedGun,
                              items: _gunler,
                              onChanged: (v) => setState(() => _selectedGun = v!)),
                          const SizedBox(width: 8),
                          _buildDropdown<int>(
                              value: _selectedAy,
                              items: _aylar,
                              onChanged: (v) => setState(() => _selectedAy = v!)),
                          const SizedBox(width: 8),
                          _buildDropdown<int>(
                              value: _selectedYil,
                              items: _yillar,
                              onChanged: (v) => setState(() => _selectedYil = v!)),
                        ],
                      )
                    else
                      Row(
                        children: [
                          _buildDropdown<int>(
                              value: _selectedAy,
                              items: _aylar,
                              onChanged: (v) => setState(() => _selectedAy = v!)),
                          const SizedBox(width: 8),
                          _buildDropdown<int>(
                              value: _selectedYil,
                              items: _yillar,
                              onChanged: (v) => setState(() => _selectedYil = v!)),
                        ],
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: planlariGetir,
                        icon: const Icon(Icons.search, color: AppColors.primary),
                        label: const Text("Getir",
                            style: TextStyle(color: AppColors.primary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _galleryMedia.isEmpty
                      ? const Center(child: Text("Henüz plan bulunamadı"))
                      : GridView.builder(
                    controller: _scrollController,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Ortak dropdown widget
  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: items
                .map((item) =>
                DropdownMenuItem(value: item, child: Text(item.toString())))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

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
