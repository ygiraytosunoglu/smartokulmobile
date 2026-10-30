import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../constants.dart';
import '../screens/video_player_screen.dart';
import '../services/api_service.dart';
import '../utils/chat_attachment.dart';

class ChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> mesaj;
  final bool benim;
  final bool isGroup;
  final String tckn;
  final bool showDateHeader;
  final bool showSenderName;

  const ChatMessageBubble({
    super.key,
    required this.mesaj,
    required this.benim,
    required this.tckn,
    this.isGroup = false,
    this.showDateHeader = false,
    this.showSenderName = false,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  late String _url;
  bool _urlYenileniyor = false;

  @override
  void initState() {
    super.initState();
    _url = (widget.mesaj['DosyaUrl'] ?? '').toString();
  }

  @override
  void didUpdateWidget(covariant ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = (widget.mesaj['DosyaUrl'] ?? '').toString();
    if (next.isNotEmpty && next != _url) _url = next;
  }

  bool get _hasAtt =>
      widget.mesaj['HasAttachment'] == true ||
      (_url.isNotEmpty) ||
      ((widget.mesaj['_localPath'] ?? '').toString().isNotEmpty);

  String get _ekTuru {
    final t = (widget.mesaj['EkTuru'] ?? '').toString().toLowerCase();
    if (t.isNotEmpty) return t;
    final path = (widget.mesaj['_localPath'] ?? widget.mesaj['DosyaAdi'] ?? '')
        .toString();
    return path.isEmpty ? '' : ekTuruFromPath(path);
  }

  Future<void> _yenileUrl() async {
    if (_urlYenileniyor) return;
    final id = widget.mesaj['Id'];
    final mesajId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (mesajId == null) return;
    _urlYenileniyor = true;
    try {
    final refreshed = await ApiService.getAttachmentUrl(
      mesajId: mesajId,
      tckn: widget.tckn,
      isGroup: widget.isGroup,
    );
    final url = (refreshed?['url'] ?? '').toString();
    if (url.isNotEmpty && mounted) {
      setState(() {
        _url = url;
        widget.mesaj['DosyaUrl'] = url;
      });
    }
    } finally {
      _urlYenileniyor = false;
    }
  }

  Future<void> _acBelge() async {
    var url = _url;
    if (url.isEmpty) {
      await _yenileUrl();
      url = _url;
    }
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    try {
      final dir = await getTemporaryDirectory();
      final name = (widget.mesaj['DosyaAdi'] ?? 'dosya').toString();
      final savePath = '${dir.path}/$name';
      final r = await http.get(Uri.parse(url));
      if (r.statusCode == 200) {
        await File(savePath).writeAsBytes(r.bodyBytes);
        await OpenFilex.open(savePath);
      } else if (r.statusCode == 401 || r.statusCode == 403) {
        await _yenileUrl();
      }
    } catch (_) {
      await _yenileUrl();
    }
  }

  @override
  Widget build(BuildContext context) {
    final benim = widget.benim;
    final text = (widget.mesaj['Data'] ?? '').toString();
    final gonderenAdi = (widget.mesaj['GonderenAdi'] ?? '').toString();
    final saat = chatSaat(widget.mesaj);
    final uploading = widget.mesaj['_uploading'] == true;
    final timeColor = benim ? Colors.white70 : Colors.black54;

    return Column(
      children: [
        if (widget.showDateHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chatGunEtiketi(widget.mesaj),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
        Align(
          alignment: benim ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: benim ? AppColors.primary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment:
                  benim ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (widget.showSenderName && gonderenAdi.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      gonderenAdi,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                if (_hasAtt) _ekWidget(benim),
                if (uploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, bottom: 4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: _hasAtt ? 6 : 0),
                    child: Linkify(
                      text: text,
                      style: TextStyle(
                        color: benim ? Colors.white : Colors.black87,
                      ),
                      onOpen: (link) async {
                        final uri = Uri.parse(
                          link.url.startsWith('http')
                              ? link.url
                              : 'https://${link.url}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ),
                if (saat.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        saat,
                        style: TextStyle(fontSize: 11, color: timeColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ekWidget(bool benim) {
    final local = (widget.mesaj['_localPath'] ?? '').toString();
    final tur = _ekTuru;
    if (tur == 'image') {
      return _imageEk(local);
    }
    if (tur == 'video') {
      return _videoEk(local);
    }
    if (tur == 'audio') {
      return _ChatAudioPlayer(url: _url, localPath: local, mine: benim);
    }
    return _belgeEk(benim);
  }

  Widget _imageEk(String local) {
    Widget img;
    if (local.isNotEmpty) {
      img = Image.file(File(local), fit: BoxFit.cover);
    } else if (_url.isNotEmpty) {
      img = CachedNetworkImage(
        imageUrl: _url,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _yenileUrl();
          });
          return IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _yenileUrl,
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        if (local.isEmpty && _url.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(backgroundColor: Colors.black),
              backgroundColor: Colors.black,
              body: PhotoView(
                imageProvider: local.isNotEmpty
                    ? FileImage(File(local))
                    : CachedNetworkImageProvider(_url),
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 220, height: 180, child: img),
      ),
    );
  }

  Widget _videoEk(String local) {
    return GestureDetector(
      onTap: () {
        if (local.isNotEmpty) {
          OpenFilex.open(local);
          return;
        }
        if (_url.isEmpty) {
          _yenileUrl();
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(videoUrl: _url),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 220,
          height: 140,
          color: Colors.black26,
          child: const Center(
            child: Icon(Icons.play_circle_fill, size: 56, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _belgeEk(bool benim) {
    final name = (widget.mesaj['DosyaAdi'] ?? 'Dosya').toString();
    final rawBoyut = widget.mesaj['DosyaBoyut'];
    final size = formatDosyaBoyut(
      rawBoyut is int ? rawBoyut : int.tryParse(rawBoyut?.toString() ?? ''),
    );
    final color = benim ? Colors.white : Colors.black87;
    return InkWell(
      onTap: _acBelge,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                if (size.isNotEmpty)
                  Text(size, style: TextStyle(fontSize: 11, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAudioPlayer extends StatefulWidget {
  final String url;
  final String localPath;
  final bool mine;

  const _ChatAudioPlayer({
    required this.url,
    required this.localPath,
    required this.mine,
  });

  @override
  State<_ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<_ChatAudioPlayer> {
  VideoPlayerController? _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _ChatAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.localPath != widget.localPath) {
      _c?.dispose();
      _c = null;
      _ready = false;
      _init();
    }
  }

  String _sureYazi(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _init() async {
    try {
      if (widget.localPath.isNotEmpty) {
        _c = VideoPlayerController.file(File(widget.localPath));
      } else if (widget.url.isNotEmpty) {
        _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      } else {
        return;
      }
      await _c!.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.mine ? Colors.white : Colors.black87;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _c?.value.isPlaying == true ? Icons.pause : Icons.play_arrow,
            color: color,
          ),
          onPressed: !_ready
              ? null
              : () {
                  setState(() {
                    if (_c!.value.isPlaying) {
                      _c!.pause();
                    } else {
                      _c!.play();
                    }
                  });
                },
        ),
        Text(
          _ready ? _sureYazi(_c!.value.duration) : '--:--',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}
