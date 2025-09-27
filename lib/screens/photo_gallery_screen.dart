import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;
import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({Key? key}) : super(key: key);

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  List<String> galleryImages = [];
  bool isLoading = true;
  bool isUploading = false;
  int skip = 0;
  final int take = 18;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _loadMoreImages();
      }
    });
  }

  Future<void> _loadGalleryImages() async {
    setState(() => isLoading = true);
    try {
      skip = 0;
      final images = await _apiService.getGallery(
        globals.kullaniciTCKN,
        take: take,
        skip: skip,
      );
      setState(() {
        galleryImages = images;
        hasMore = images.length == take;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Galeri yüklenemedi: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<void> _loadMoreImages() async {
    setState(() => isLoading = true);
    try {
      skip += take;
      final images = await _apiService.getGallery(
        globals.kullaniciTCKN,
        take: take,
        skip: skip,
      );
      setState(() {
        galleryImages.addAll(images);
        if (images.length < take) hasMore = false;
      });
    } catch (e) {
      print("Daha fazla fotoğraf yüklenemedi: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        List<File> files = pickedFiles.map((xfile) => File(xfile.path)).toList();

        bool success =
        await ApiService().uploadGallery(globals.kullaniciTCKN, files);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fotoğraflar yüklendi")),
          );
          _loadGalleryImages();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fotoğraf yükleme başarısız")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraf yükleme hatası: $e")),
      );
    }
  }

 /* Future<bool> saveImageToGallery(File file) async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) return false;
    }

    final directory = await getExternalStorageDirectory();
    final path = directory!.path + '/SmartOkulGallery';
    await Directory(path).create(recursive: true);
    final newFile = await file.copy('$path/${DateTime.now().millisecondsSinceEpoch}.jpg');
    return newFile.existsSync();
  }

  Future<void> _downloadImage(String url) async {
    try {
      var response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 100,
        name: "smart_okul_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📷 Fotoğraf galeriye kaydedildi")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Kaydetme başarısız")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }*/

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.download, color: Colors.white, size: 30),
                onPressed: () => null,//_downloadImage(imageUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(String imageUrl) async {
    if (globals.globalKullaniciTipi != 'T') return; // sadece öğretmen
    // TODO: ApiService().deleteGalleryPhoto çağrısı eklenebilir
    setState(() {
      galleryImages.remove(imageUrl);
    });
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : _pickAndUploadImages,
                    icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
                    label: const Text(
                      "Fotoğraf Ekle",
                      style: TextStyle(color: AppColors.primary),
                    ),
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
                  child: isLoading && galleryImages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : galleryImages.isEmpty
                      ? const Center(child: Text("Henüz fotoğraf yok"))
                      : GridView.builder(
                    controller: _scrollController,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = galleryImages[index];
                      return GestureDetector(
                        onTap: () => _showFullImage(imageUrl),
                        onLongPress: () => _deletePhoto(imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder:
                                (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                          ),
                        ),
                      );
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
}


/* 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({Key? key}) : super(key: key);

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  List<String> galleryImages = [];
  bool isLoading = true;
  bool isUploading = false;
  int skip = 0;
  final int take = 18;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _loadMoreImages();
      }
    });
  }

  Future<void> _loadGalleryImages() async {
    setState(() => isLoading = true);
    try {
      skip = 0;
      final images =
      await _apiService.getGallery(globals.kullaniciTCKN, take: take, skip: skip);
      setState(() {
        galleryImages = images;
        hasMore = images.length == take;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Galeri yüklenemedi: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreImages() async {
    setState(() => isLoading = true);
    try {
      skip += take;
      final images =
      await _apiService.getGallery(globals.kullaniciTCKN, take: take, skip: skip);
      setState(() {
        galleryImages.addAll(images);
        if (images.length < take) hasMore = false;
      });
    } catch (e) {
      print("Daha fazla fotoğraf yüklenemedi: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(); // List<XFile>

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        List<File> files = pickedFiles.map((xfile) => File(xfile.path)).toList();

        bool success =
        await ApiService().uploadGallery(globals.kullaniciTCKN, files);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fotoğraflar yüklendi")),
          );
          _loadGalleryImages();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fotoğraf yükleme başarısız")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraf yükleme hatası: $e")),
      );
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  Future<void> _deletePhoto(String imageUrl) async {
    if (globals.globalKullaniciTipi != 'T') return; // sadece öğretmen
    // TODO: ApiService().deleteGalleryPhoto çağrısı eklenebilir
    setState(() {
      galleryImages.remove(imageUrl);
    });
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : _pickAndUploadImages,
                    icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
                    label: const Text(
                      "Fotoğraf Ekle",
                      style: TextStyle(color: AppColors.primary),
                    ),
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
                  child: isLoading && galleryImages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : galleryImages.isEmpty
                      ? const Center(child: Text("Henüz fotoğraf yok"))
                      : GridView.builder(
                    controller: _scrollController,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = galleryImages[index];
                      return GestureDetector(
                        onTap: () => _showFullImage(imageUrl),
                        onLongPress: () => _deletePhoto(imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                          ),
                        ),
                      );
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
}
*/

/*import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({Key? key}) : super(key: key);

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  List<String> galleryImages = [];
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    setState(() => isLoading = true);
    try {
      final images = await _apiService.getGallery(globals.kullaniciTCKN);
      setState(() {
        galleryImages = images;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Galeri yüklenemedi: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      /*final List<File>? pickedFiles = (await _picker.pickMultiImage()).cast<File>();
      if (pickedFiles == null || pickedFiles.isEmpty) return;

      setState(() => isUploading = true);
      //await _apiService.uploadGalleryImages(pickedFiles);
      await _apiService.uploadGallery(globals.kullaniciTCKN, pickedFiles);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fotoğraflar yüklendi")),
      );*/
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(); // List<XFile>

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        // XFile -> File dönüşümü
        List<File> files = pickedFiles.map((xfile) => File(xfile.path)).toList();

        bool success = await ApiService().uploadGallery(globals.kullaniciTCKN, files);
        if (success) {
          print("Fotoğraflar başarıyla yüklendi.");
        } else {
          print("Yükleme başarısız.");
        }
      }

      _loadGalleryImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraf yükleme hatası: $e")),
      );
    } finally {
      setState(() => isUploading = false);
    }
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
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
                /*ElevatedButton.icon(
                  onPressed: isUploading ? null : _pickAndUploadImages,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(
                    isUploading ? "Yükleniyor..." : "Fotoğraf Ekle",
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56), // yükseklik
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // köşeleri yuvarlak
                    ),
                  ),
                ),*/
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity, // tam genişlik
                    child: ElevatedButton.icon(
                      onPressed: isUploading ? null : _pickAndUploadImages,
                      icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
                      label: const Text(
                        "Fotoğraf Ekle",
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white, // arka plan beyaz
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : galleryImages.isEmpty
                      ? const Center(child: Text("Henüz fotoğraf yok"))
                      : GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = galleryImages[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                        ),
                      );
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
}*/
