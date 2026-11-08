// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Smart Okul';

  @override
  String get userCode => 'Kullanıcı No';

  @override
  String get login => 'Giriş';

  @override
  String get userType => 'Kullanıcı Tipi';

  @override
  String get password => 'Şifre';

  @override
  String get enter => 'Giriş Yap';

  @override
  String get galleries => 'Galeriler';

  @override
  String get welcome => 'Hoşgeldiniz';

  @override
  String get err => 'Hata';

  @override
  String get userEmpty => 'Kullanıcı No boş bırakılamaz';

  @override
  String get userLength => 'Kullanıcı No 11 haneli olmalıdır';

  @override
  String get userHint => '11 haneli Kullanıcı No giriniz';

  @override
  String get pswHint => 'Şifrenizi giriniz';

  @override
  String get pswEmpty => 'Şifre boş bırakılamaz';

  @override
  String get teacher => 'Öğretmen';

  @override
  String get parent => 'Veli';

  @override
  String get manager => 'Yönetici';

  @override
  String get hostes => 'Hostes';

  @override
  String get enterLoading => 'Giriş Yapılıyor...';

  @override
  String get enterError => 'Bir hata oluştu. Tekrar deneyin.';

  @override
  String get pswForget => 'Şifremi Unuttum';

  @override
  String get messages => 'MESAJLAR';

  @override
  String get gallery => 'GALERİ';

  @override
  String get notification => 'ANONS';

  @override
  String get profile => 'PROFİL';

  @override
  String get anouncement => 'DUYURULAR';

  @override
  String get attendance => 'DEVAM BİLGİSİ';

  @override
  String get medicine => 'İLAÇ';

  @override
  String get gateControl => 'KAPI KONTROL';

  @override
  String get activities => 'ETKİNLİKLER';

  @override
  String get daily => 'GÜNLÜK';

  @override
  String get mealList => 'YEMEK LİSTESİ';

  @override
  String get survey => 'ANKETLER';

  @override
  String get qrCode => 'KAREKOD';

  @override
  String get homework => 'ÖDEV';

  @override
  String get privateLesson => 'ÖZEL DERS';

  @override
  String get tutoring => 'ETÜT';

  @override
  String get schoolLessons => 'OKUL DERSLERİ';

  @override
  String get studentNotification => 'Öğrenci Anons';

  @override
  String get notification1 => 'Bıraktım';

  @override
  String get notification2 => 'Yaklaştım';

  @override
  String get notification3 => 'Aldım';

  @override
  String get notification4 => 'Geldim';

  @override
  String get mainScreen => 'Ana Sayfa';

  @override
  String get studentLengthMsg => 'En az bir öğrenci seçilmelidir';

  @override
  String get notificationSuccessMsg => 'Bildirim gönderildi';

  @override
  String get notificationFailMsg => 'Bildirim gönderilemedi';

  @override
  String get announcementListTitle => 'Duyuru Listesi';

  @override
  String get announcementDetailTitle => 'Duyuru Detayı';

  @override
  String get announcementCopied => 'Duyuru kopyalandı';

  @override
  String get newAnnouncement => 'Yeni Duyuru';

  @override
  String get sendAnnouncement => 'Duyuru Gönder';

  @override
  String get sendingAnnouncement => 'Duyuru Gönderiliyor...';

  @override
  String get announcementTitleLabel => 'Duyuru Başlığı';

  @override
  String get announcementMessageLabel => 'Duyuru Mesajı';

  @override
  String get titleRequired => 'Başlık gerekli';

  @override
  String get messageRequired => 'Mesaj gerekli';

  @override
  String get announcementSentSuccess => 'Duyuru(lar) başarıyla gönderildi';

  @override
  String get fillFieldsSelectStudent =>
      'Lütfen tüm alanları doldurun ve öğrenci seçin';

  @override
  String get fillFieldsSelectClass =>
      'Lütfen tüm alanları doldurun ve sınıf seçin';

  @override
  String get selectTeacherPlease => 'Lütfen bir öğretmen seçin';

  @override
  String get enterTitleAndMessage => 'Lütfen başlık ve mesaj girin';

  @override
  String get senderLabel => 'Gönderen';

  @override
  String get onlyTeachersAdminsCanNotify =>
      'Sadece öğretmenler ve yöneticiler velilere bildirim gönderebilir!';

  @override
  String get teachersTitle => 'Öğretmenler';

  @override
  String get teacherNotFound => 'Öğretmen bulunamadı';

  @override
  String get unnamedTeacher => 'İsimsiz Öğretmen';

  @override
  String get parentMessages => 'Veli Mesajlaşmaları';

  @override
  String get messagesTitle => 'Mesajlar';

  @override
  String get noMessagesYet => 'Henüz mesaj yok';

  @override
  String get conversationWarning =>
      '* Konuşma metni okul yönetimi gözetimindedir';

  @override
  String get galleryTitle => 'Galeri';

  @override
  String get studentListNotLoaded => 'Öğrenci listesi yüklenmedi';

  @override
  String get selectStudentsTitle => 'Gönderilecek Öğrenciler';

  @override
  String get selectAll => 'Hepsi';

  @override
  String get cancel => 'İptal';

  @override
  String get contin => 'Devam';

  @override
  String get noStudentSelected => 'Öğrenci seçilmedi';

  @override
  String galleryLoadError(Object error) {
    return 'Galeri yüklenemedi: $error';
  }

  @override
  String get photoPermissionRequired => 'Fotoğraflara erişim izni gerekli';

  @override
  String get mediaSavedToGallery => 'Medya galeriye kaydedildi';

  @override
  String get mediaSaveFailed => 'Galeriye kaydetme başarısız';

  @override
  String errorMessage(Object error) {
    return 'Hata: $error';
  }

  @override
  String get deleteMediaTitle => 'Medya Sil';

  @override
  String get deleteMediaConfirm =>
      'Bu medya kalıcı olarak silinecek. Emin misiniz?';

  @override
  String get delete => 'Sil';

  @override
  String get mediaDeleted => 'Medya silindi';

  @override
  String deleteFailed(Object error) {
    return 'Silme başarısız: $error';
  }

  @override
  String get uploading => 'Yükleniyor...';

  @override
  String get addMedia => 'Medya Ekle';

  @override
  String get mealScreenTitle => 'Yemek Listesi';

  @override
  String get mealNotFound => 'Yemek listesi bulunamadı.';

  @override
  String get mealBreakfast => 'Kahvaltı:';

  @override
  String get mealLunch => 'Öğle:';

  @override
  String get mealSnack => 'İkindi:';

  @override
  String mealDateHeader(Object date) {
    return '$date';
  }

  @override
  String get profileTitle => 'Profil Sayfası';

  @override
  String get userInfoTitle => '👤 Kullanıcı Bilgileri';

  @override
  String get studentsTitle => '👧 Öğrenciler';

  @override
  String get attendanceTitle => 'Yoklama';

  @override
  String get parentInfoTitle => '👪 Veli Bilgileri';

  @override
  String get labelFullName => 'Ad Soyad:';

  @override
  String get labelProfession => 'Meslek:';

  @override
  String get labelHobby => 'Hobi:';

  @override
  String get labelPhone => 'Telefon:';

  @override
  String get close => 'Kapat';

  @override
  String get labelAllergy => 'Alerji:';

  @override
  String get labelMedicine => 'İlaç:';

  @override
  String get labelClass => 'Sınıfı:';

  @override
  String get labelSchoolNumber => 'Okul No:';

  @override
  String get qrOrCodeCreateTitle => 'Karekod / Kod Oluştur';

  @override
  String get receiverLabel => 'Alacak Kişi';

  @override
  String get receiverHint => 'Kişi adını giriniz';

  @override
  String get fieldRequired => 'Bu alan zorunludur';

  @override
  String get createQrButton => 'QR Oluştur';

  @override
  String get createCodeButton => 'Kod Oluştur';

  @override
  String get generatedResultTitle => 'Oluşturulan Sonuç';

  @override
  String get copyButton => 'Kopyala';

  @override
  String get copiedSnackBar => 'Kopyalandı';

  @override
  String get shareButton => 'Paylaş';

  @override
  String get qrVerifyTitle => 'QR / Kod Doğrulama';

  @override
  String get tabQrScan => 'QR Oku';

  @override
  String get tabManualCode => 'Kod Gir';

  @override
  String get cameraInstruction => 'Lütfen kamerayı bir QR koda doğru tutun';

  @override
  String get copiedToClipboard => 'Kod panoya kopyalandı';

  @override
  String get scanAgain => 'Tekrar Tara';

  @override
  String get otpLabel => 'OTP Kod';

  @override
  String get verifyButton => 'Doğrula';

  @override
  String get otpEmptyError => 'OTP boş olamaz';

  @override
  String get verifySuccessTitle => '✅ Kod Doğrulandı:';

  @override
  String get verifyInvalid => 'Kod Geçersiz';

  @override
  String verifyPersonLine(Object logName, Object personName) {
    return '• $logName - $personName';
  }

  @override
  String get attendanceStatusTitle => 'Devam Durumu';

  @override
  String get unknownStudent => 'Bilinmeyen';

  @override
  String get attendanceNotFound => 'Devam durumu bulunamadı.';

  @override
  String get attended => 'Devam etti';

  @override
  String get absent => 'Devamsız';

  @override
  String get medicineListTitle => 'İlaç Listesi';

  @override
  String get createNewMedicine => 'Yeni İlaç Oluştur';

  @override
  String get noMedicineYet => 'Henüz ilaç bilgisi yok.';

  @override
  String get medicineDetailTitle => 'İlaç Detayı';

  @override
  String get description => 'Açıklama';

  @override
  String get noDescription => 'Yok';

  @override
  String get ok => 'Tamam';

  @override
  String get create => 'Oluştur';

  @override
  String get creating => 'Oluşturuluyor...';

  @override
  String get createMedicineTitle => 'Yeni İlaç Bilgisi Oluştur';

  @override
  String get medicineStartDay => 'İlaç Başlangıç Günü';

  @override
  String get medicineEndDay => 'İlaç Bitiş Günü';

  @override
  String get medicineTime => 'İlaç Saati';

  @override
  String get selectStudent => 'Öğrenci Seçin:';

  @override
  String get fillAllDateFields => 'Tüm tarih alanlarını doldurunuz.';

  @override
  String get selectStudentError => 'Bir öğrenci seçmelisiniz.';

  @override
  String get medicineCreated => 'İlaç bilgisi başarıyla oluşturuldu.';

  @override
  String get deleteMedicineTitle => 'İlaç Kaydı Sil';

  @override
  String get deleteMedicineConfirm => 'Bu ilaç kaydı silinecek. Emin misiniz?';

  @override
  String get medicineDeactivated => 'İlaç kaydı silindi.';

  @override
  String get date => 'Tarih';

  @override
  String get student => 'Öğrenci';

  @override
  String get homeworkTitle => 'Ödevler';

  @override
  String get createHomework => 'Yeni Ödev Oluştur';

  @override
  String get noHomeworkYet => 'Henüz ödev yok.';

  @override
  String get homeworkDetailTitle => 'Ödev Detayı';

  @override
  String get lesson => 'Ders';

  @override
  String get search => 'Ara';

  @override
  String get noStudentsFound => 'Öğrenci bulunamadı';

  @override
  String get learningArea => 'Öğrenme Alanı';

  @override
  String get topic => 'Konu';

  @override
  String get learningAreaOptional => 'Öğrenme Alanı (opsiyonel)';

  @override
  String get topicOptional => 'Konu (opsiyonel)';

  @override
  String get learningAreaRequired => 'Öğrenme Alanı *';

  @override
  String get topicRequired => 'Konu *';

  @override
  String get dueDate => 'Son Teslim Tarihi';

  @override
  String get attachedFiles => 'Ekli Dosyalar';

  @override
  String get fileOpenError => 'Dosya açılamadı';

  @override
  String get file => 'Dosya';

  @override
  String get deleteHomeworkTitle => 'Ödev Sil';

  @override
  String get deleteHomeworkConfirm => 'Bu ödev silinecek. Emin misiniz?';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get homeworkDeleted => 'Ödev silindi';

  @override
  String get homeworkNotFound => 'Ödev bulunamadı';

  @override
  String get deleteError => 'Silme hatası';

  @override
  String get update => 'Değiştir';

  @override
  String get newHomeworkTitle => 'Yeni Ödev Oluştur';

  @override
  String get lessonRequired => 'Ders *';

  @override
  String get descriptionRequired => 'Açıklama *';

  @override
  String get dueDateRequired => 'Son Teslim Tarihi *';

  @override
  String get addFile => 'Dosya Ekle';

  @override
  String get save => 'Kaydet';

  @override
  String get fillRequiredFields => 'Zorunlu alanları doldurun';

  @override
  String get lessonDetail => 'Ödev Detayı';

  @override
  String get surveyListTitle => 'Anket Listesi';

  @override
  String get newSurvey => 'Yeni Anket Oluştur';

  @override
  String get noSurvey => 'Henüz anket bulunmuyor.';

  @override
  String get send => 'Gönder';

  @override
  String get answer => 'Cevap';

  @override
  String get unanswered => 'Cevaplanmamış';

  @override
  String get answerDetails => 'Cevap Detayları';

  @override
  String get noAnswer => 'Cevapsız';

  @override
  String get deleteConfirmTitle => 'Silme Onayı';

  @override
  String get deleteConfirmMessage =>
      'Bu etkinliği silmek istediğinize emin misiniz?';

  @override
  String get deleteSuccess => 'Aktivite silindi';

  @override
  String get deleteNoPermission => 'Silme yetkiniz yok';

  @override
  String get submitError => 'Cevap gönderilemedi';

  @override
  String get noTitle => 'Başlıksız';

  @override
  String get doorControlTitle => 'Kapı Kontrol Paneli';

  @override
  String get mainGateControl => 'Ana Kapı Kontrol';

  @override
  String get parkingControl => 'Otopark Kontrol';

  @override
  String get mainGateRequestSent => 'Ana Kapı açılma isteği gönderildi';

  @override
  String get mainGateRequestFailed => 'Ana kapı için istek gönderilemedi';

  @override
  String get parkingRequestSent => 'Otopark Kapısı açılma isteği gönderildi';

  @override
  String get parkingRequestFailed => 'Otopark için istek gönderilemedi';

  @override
  String get errorOccurred => 'Bir hata oluştu';

  @override
  String get notifyArrivalTitle => 'Geldiğimizi Bildir';

  @override
  String get attendanceSaved => 'Yoklamalar Kaydedildi';

  @override
  String get dailyInfoTitle => 'Günlük Bilgilendirme';

  @override
  String get studentDefaultName => 'Öğrenci';

  @override
  String get breakfast => 'Kahvaltı';

  @override
  String get lunch => 'Öğle';

  @override
  String get snack => 'İkindi';

  @override
  String get didNotEat => 'Yemedi';

  @override
  String get ateLittle => 'Az Yedi';

  @override
  String get ateAll => 'Tamamını Yedi';

  @override
  String get moodTitle => 'Duygu Durumu';

  @override
  String get sleepTitle => 'Uyku';

  @override
  String get moodHappy => 'Mutlu';

  @override
  String get moodSad => 'Üzgün';

  @override
  String get moodTired => 'Yorgun';

  @override
  String get moodPeaceful => 'Huzurlu';

  @override
  String get moodAngry => 'Sinirli';

  @override
  String get sleepNone => 'Uyumadı';

  @override
  String get sleepLittle => 'Az Uyudu';

  @override
  String get sleepSlept => 'Uyudu';

  @override
  String get studentNotFound => 'Öğrenci bulunamadı.';

  @override
  String get savedAll => 'Tüm bilgiler kaydedildi';

  @override
  String get saveError => 'Kaydetme hatası';

  @override
  String get plans => 'Planlar';

  @override
  String get monthly => 'Aylık';

  @override
  String get addPlan => 'Plan Ekle';

  @override
  String get fetch => 'Getir';

  @override
  String get noPlansYet => 'Henüz plan bulunamadı';

  @override
  String get planFound => ' plan bulundu.';

  @override
  String get planFetchError => 'Plan alınamadı';

  @override
  String get planUploadSuccess => 'Plan başarıyla yüklendi';

  @override
  String get planUploadError => 'Plan yüklenemedi';

  @override
  String get permissionPhotosRequired => 'Fotoğraflara erişim izni gerekli';

  @override
  String get planSavedToGallery => 'Plan kaydedildi';

  @override
  String get planSaveFailed => 'Plan kaydetme başarısız';

  @override
  String error(Object error) {
    return 'Hata: $error';
  }

  @override
  String get selectFileCanceled => 'Dosya seçilmedi';

  @override
  String get filePathError => 'Dosya yolu alınamadı';

  @override
  String get loading => 'Yükleniyor';

  @override
  String get activityListTitle => 'Etkinlik Listesi';

  @override
  String get activityDetailTitle => 'Etkinlik Detayı';

  @override
  String get newActivity => 'Yeni Etkinlik Oluştur';

  @override
  String get createActivity => 'Etkinlik Oluştur';

  @override
  String get activityDay => 'Etkinlik Günü';

  @override
  String get activityTime => 'Etkinlik Saati';

  @override
  String get activityPlace => 'Etkinlik Yeri';

  @override
  String get activityDescription => 'Açıklama';

  @override
  String get classes => 'Sınıflar';

  @override
  String get updating => 'Değiştiriliyor...';

  @override
  String get selectDayTime => 'Etkinlik gün ve saati seçiniz.';

  @override
  String get placeDescriptionEmpty => 'Etkinlik yeri ve açıklama boş olamaz.';

  @override
  String get selectAtLeastOneClass => 'En az bir sınıf seçmelisiniz.';

  @override
  String get fillAllFields => 'Tüm alanlar doldurulmalıdır';

  @override
  String get activityCreated => 'Etkinlik başarıyla oluşturuldu.';

  @override
  String get activityUpdated => 'Etkinlik güncellendi';

  @override
  String get activityDeleted => 'Aktivite silindi';

  @override
  String get activityCreateError => 'Etkinlik oluşturulamadı: ';

  @override
  String get activityUpdateError => 'Güncelleme hatası: ';

  @override
  String get activityDeleteError => 'Silme hatası: ';

  @override
  String get noDeletePermission => 'Silme yetkiniz yok';

  @override
  String get noActivityYet => 'Henüz etkinlik yok.';

  @override
  String get classLabel => 'Sınıf/lar';

  @override
  String get placeLabel => 'Yer';

  @override
  String get dateLabel => 'Tarih';

  @override
  String get edit => 'Düzenle';

  @override
  String get editActivity => 'Etkinliği Düzenle';

  @override
  String get guidance => 'Rehberlik';

  @override
  String get guidanceTitle => 'REHBERLİK';

  @override
  String get measurement => 'Ölçüm';

  @override
  String get guidanceResult => 'Ölçek Sonuç';

  @override
  String get fillForm => 'Form Doldur';

  @override
  String get getResult => 'Sonuç Getir';

  @override
  String get scaleResultGraph => 'Ölçek Sonuç Grafiği';

  @override
  String get result => 'Sonuç';

  @override
  String get resultNotFound => 'Test sonucu bulunamadı';

  @override
  String get gelisim => 'Gelişim';

  @override
  String get gelisimTitle => 'GELİŞİM';

  @override
  String get createGelisim => 'Yeni Kayıt Oluştur';

  @override
  String get allOfThem => 'Hepsi';

  @override
  String get growtType => 'Gelişim Tipi';

  @override
  String get newGrowth => 'Yeni Gelişim Kaydı';

  @override
  String get students => 'Öğrenciler';

  @override
  String get value => 'Değer';

  @override
  String get editGelisimTitle => 'Kayıt Düzenle / Sil';

  @override
  String get editGelisimButton => 'Kayıt Düzenle';

  @override
  String get recordsFetchError => 'Kayıtlar alınamadı';

  @override
  String get recordDeleted => 'Kayıt silindi';

  @override
  String get noRecordFound => 'Kayıt bulunamadı';

  @override
  String get gelisimDeleteConfirm =>
      'Bu gelişim kaydı kalıcı olarak silinecek. Emin misiniz?';

  @override
  String get noData => 'Veri yok';

  @override
  String get errKullaniciNoZorunlu => 'Kullanıcı No zorunludur.';

  @override
  String get errKullaniciNo11Hane =>
      'Kullanıcı No 11 hane ve sadece rakamlardan oluşmalıdır.';

  @override
  String get errKullaniciNoAyniRakam =>
      'Kullanıcı No içinde aynı rakam 8 veya daha fazla kez bulunamaz.';

  @override
  String get errKayitBulunamadi => 'Kayıt bulunamadı.';

  @override
  String get errSifreKilidiListesindeDegil =>
      'Bu kullanıcı şifre kilidi listesinde değil.';

  @override
  String get errSifreSon4HaneGuncellendi =>
      'Şifre telefon numarasının son 4 hanesi olarak güncellendi.';

  @override
  String get errKayitOkulaAitDegil =>
      'Kayıt bulunamadı veya bu okula ait değil.';

  @override
  String get errTcknSifreHatali => 'TCKN veya Şifre hatalı. Tekrar deneyiniz.';

  @override
  String get errTcknSifreTipHatali =>
      'TCKN, Şifre veya Kullanıcı Tipi hatalı. Tekrar deneyiniz.';

  @override
  String get errKullaniciKilitlendi =>
      'Kullanıcı kilitlendi. Çok fazla hatalı şifre denemesi yapıldı. Okul yöneticiniz ile görüşünüz.';

  @override
  String get errLisansDolmus =>
      'Lisansınız dolmuş. Okul yöneticiniz ile görüşünüz.';

  @override
  String get errDogrulamaBasarili => 'Doğrulama başarılı.';

  @override
  String get errKisiBulunamadi => 'Kişi bulunamadı.';

  @override
  String get errKisiGuncellendi => 'Kişi güncellendi.';

  @override
  String get errOkulBulunamadi => 'Okul bulunamadı.';

  @override
  String get errOkulSilmeHatasi =>
      'Okul silinirken hata oluştu. Okula bağlı veriler olabilir.';

  @override
  String get errGonderenKisiBulunamadi => 'Gönderen kişi bulunamadı.';

  @override
  String get errSiniflardaOgrenciYok =>
      'Belirtilen sınıflarda hiç öğrenci bulunamadı.';

  @override
  String get errIcSunucuHatasi => 'İç sunucu hatası.';

  @override
  String get errMesajAliciYok => 'Hiçbir alıcı bulunamadı, mesaj eklenmedi.';

  @override
  String get errMesajGonderildi => 'Mesaj başarıyla gönderildi.';

  @override
  String get errAlanStudentTeacherYok =>
      'Hiçbir alan student veya teacher bulunamadı.';

  @override
  String get errMesajKisiEklenmedi => 'Hiçbir kişiye mesaj eklenmedi.';

  @override
  String get errDuyuruAliciYok => 'Hiçbir alıcı bulunamadı, duyuru eklenmedi.';

  @override
  String get errDuyuruGonderildi => 'Duyuru başarıyla gönderildi.';

  @override
  String get errGelisimTipiEklendi => 'Gelişim tipi başarıyla eklendi.';

  @override
  String get errDuyuruKisiEklenmedi => 'Hiçbir kişiye duyuru eklenmedi.';

  @override
  String get errGelisimTipiBulunamadi => 'Gelişim tipi bulunamadı.';

  @override
  String get errGelisimTipiSilindi => 'Gelişim tipi başarıyla silindi.';

  @override
  String get errGelisimTipiOkulaAitDegil => 'Gelişim tipi bu okula ait değil.';

  @override
  String get errGelisimKayitEklendi => 'Gelişim kaydı başarıyla eklendi.';

  @override
  String get errGelisimKayitBulunamadi => 'Gelişim kaydı bulunamadı.';

  @override
  String get errGelisimKayitGuncellendi =>
      'Gelişim kaydı başarıyla güncellendi.';

  @override
  String get errGelisimKayitSilindi => 'Gelişim kaydı başarıyla silindi.';

  @override
  String get errOgrenciBulunamadi => 'Öğrenci bulunamadı.';

  @override
  String get errDesteklenmeyenIliski => 'Desteklenmeyen ilişki tipi.';

  @override
  String get errAlanKisiBulunamadi => 'Hiçbir alan kişi bulunamadı.';

  @override
  String get errTcknParentDegil => 'TCKN bir parent değildir.';

  @override
  String get errParentOkulIdYok => 'Parent\'ın okul ID\'si bulunamadı.';

  @override
  String get errParentStudentYok => 'Parent\'a ait student bulunamadı.';

  @override
  String get errTcknBulunamadi => 'TCKN bulunamadı.';

  @override
  String get errPersonOkulIdYok => 'Person\'ın okul ID\'si bulunamadı.';

  @override
  String get errOtpGecersiz => 'Geçersiz OTP veya kayıt bulunamadı.';

  @override
  String get errPersonSinifIdYok => 'Person\'ın sınıf ID\'si bulunamadı.';

  @override
  String get errTcknListesiBos => 'TCKN listesi boş.';

  @override
  String get errOlcekZatenTanimli => 'Bu ölçek zaten okula tanımlı.';

  @override
  String get errPersonOkulAtanmamis => 'Person bulunamadı veya okul atanmamış.';

  @override
  String get errTumSorularCevaplanmali => 'Tüm sorular cevaplanmalıdır.';

  @override
  String get errEksikSoruCevap => 'Eksik veya geçersiz soru cevapları.';

  @override
  String get errGecersizSoruCevap => 'Geçersiz soru/cevap.';

  @override
  String get errMinDegerMaxDegerdenBuyuk =>
      'min_deger, max_deger\'dan büyük olamaz.';

  @override
  String get errTcknZorunlu => 'tckn zorunludur.';

  @override
  String get errOgrenciHostesIliskisiYok =>
      'Öğrenci için tanımlı hostes ilişkisi bulunamadı.';

  @override
  String get errPinEncryptionKeyYok =>
      'PinEncryption:Key yapılandırılmamış. appsettings veya PinEncryption__Key ortam değişkenini ayarlayın.';

  @override
  String get errPinEncryptionKeyUzunluk =>
      'PinEncryption:Key tam 32 byte (Base64) olmalıdır.';

  @override
  String get errPinEncBos => 'pin_enc boş.';

  @override
  String get errPinEncFormat => 'Desteklenmeyen pin_enc formatı.';

  @override
  String get errPinEncUzunluk => 'Geçersiz pin_enc uzunluğu.';
}
