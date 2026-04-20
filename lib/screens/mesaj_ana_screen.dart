import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/mesaj_detay_screen.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class MesajAnaScreen extends StatefulWidget {
  final String tckn; // 👈 PARAMETRE

  const MesajAnaScreen({
    Key? key,
    required this.tckn,
  }) : super(key: key);


  @override
  State<MesajAnaScreen> createState() => _MesajAnaScreenState();
}

class _MesajAnaScreenState extends State<MesajAnaScreen> {
  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversationList();
  }

  Future<void> _loadConversationList() async {
    try {
      final data =
      await ApiService.getConversationList(widget.tckn);

      setState(() {
        conversations = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });

      // Okunmamış mesaj yoksa home_screen'deki kırmızı çerçeveyi kaldır
      final hasUnread = conversations.any((c) => (c['isRead'] ?? 1) == 0);
      globals.mesajVar.value = hasUnread;
    } catch (e) {
      debugPrint("Conversation list error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Mesaj açılınca: okundu yap + detay sayfasına git
  Future<void> mesajSayfasiniGetir(String tckn, String name) async {
    try {
      final index =
      conversations.indexWhere((e) => e['TCKN'] == tckn);

      if (index != -1 && conversations[index]['isRead'] == 0) {
        await ApiService().setMesajOkundu(
          globals.kullaniciTCKN, // gonderenTckn
          tckn // alanTckn
        );

        setState(() {
          conversations[index]['isRead'] = 1;
        });
      }
    } catch (e) {
      debugPrint("Mesaj okundu işaretleme hatası: $e");
    }

    // 👉 Detay ekranına git
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesajDetayScreen(
          tckn:widget.tckn,
          alanTckn: tckn,
          alanAdi: name,
        ),
      ),
    );

    // 👉 GERİ GELİNCE otomatik refresh
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
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : conversations.isEmpty
            ? Center(
          child: Text(
            AppLocalizations.of(context)!.noMessagesYet,
            style: TextStyle(fontSize: 16),
          ),
        )
            : CustomScrollView(
          slivers: [

            /// ✅ STICKY WARNING
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyWarningHeader(),
            ),

            /// ✅ MESAJ LİSTESİ
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = conversations[index];
                    final bool okunmamis =
                        item['isRead'] == 0;

                    return Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        borderRadius:
                        BorderRadius.circular(16),
                        onTap: () => mesajSayfasiniGetir(
                          item['TCKN'],
                          item['Name'],
                        ),
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
                                color: Colors.black
                                    .withOpacity(0.1),
                                blurRadius: 6,
                                offset:
                                const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                              AppColors.primary,
                              child: Text(
                                item['Name']
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item['Name'],
                              style: TextStyle(
                                fontWeight: okunmamis
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: item['StudentName'] !=
                                null &&
                                item['StudentName']
                                    .toString()
                                    .isNotEmpty
                                ? Padding(
                              padding:
                              const EdgeInsets
                                  .only(top: 4),
                              child: Text(
                                item['StudentName'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: okunmamis
                                      ? AppColors
                                      .primary
                                      : Colors.grey
                                      .shade600,
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                              ),
                            )
                                : null,
                            trailing: Row(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                if (okunmamis)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin:
                                    const EdgeInsets
                                        .only(right: 8),
                                    decoration:
                                    const BoxDecoration(
                                      color: Colors.blue,
                                      shape:
                                      BoxShape.circle,
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
                  childCount: conversations.length,
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
      child:  Text(
        AppLocalizations.of(context)!.conversationWarning,
        style: TextStyle(
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