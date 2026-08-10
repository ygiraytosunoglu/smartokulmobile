import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// Sunucudan gelen hata mesajını yerelleştirilmiş metne çevirir.
///
/// - Mesaj `ERR_` ile başlıyorsa: AppLocalizations'taki karşılığını döner.
///   Eşleşme bulunamazsa mesajı aynen döner.
/// - `Exception: ERR_...` gibi Flutter exception sarmalı da tanınır.
/// - `ERR_` ile başlamıyorsa: mesajı aynen döner.
String translateError(String message, BuildContext context) {
  // Flutter exception sarmalını çıkar: "Exception: ERR_FOO" → "ERR_FOO"
  String cleaned = message.trim();
  if (cleaned.startsWith('Exception: ')) {
    cleaned = cleaned.substring('Exception: '.length).trim();
  }

  if (!cleaned.startsWith('ERR_')) return message;

  final l = AppLocalizations.of(context);
  if (l == null) return message;

  final key = cleaned;

  switch (key) {
    case 'ERR_KULLANICI_NO_ZORUNLU':         return l.errKullaniciNoZorunlu;
    case 'ERR_KULLANICI_NO_11_HANE':         return l.errKullaniciNo11Hane;
    case 'ERR_KULLANICI_NO_AYNI_RAKAM':      return l.errKullaniciNoAyniRakam;
    case 'ERR_KAYIT_BULUNAMADI':             return l.errKayitBulunamadi;
    case 'ERR_SIFRE_KILIDI_LISTESINDE_DEGIL':return l.errSifreKilidiListesindeDegil;
    case 'ERR_SIFRE_SON_4_HANE_GUNCELLENDI': return l.errSifreSon4HaneGuncellendi;
    case 'ERR_KAYIT_OKULA_AIT_DEGIL':        return l.errKayitOkulaAitDegil;
    case 'ERR_TCKN_SIFRE_HATALI':            return l.errTcknSifreHatali;
    case 'ERR_TCKN_SIFRE_TIP_HATALI':        return l.errTcknSifreTipHatali;
    case 'ERR_KULLANICI_KILITLENDI':         return l.errKullaniciKilitlendi;
    case 'ERR_LISANS_DOLMUS':                return l.errLisansDolmus;
    case 'ERR_DOGRULAMA_BASARILI':           return l.errDogrulamaBasarili;
    case 'ERR_KISI_BULUNAMADI':              return l.errKisiBulunamadi;
    case 'ERR_KISI_GUNCELLENDI':             return l.errKisiGuncellendi;
    case 'ERR_OKUL_BULUNAMADI':              return l.errOkulBulunamadi;
    case 'ERR_OKUL_SILME_HATASI':            return l.errOkulSilmeHatasi;
    case 'ERR_GONDEREN_KISI_BULUNAMADI':     return l.errGonderenKisiBulunamadi;
    case 'ERR_SINIFLARDA_OGRENCI_YOK':       return l.errSiniflardaOgrenciYok;
    case 'ERR_IC_SUNUCU_HATASI':             return l.errIcSunucuHatasi;
    case 'ERR_MESAJ_ALICI_YOK':              return l.errMesajAliciYok;
    case 'ERR_MESAJ_GONDERILDI':             return l.errMesajGonderildi;
    case 'ERR_ALAN_STUDENT_TEACHER_YOK':     return l.errAlanStudentTeacherYok;
    case 'ERR_MESAJ_KISI_EKLENMEDI':         return l.errMesajKisiEklenmedi;
    case 'ERR_DUYURU_ALICI_YOK':             return l.errDuyuruAliciYok;
    case 'ERR_DUYURU_GONDERILDI':            return l.errDuyuruGonderildi;
    case 'ERR_GELISIM_TIPI_EKLENDI':         return l.errGelisimTipiEklendi;
    case 'ERR_DUYURU_KISI_EKLENMEDI':        return l.errDuyuruKisiEklenmedi;
    case 'ERR_GELISIM_TIPI_BULUNAMADI':      return l.errGelisimTipiBulunamadi;
    case 'ERR_GELISIM_TIPI_SILINDI':         return l.errGelisimTipiSilindi;
    case 'ERR_GELISIM_TIPI_OKULA_AIT_DEGIL': return l.errGelisimTipiOkulaAitDegil;
    case 'ERR_GELISIM_KAYIT_EKLENDI':        return l.errGelisimKayitEklendi;
    case 'ERR_GELISIM_KAYIT_BULUNAMADI':     return l.errGelisimKayitBulunamadi;
    case 'ERR_GELISIM_KAYIT_GUNCELLENDI':    return l.errGelisimKayitGuncellendi;
    case 'ERR_GELISIM_KAYIT_SILINDI':        return l.errGelisimKayitSilindi;
    case 'ERR_OGRENCI_BULUNAMADI':           return l.errOgrenciBulunamadi;
    case 'ERR_DESTEKLENMEYEN_ILISKI':        return l.errDesteklenmeyenIliski;
    case 'ERR_ALAN_KISI_BULUNAMADI':         return l.errAlanKisiBulunamadi;
    case 'ERR_TCKN_PARENT_DEGIL':            return l.errTcknParentDegil;
    case 'ERR_PARENT_OKUL_ID_YOK':           return l.errParentOkulIdYok;
    case 'ERR_PARENT_STUDENT_YOK':           return l.errParentStudentYok;
    case 'ERR_TCKN_BULUNAMADI':              return l.errTcknBulunamadi;
    case 'ERR_PERSON_OKUL_ID_YOK':           return l.errPersonOkulIdYok;
    case 'ERR_OTP_GECERSIZ':                 return l.errOtpGecersiz;
    case 'ERR_PERSON_SINIF_ID_YOK':          return l.errPersonSinifIdYok;
    case 'ERR_TCKN_LISTESI_BOS':             return l.errTcknListesiBos;
    case 'ERR_OLCEK_ZATEN_TANIMLI':          return l.errOlcekZatenTanimli;
    case 'ERR_PERSON_OKUL_ATANMAMIS':        return l.errPersonOkulAtanmamis;
    case 'ERR_TUM_SORULAR_CEVAPLANMALI':     return l.errTumSorularCevaplanmali;
    case 'ERR_EKSIK_SORU_CEVAP':             return l.errEksikSoruCevap;
    case 'ERR_GECERSIZ_SORU_CEVAP':          return l.errGecersizSoruCevap;
    case 'ERR_MIN_DEGER_MAX_DEGERDEN_BUYUK': return l.errMinDegerMaxDegerdenBuyuk;
    case 'ERR_TCKN_ZORUNLU':                 return l.errTcknZorunlu;
    case 'ERR_OGRENCI_HOSTES_ILISKISI_YOK':  return l.errOgrenciHostesIliskisiYok;
    case 'ERR_PIN_ENCRYPTION_KEY_YOK':       return l.errPinEncryptionKeyYok;
    case 'ERR_PIN_ENCRYPTION_KEY_UZUNLUK':   return l.errPinEncryptionKeyUzunluk;
    case 'ERR_PIN_ENC_BOS':                  return l.errPinEncBos;
    case 'ERR_PIN_ENC_FORMAT':               return l.errPinEncFormat;
    case 'ERR_PIN_ENC_UZUNLUK':              return l.errPinEncUzunluk;
    default:                                 return message;
  }
}

/// Servis cevabındaki `message` alanını güvenli şekilde çıkarır
/// ve eğer ERR_ kodu ise yerelleştirir.
///
/// Kullanım:
/// ```dart
/// final msg = extractAndTranslate(result['message'], context);
/// ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
/// ```
String extractAndTranslate(dynamic rawMessage, BuildContext context) {
  final message = rawMessage?.toString() ?? '';
  return translateError(message, context);
}
