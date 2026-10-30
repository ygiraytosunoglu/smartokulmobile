import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/grup_mesaj_detay_screen.dart';
import 'package:smart_okul_mobile/screens/mesaj_detay_screen.dart';
import '../constants.dart';
import '../models/conversation_item.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class MesajAnaScreen extends StatefulWidget {
  final String tckn;

  const MesajAnaScreen({
    Key? key,
    required this.tckn,
  }) : super(key: key);

  @override
  State<MesajAnaScreen> createState() => _MesajAnaScreenState();
}

class _MesajAnaScreenState extends State<MesajAnaScreen> {
  List<ConversationItem> conversations = [];
  bool isLoading = true;
  bool _contactsLoading = false;
  final TextEditingController _aramaCtrl = TextEditingController();
  String _arama = '';

  bool get _contactsIsteniyor =>
      globals.globalKullaniciTipi == 'T' ||
      globals.globalKullaniciTipi == 'M';

  @override
  void initState() {
    super.initState();
    _loadConversationList();
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  List<ConversationItem> get _gorunenKonusmalar {
    final q = _arama.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations.where((c) {
      final name = c.name.toLowerCase();
      final student = (c.studentName ?? '').toLowerCase();
      return name.contains(q) || student.contains(q);
    }).toList();
  }

  ConversationItem? _parseItem(dynamic raw) {
    if (raw is! Map) return null;
    return ConversationItem.fromJson(Map<String, dynamic>.from(raw));
  }

  String _tcknKey(String? tckn) {
    if (tckn == null || tckn.isEmpty) return '';
    return tckn.split('_').first;
  }

  List<ConversationItem> _contactsIleBirles(
    List<ConversationItem> mevcut,
    List<ConversationItem> contacts,
  ) {
    final seen = <String>{
      for (final c in mevcut)
        if (!c.isGroup) _tcknKey(c.tckn),
    }..remove('');

    final ekler = <ConversationItem>[];
    for (final c in contacts) {
      final key = _tcknKey(c.tckn);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      ekler.add(c);
    }
    ekler.sort((a, b) => a.name.compareTo(b.name));
    return [...mevcut, ...ekler];
  }

  Future<void> _loadConversationList() async {
    try {
      final sohbetFuture = ApiService.getConversationList(widget.tckn);
      final contactsFuture = _contactsIsteniyor
          ? ApiService.getMessageableContacts(widget.tckn)
          : Future<List<ConversationItem>>.value(const []);

      final data = await sohbetFuture;
      final parsed =
          data.map(_parseItem).whereType<ConversationItem>().toList();

      if (!mounted) return;
      setState(() {
        conversations = parsed;
        isLoading = false;
        _contactsLoading = _contactsIsteniyor;
      });
      globals.mesajVar.value = conversations.any((c) => c.isUnread);

      final contacts = await contactsFuture;
      if (!mounted || !_contactsIsteniyor) return;
      setState(() {
        conversations = _contactsIleBirles(conversations, contacts);
        _contactsLoading = false;
      });
    } catch (e) {
      debugPrint("Conversation list error: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _contactsLoading = false;
      });
    }
  }

  String _avatarLetter(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  Future<void> _konusmayiAc(ConversationItem item) async {
    if (item.isGroup) {
      final groupId = item.groupId;
      if (groupId == null) return;

      if (item.isUnread) {
        await ApiService().markGroupAsRead(
          grupId: groupId,
          tckn: widget.tckn,
        );
        setState(() {
          final i = conversations.indexOf(item);
          if (i != -1) {
            conversations[i] = ConversationItem(
              isGroup: true,
              groupId: groupId,
              tckn: item.tckn,
              name: item.name,
              studentName: item.studentName,
              isRead: 1,
              lastMessageDate: item.lastMessageDate,
            );
          }
        });
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GrupMesajDetayScreen(
            groupId: groupId,
            groupName: item.name.isEmpty ? 'Grup' : item.name,
            tckn: widget.tckn,
          ),
        ),
      );
    } else {
      final tckn = item.tckn;
      if (tckn == null || tckn.isEmpty) return;

      try {
        if (item.isUnread) {
          await ApiService().setMesajOkundu(
            globals.kullaniciTCKN,
            tckn,
          );
          setState(() {
            final i = conversations.indexOf(item);
            if (i != -1) {
              conversations[i] = ConversationItem(
                isGroup: false,
                groupId: item.groupId,
                tckn: tckn,
                name: item.name,
                studentName: item.studentName,
                isRead: 1,
                lastMessageDate: item.lastMessageDate,
              );
            }
          });
        }
      } catch (e) {
        debugPrint("Mesaj okundu işaretleme hatası: $e");
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MesajDetayScreen(
            tckn: widget.tckn,
            alanTckn: tckn,
            alanAdi: item.name,
          ),
        ),
      );
    }

    _loadConversationList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.messagesTitle,
          style: AppStyles.titleLarge,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withOpacity(0.8),
              AppColors.background.withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                controller: _aramaCtrl,
                onChanged: (v) => setState(() => _arama = v),
                decoration: InputDecoration(
                  hintText: 'Ara',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _arama.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _aramaCtrl.clear();
                            setState(() => _arama = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            if (_contactsLoading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : conversations.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.noMessagesYet,
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : _gorunenKonusmalar.isEmpty
                          ? const Center(
                              child: Text(
                                'Sonuç bulunamadı',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : RefreshIndicator(
                    onRefresh: _loadConversationList,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: StickyWarningHeader(),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(12),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _gorunenKonusmalar[index];
                                final okunmamis = item.isUnread;
                                final title = item.name.isEmpty
                                    ? (item.isGroup ? 'Grup' : '')
                                    : item.name;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _konusmayiAc(item),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: okunmamis
                                            ? AppColors.primary
                                                .withOpacity(0.08)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.primary,
                                          child: item.isGroup
                                              ? const Icon(
                                                  Icons.groups,
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  _avatarLetter(title),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                        title: Text(
                                          title,
                                          style: TextStyle(
                                            fontWeight: okunmamis
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: item.studentName != null
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Text(
                                                  item.studentName!,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: okunmamis
                                                        ? AppColors.primary
                                                        : Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              )
                                            : item.isGroup
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4),
                                                    child: Text(
                                                      'Grup sohbeti',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (okunmamis)
                                              Container(
                                                width: 10,
                                                height: 10,
                                                margin: const EdgeInsets.only(
                                                    right: 8),
                                                decoration: const BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _gorunenKonusmalar.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class StickyWarningHeader extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 45;

  @override
  double get maxExtent => 45;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      alignment: Alignment.center,
      color: Colors.red.withOpacity(0.08),
      child: Text(
        AppLocalizations.of(context)!.conversationWarning,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
