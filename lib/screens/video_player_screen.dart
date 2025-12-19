import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  Timer? _hideTimer;

  get videoUrl => null;
  @override
  void initState() {
    super.initState();


    // Ekran döndürme = sensör serbest
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    print("controller initState");

    print("controller initState");
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        print("vps initState 1");
       /* Future.delayed(const Duration(seconds: 3), () {
          print("3 saniye geçti");
          // Buraya 3 sn sonra çalışmasını istediğin kodu yaz
        });*/
        _controller.pause();
        _controller.setLooping(false); // <-- Döngüyü kapatır
       /* Future.delayed(const Duration(seconds: 3), () {
          print("3 saniye geçti");
          // Buraya 3 sn sonra çalışmasını istediğin kodu yaz
        });*/
        print("vps initState 2");

        setState(() {});
        print("vps initState 3");
       // _controller.play();
      });

    //_startHideTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startHideTimer();
    });
  }

  Future<void> _downloadVideo() async {
    try {
      print("download video");

      final tempDir = await getTemporaryDirectory();
      print("tempDir:"+tempDir.toString());
      final filePath ="${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4";
      print("filePath url:"+filePath);
      print("videoUrl:"+widget.videoUrl);
      var response = await http.get(Uri.parse(widget.videoUrl));
      print("resp:"+response.toString());
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      print("write sonrasi");
      await GallerySaver.saveVideo(file.path);
      print("save sonrasi");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(
        content: Text(
        'Video kaydedildi',
        style: TextStyle(color: Colors.white),
      ),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
          content: Text("Hata: Vide KAYDEDİLEMEDİ",
              style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      )

      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    print("build video player");

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [

            // -------------------------
            // 1) ÜST BAR (Kapat + İndir)
            // -------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white, size: 30),
                  onPressed: _downloadVideo,
                ),
              ],
            ),

            // -----------------------------------------------------
            // 2) ORTA: VİDEO (tüm alanı kaplasın, sağlam FittedBox)
            // -----------------------------------------------------
            Expanded(
              child: Center(
                child: _controller.value.isInitialized
                    ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),

            // -------------------------
            // 3) ALT BAR (progress + kontrol)
            // -------------------------
            Column(
              children: [
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10,
                          color: Colors.white, size: 32),
                      onPressed: () {
                        final pos = _controller.value.position -
                            const Duration(seconds: 10);
                        _controller.seekTo(pos);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10,
                          color: Colors.white, size: 32),
                      onPressed: () {
                        final pos = _controller.value.position +
                            const Duration(seconds: 10);
                        _controller.seekTo(pos);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }


}

/*import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    // Tam ekran moduna alın
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Ekranı her iki yatay moda zorla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _startHideTimer();
  }

  @override
  void dispose() {
    _controller.dispose();

    // Eski dikey moda geri döndür
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startHideTimer();
    });
  }

  Future<void> _downloadVideo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4";

      var response = await http.get(Uri.parse(widget.videoUrl));
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await GallerySaver.saveVideo(file.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video galeriye kaydedildi")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İndirme Hatası: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // ÜST KONTROL BAR
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white, size: 30),
                        onPressed: _downloadVideo,
                      ),
                    ],
                  ),
                ),
              ),

            // ALT KONTROL BAR
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Progress bar
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                            onPressed: () {
                              final pos = _controller.value.position - const Duration(seconds: 10);
                              _controller.seekTo(pos);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                            onPressed: () {
                              final pos = _controller.value.position + const Duration(seconds: 10);
                              _controller.seekTo(pos);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}*/