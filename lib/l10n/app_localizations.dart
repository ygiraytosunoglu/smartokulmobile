import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ru'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Smart Okul'**
  String get appTitle;

  /// No description provided for @userCode.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı No'**
  String get userCode;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş'**
  String get login;

  /// No description provided for @userType.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Tipi'**
  String get userType;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @enter.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get enter;

  /// No description provided for @galleries.
  ///
  /// In tr, this message translates to:
  /// **'Galeriler'**
  String get galleries;

  /// No description provided for @welcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoşgeldiniz'**
  String get welcome;

  /// No description provided for @err.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get err;

  /// No description provided for @userEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı No boş bırakılamaz'**
  String get userEmpty;

  /// No description provided for @userLength.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı No 11 haneli olmalıdır'**
  String get userLength;

  /// No description provided for @userHint.
  ///
  /// In tr, this message translates to:
  /// **'11 haneli Kullanıcı No giriniz'**
  String get userHint;

  /// No description provided for @pswHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi giriniz'**
  String get pswHint;

  /// No description provided for @pswEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Şifre boş bırakılamaz'**
  String get pswEmpty;

  /// No description provided for @teacher.
  ///
  /// In tr, this message translates to:
  /// **'Öğretmen'**
  String get teacher;

  /// No description provided for @parent.
  ///
  /// In tr, this message translates to:
  /// **'Veli'**
  String get parent;

  /// No description provided for @manager.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get manager;

  /// No description provided for @hostes.
  ///
  /// In tr, this message translates to:
  /// **'Hostes'**
  String get hostes;

  /// No description provided for @enterLoading.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yapılıyor...'**
  String get enterLoading;

  /// No description provided for @enterError.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu. Tekrar deneyin.'**
  String get enterError;

  /// No description provided for @pswForget.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get pswForget;

  /// No description provided for @messages.
  ///
  /// In tr, this message translates to:
  /// **'MESAJLAR'**
  String get messages;

  /// No description provided for @gallery.
  ///
  /// In tr, this message translates to:
  /// **'GALERİ'**
  String get gallery;

  /// No description provided for @notification.
  ///
  /// In tr, this message translates to:
  /// **'ANONS'**
  String get notification;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'PROFİL'**
  String get profile;

  /// No description provided for @anouncement.
  ///
  /// In tr, this message translates to:
  /// **'DUYURULAR'**
  String get anouncement;

  /// No description provided for @attendance.
  ///
  /// In tr, this message translates to:
  /// **'DEVAM BİLGİSİ'**
  String get attendance;

  /// No description provided for @medicine.
  ///
  /// In tr, this message translates to:
  /// **'İLAÇ'**
  String get medicine;

  /// No description provided for @gateControl.
  ///
  /// In tr, this message translates to:
  /// **'KAPI KONTROL'**
  String get gateControl;

  /// No description provided for @activities.
  ///
  /// In tr, this message translates to:
  /// **'ETKİNLİKLER'**
  String get activities;

  /// No description provided for @daily.
  ///
  /// In tr, this message translates to:
  /// **'GÜNLÜK'**
  String get daily;

  /// No description provided for @mealList.
  ///
  /// In tr, this message translates to:
  /// **'YEMEK LİSTESİ'**
  String get mealList;

  /// No description provided for @survey.
  ///
  /// In tr, this message translates to:
  /// **'ANKETLER'**
  String get survey;

  /// No description provided for @qrCode.
  ///
  /// In tr, this message translates to:
  /// **'KAREKOD'**
  String get qrCode;

  /// No description provided for @homework.
  ///
  /// In tr, this message translates to:
  /// **'ÖDEV'**
  String get homework;

  /// No description provided for @studentNotification.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci Anons'**
  String get studentNotification;

  /// No description provided for @notification1.
  ///
  /// In tr, this message translates to:
  /// **'Bıraktım'**
  String get notification1;

  /// No description provided for @notification2.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaştım'**
  String get notification2;

  /// No description provided for @notification3.
  ///
  /// In tr, this message translates to:
  /// **'Aldım'**
  String get notification3;

  /// No description provided for @notification4.
  ///
  /// In tr, this message translates to:
  /// **'Geldim'**
  String get notification4;

  /// No description provided for @mainScreen.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get mainScreen;

  /// No description provided for @studentLengthMsg.
  ///
  /// In tr, this message translates to:
  /// **'En az bir öğrenci seçilmelidir'**
  String get studentLengthMsg;

  /// No description provided for @notificationSuccessMsg.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim gönderildi'**
  String get notificationSuccessMsg;

  /// No description provided for @notificationFailMsg.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim gönderilemedi'**
  String get notificationFailMsg;

  /// No description provided for @teachersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğretmenler'**
  String get teachersTitle;

  /// No description provided for @teacherNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Öğretmen bulunamadı'**
  String get teacherNotFound;

  /// No description provided for @unnamedTeacher.
  ///
  /// In tr, this message translates to:
  /// **'İsimsiz Öğretmen'**
  String get unnamedTeacher;

  /// No description provided for @parentMessages.
  ///
  /// In tr, this message translates to:
  /// **'Veli Mesajlaşmaları'**
  String get parentMessages;

  /// No description provided for @messagesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get messagesTitle;

  /// No description provided for @noMessagesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok'**
  String get noMessagesYet;

  /// No description provided for @conversationWarning.
  ///
  /// In tr, this message translates to:
  /// **'* Konuşma metni okul yönetimi gözetimindedir'**
  String get conversationWarning;

  /// No description provided for @galleryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get galleryTitle;

  /// No description provided for @studentListNotLoaded.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci listesi yüklenmedi'**
  String get studentListNotLoaded;

  /// No description provided for @selectStudentsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilecek Öğrenciler'**
  String get selectStudentsTitle;

  /// No description provided for @selectAll.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get selectAll;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @contin.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get contin;

  /// No description provided for @noStudentSelected.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci seçilmedi'**
  String get noStudentSelected;

  /// No description provided for @galleryLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Galeri yüklenemedi: {error}'**
  String galleryLoadError(Object error);

  /// No description provided for @photoPermissionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraflara erişim izni gerekli'**
  String get photoPermissionRequired;

  /// No description provided for @mediaSavedToGallery.
  ///
  /// In tr, this message translates to:
  /// **'Medya galeriye kaydedildi'**
  String get mediaSavedToGallery;

  /// No description provided for @mediaSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Galeriye kaydetme başarısız'**
  String get mediaSaveFailed;

  /// No description provided for @errorMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String errorMessage(Object error);

  /// No description provided for @deleteMediaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Medya Sil'**
  String get deleteMediaTitle;

  /// No description provided for @deleteMediaConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu medya kalıcı olarak silinecek. Emin misiniz?'**
  String get deleteMediaConfirm;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @mediaDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Medya silindi'**
  String get mediaDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Silme başarısız: {error}'**
  String deleteFailed(Object error);

  /// No description provided for @uploading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get uploading;

  /// No description provided for @addMedia.
  ///
  /// In tr, this message translates to:
  /// **'Medya Ekle'**
  String get addMedia;

  /// No description provided for @mealScreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yemek Listesi'**
  String get mealScreenTitle;

  /// No description provided for @mealNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Yemek listesi bulunamadı.'**
  String get mealNotFound;

  /// No description provided for @mealBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı:'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle:'**
  String get mealLunch;

  /// No description provided for @mealSnack.
  ///
  /// In tr, this message translates to:
  /// **'İkindi:'**
  String get mealSnack;

  /// No description provided for @mealDateHeader.
  ///
  /// In tr, this message translates to:
  /// **'{date}'**
  String mealDateHeader(Object date);

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil Sayfası'**
  String get profileTitle;

  /// No description provided for @userInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'👤 Kullanıcı Bilgileri'**
  String get userInfoTitle;

  /// No description provided for @studentsTitle.
  ///
  /// In tr, this message translates to:
  /// **'👧 Öğrenciler'**
  String get studentsTitle;

  /// No description provided for @attendanceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yoklama'**
  String get attendanceTitle;

  /// No description provided for @parentInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'👪 Veli Bilgileri'**
  String get parentInfoTitle;

  /// No description provided for @labelFullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad:'**
  String get labelFullName;

  /// No description provided for @labelProfession.
  ///
  /// In tr, this message translates to:
  /// **'Meslek:'**
  String get labelProfession;

  /// No description provided for @labelHobby.
  ///
  /// In tr, this message translates to:
  /// **'Hobi:'**
  String get labelHobby;

  /// No description provided for @labelPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon:'**
  String get labelPhone;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @labelAllergy.
  ///
  /// In tr, this message translates to:
  /// **'Alerji:'**
  String get labelAllergy;

  /// No description provided for @labelMedicine.
  ///
  /// In tr, this message translates to:
  /// **'İlaç:'**
  String get labelMedicine;

  /// No description provided for @labelClass.
  ///
  /// In tr, this message translates to:
  /// **'Sınıfı:'**
  String get labelClass;

  /// No description provided for @labelSchoolNumber.
  ///
  /// In tr, this message translates to:
  /// **'Okul No:'**
  String get labelSchoolNumber;

  /// No description provided for @qrOrCodeCreateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Karekod / Kod Oluştur'**
  String get qrOrCodeCreateTitle;

  /// No description provided for @receiverLabel.
  ///
  /// In tr, this message translates to:
  /// **'Alacak Kişi'**
  String get receiverLabel;

  /// No description provided for @receiverHint.
  ///
  /// In tr, this message translates to:
  /// **'Kişi adını giriniz'**
  String get receiverHint;

  /// No description provided for @fieldRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bu alan zorunludur'**
  String get fieldRequired;

  /// No description provided for @createQrButton.
  ///
  /// In tr, this message translates to:
  /// **'QR Oluştur'**
  String get createQrButton;

  /// No description provided for @createCodeButton.
  ///
  /// In tr, this message translates to:
  /// **'Kod Oluştur'**
  String get createCodeButton;

  /// No description provided for @generatedResultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulan Sonuç'**
  String get generatedResultTitle;

  /// No description provided for @copyButton.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copyButton;

  /// No description provided for @copiedSnackBar.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı'**
  String get copiedSnackBar;

  /// No description provided for @shareButton.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get shareButton;

  /// No description provided for @qrVerifyTitle.
  ///
  /// In tr, this message translates to:
  /// **'QR / Kod Doğrulama'**
  String get qrVerifyTitle;

  /// No description provided for @tabQrScan.
  ///
  /// In tr, this message translates to:
  /// **'QR Oku'**
  String get tabQrScan;

  /// No description provided for @tabManualCode.
  ///
  /// In tr, this message translates to:
  /// **'Kod Gir'**
  String get tabManualCode;

  /// No description provided for @cameraInstruction.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen kamerayı bir QR koda doğru tutun'**
  String get cameraInstruction;

  /// No description provided for @copiedToClipboard.
  ///
  /// In tr, this message translates to:
  /// **'Kod panoya kopyalandı'**
  String get copiedToClipboard;

  /// No description provided for @scanAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Tara'**
  String get scanAgain;

  /// No description provided for @otpLabel.
  ///
  /// In tr, this message translates to:
  /// **'OTP Kod'**
  String get otpLabel;

  /// No description provided for @verifyButton.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula'**
  String get verifyButton;

  /// No description provided for @otpEmptyError.
  ///
  /// In tr, this message translates to:
  /// **'OTP boş olamaz'**
  String get otpEmptyError;

  /// No description provided for @verifySuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'✅ Kod Doğrulandı:'**
  String get verifySuccessTitle;

  /// No description provided for @verifyInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Kod Geçersiz'**
  String get verifyInvalid;

  /// No description provided for @verifyPersonLine.
  ///
  /// In tr, this message translates to:
  /// **'• {logName} - {personName}'**
  String verifyPersonLine(Object logName, Object personName);

  /// No description provided for @attendanceStatusTitle.
  ///
  /// In tr, this message translates to:
  /// **'Devam Durumu'**
  String get attendanceStatusTitle;

  /// No description provided for @unknownStudent.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen'**
  String get unknownStudent;

  /// No description provided for @attendanceNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Devam durumu bulunamadı.'**
  String get attendanceNotFound;

  /// No description provided for @attended.
  ///
  /// In tr, this message translates to:
  /// **'Devam etti'**
  String get attended;

  /// No description provided for @absent.
  ///
  /// In tr, this message translates to:
  /// **'Devamsız'**
  String get absent;

  /// No description provided for @medicineListTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Listesi'**
  String get medicineListTitle;

  /// No description provided for @createNewMedicine.
  ///
  /// In tr, this message translates to:
  /// **'Yeni İlaç Oluştur'**
  String get createNewMedicine;

  /// No description provided for @noMedicineYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ilaç bilgisi yok.'**
  String get noMedicineYet;

  /// No description provided for @medicineDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Detayı'**
  String get medicineDetailTitle;

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @noDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get noDescription;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @create.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get create;

  /// No description provided for @creating.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturuluyor...'**
  String get creating;

  /// No description provided for @createMedicineTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni İlaç Bilgisi Oluştur'**
  String get createMedicineTitle;

  /// No description provided for @medicineStartDay.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Başlangıç Günü'**
  String get medicineStartDay;

  /// No description provided for @medicineEndDay.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Bitiş Günü'**
  String get medicineEndDay;

  /// No description provided for @medicineTime.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Saati'**
  String get medicineTime;

  /// No description provided for @selectStudent.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci Seçin:'**
  String get selectStudent;

  /// No description provided for @fillAllDateFields.
  ///
  /// In tr, this message translates to:
  /// **'Tüm tarih alanlarını doldurunuz.'**
  String get fillAllDateFields;

  /// No description provided for @selectStudentError.
  ///
  /// In tr, this message translates to:
  /// **'Bir öğrenci seçmelisiniz.'**
  String get selectStudentError;

  /// No description provided for @medicineCreated.
  ///
  /// In tr, this message translates to:
  /// **'İlaç bilgisi başarıyla oluşturuldu.'**
  String get medicineCreated;

  /// No description provided for @deleteMedicineTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Kaydı Sil'**
  String get deleteMedicineTitle;

  /// No description provided for @deleteMedicineConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu ilaç kaydı silinecek. Emin misiniz?'**
  String get deleteMedicineConfirm;

  /// No description provided for @medicineDeactivated.
  ///
  /// In tr, this message translates to:
  /// **'İlaç kaydı silindi.'**
  String get medicineDeactivated;

  /// No description provided for @date.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get date;

  /// No description provided for @student.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci'**
  String get student;

  /// No description provided for @homeworkTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ödevler'**
  String get homeworkTitle;

  /// No description provided for @createHomework.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Ödev Oluştur'**
  String get createHomework;

  /// No description provided for @noHomeworkYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ödev yok.'**
  String get noHomeworkYet;

  /// No description provided for @homeworkDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ödev Detayı'**
  String get homeworkDetailTitle;

  /// No description provided for @lesson.
  ///
  /// In tr, this message translates to:
  /// **'Ders'**
  String get lesson;

  /// No description provided for @dueDate.
  ///
  /// In tr, this message translates to:
  /// **'Son Teslim Tarihi'**
  String get dueDate;

  /// No description provided for @attachedFiles.
  ///
  /// In tr, this message translates to:
  /// **'Ekli Dosyalar'**
  String get attachedFiles;

  /// No description provided for @fileOpenError.
  ///
  /// In tr, this message translates to:
  /// **'Dosya açılamadı'**
  String get fileOpenError;

  /// No description provided for @file.
  ///
  /// In tr, this message translates to:
  /// **'Dosya'**
  String get file;

  /// No description provided for @deleteHomeworkTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ödev Sil'**
  String get deleteHomeworkTitle;

  /// No description provided for @deleteHomeworkConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu ödev silinecek. Emin misiniz?'**
  String get deleteHomeworkConfirm;

  /// No description provided for @yes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @homeworkDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Ödev silindi'**
  String get homeworkDeleted;

  /// No description provided for @homeworkNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Ödev bulunamadı'**
  String get homeworkNotFound;

  /// No description provided for @deleteError.
  ///
  /// In tr, this message translates to:
  /// **'Silme hatası'**
  String get deleteError;

  /// No description provided for @update.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get update;

  /// No description provided for @newHomeworkTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Ödev Oluştur'**
  String get newHomeworkTitle;

  /// No description provided for @lessonRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ders *'**
  String get lessonRequired;

  /// No description provided for @descriptionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama *'**
  String get descriptionRequired;

  /// No description provided for @dueDateRequired.
  ///
  /// In tr, this message translates to:
  /// **'Son Teslim Tarihi *'**
  String get dueDateRequired;

  /// No description provided for @addFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya Ekle'**
  String get addFile;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @fillRequiredFields.
  ///
  /// In tr, this message translates to:
  /// **'Zorunlu alanları doldurun'**
  String get fillRequiredFields;

  /// No description provided for @lessonDetail.
  ///
  /// In tr, this message translates to:
  /// **'Ödev Detayı'**
  String get lessonDetail;

  /// No description provided for @surveyListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Anket Listesi'**
  String get surveyListTitle;

  /// No description provided for @newSurvey.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Anket Oluştur'**
  String get newSurvey;

  /// No description provided for @noSurvey.
  ///
  /// In tr, this message translates to:
  /// **'Henüz anket bulunmuyor.'**
  String get noSurvey;

  /// No description provided for @send.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get send;

  /// No description provided for @answer.
  ///
  /// In tr, this message translates to:
  /// **'Cevap'**
  String get answer;

  /// No description provided for @unanswered.
  ///
  /// In tr, this message translates to:
  /// **'Cevaplanmamış'**
  String get unanswered;

  /// No description provided for @answerDetails.
  ///
  /// In tr, this message translates to:
  /// **'Cevap Detayları'**
  String get answerDetails;

  /// No description provided for @noAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Cevapsız'**
  String get noAnswer;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Silme Onayı'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkinliği silmek istediğinize emin misiniz?'**
  String get deleteConfirmMessage;

  /// No description provided for @deleteSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite silindi'**
  String get deleteSuccess;

  /// No description provided for @deleteNoPermission.
  ///
  /// In tr, this message translates to:
  /// **'Silme yetkiniz yok'**
  String get deleteNoPermission;

  /// No description provided for @submitError.
  ///
  /// In tr, this message translates to:
  /// **'Cevap gönderilemedi'**
  String get submitError;

  /// No description provided for @noTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlıksız'**
  String get noTitle;

  /// No description provided for @doorControlTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kapı Kontrol Paneli'**
  String get doorControlTitle;

  /// No description provided for @mainGateControl.
  ///
  /// In tr, this message translates to:
  /// **'Ana Kapı Kontrol'**
  String get mainGateControl;

  /// No description provided for @parkingControl.
  ///
  /// In tr, this message translates to:
  /// **'Otopark Kontrol'**
  String get parkingControl;

  /// No description provided for @mainGateRequestSent.
  ///
  /// In tr, this message translates to:
  /// **'Ana Kapı açılma isteği gönderildi'**
  String get mainGateRequestSent;

  /// No description provided for @mainGateRequestFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ana kapı için istek gönderilemedi'**
  String get mainGateRequestFailed;

  /// No description provided for @parkingRequestSent.
  ///
  /// In tr, this message translates to:
  /// **'Otopark Kapısı açılma isteği gönderildi'**
  String get parkingRequestSent;

  /// No description provided for @parkingRequestFailed.
  ///
  /// In tr, this message translates to:
  /// **'Otopark için istek gönderilemedi'**
  String get parkingRequestFailed;

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get errorOccurred;

  /// No description provided for @notifyArrivalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geldiğimizi Bildir'**
  String get notifyArrivalTitle;

  /// No description provided for @attendanceSaved.
  ///
  /// In tr, this message translates to:
  /// **'Yoklamalar Kaydedildi'**
  String get attendanceSaved;

  /// No description provided for @dailyInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Bilgilendirme'**
  String get dailyInfoTitle;

  /// No description provided for @studentDefaultName.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci'**
  String get studentDefaultName;

  /// No description provided for @breakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get lunch;

  /// No description provided for @snack.
  ///
  /// In tr, this message translates to:
  /// **'İkindi'**
  String get snack;

  /// No description provided for @didNotEat.
  ///
  /// In tr, this message translates to:
  /// **'Yemedi'**
  String get didNotEat;

  /// No description provided for @ateLittle.
  ///
  /// In tr, this message translates to:
  /// **'Az Yedi'**
  String get ateLittle;

  /// No description provided for @ateAll.
  ///
  /// In tr, this message translates to:
  /// **'Tamamını Yedi'**
  String get ateAll;

  /// No description provided for @moodTitle.
  ///
  /// In tr, this message translates to:
  /// **'Duygu Durumu'**
  String get moodTitle;

  /// No description provided for @sleepTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get sleepTitle;

  /// No description provided for @moodHappy.
  ///
  /// In tr, this message translates to:
  /// **'Mutlu'**
  String get moodHappy;

  /// No description provided for @moodSad.
  ///
  /// In tr, this message translates to:
  /// **'Üzgün'**
  String get moodSad;

  /// No description provided for @moodTired.
  ///
  /// In tr, this message translates to:
  /// **'Yorgun'**
  String get moodTired;

  /// No description provided for @moodPeaceful.
  ///
  /// In tr, this message translates to:
  /// **'Huzurlu'**
  String get moodPeaceful;

  /// No description provided for @moodAngry.
  ///
  /// In tr, this message translates to:
  /// **'Sinirli'**
  String get moodAngry;

  /// No description provided for @sleepNone.
  ///
  /// In tr, this message translates to:
  /// **'Uyumadı'**
  String get sleepNone;

  /// No description provided for @sleepLittle.
  ///
  /// In tr, this message translates to:
  /// **'Az Uyudu'**
  String get sleepLittle;

  /// No description provided for @sleepSlept.
  ///
  /// In tr, this message translates to:
  /// **'Uyudu'**
  String get sleepSlept;

  /// No description provided for @studentNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci bulunamadı.'**
  String get studentNotFound;

  /// No description provided for @savedAll.
  ///
  /// In tr, this message translates to:
  /// **'Tüm bilgiler kaydedildi'**
  String get savedAll;

  /// No description provided for @saveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme hatası'**
  String get saveError;

  /// No description provided for @plans.
  ///
  /// In tr, this message translates to:
  /// **'Planlar'**
  String get plans;

  /// No description provided for @monthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get monthly;

  /// No description provided for @addPlan.
  ///
  /// In tr, this message translates to:
  /// **'Plan Ekle'**
  String get addPlan;

  /// No description provided for @fetch.
  ///
  /// In tr, this message translates to:
  /// **'Getir'**
  String get fetch;

  /// No description provided for @noPlansYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz plan bulunamadı'**
  String get noPlansYet;

  /// No description provided for @planFound.
  ///
  /// In tr, this message translates to:
  /// **' plan bulundu.'**
  String get planFound;

  /// No description provided for @planFetchError.
  ///
  /// In tr, this message translates to:
  /// **'Plan alınamadı'**
  String get planFetchError;

  /// No description provided for @planUploadSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Plan başarıyla yüklendi'**
  String get planUploadSuccess;

  /// No description provided for @planUploadError.
  ///
  /// In tr, this message translates to:
  /// **'Plan yüklenemedi'**
  String get planUploadError;

  /// No description provided for @permissionPhotosRequired.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraflara erişim izni gerekli'**
  String get permissionPhotosRequired;

  /// No description provided for @planSavedToGallery.
  ///
  /// In tr, this message translates to:
  /// **'Plan kaydedildi'**
  String get planSavedToGallery;

  /// No description provided for @planSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Plan kaydetme başarısız'**
  String get planSaveFailed;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String error(Object error);

  /// No description provided for @selectFileCanceled.
  ///
  /// In tr, this message translates to:
  /// **'Dosya seçilmedi'**
  String get selectFileCanceled;

  /// No description provided for @filePathError.
  ///
  /// In tr, this message translates to:
  /// **'Dosya yolu alınamadı'**
  String get filePathError;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor'**
  String get loading;

  /// No description provided for @activityListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Listesi'**
  String get activityListTitle;

  /// No description provided for @activityDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Detayı'**
  String get activityDetailTitle;

  /// No description provided for @newActivity.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Etkinlik Oluştur'**
  String get newActivity;

  /// No description provided for @createActivity.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Oluştur'**
  String get createActivity;

  /// No description provided for @activityDay.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Günü'**
  String get activityDay;

  /// No description provided for @activityTime.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Saati'**
  String get activityTime;

  /// No description provided for @activityPlace.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Yeri'**
  String get activityPlace;

  /// No description provided for @activityDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get activityDescription;

  /// No description provided for @classes.
  ///
  /// In tr, this message translates to:
  /// **'Sınıflar'**
  String get classes;

  /// No description provided for @updating.
  ///
  /// In tr, this message translates to:
  /// **'Değiştiriliyor...'**
  String get updating;

  /// No description provided for @selectDayTime.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik gün ve saati seçiniz.'**
  String get selectDayTime;

  /// No description provided for @placeDescriptionEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik yeri ve açıklama boş olamaz.'**
  String get placeDescriptionEmpty;

  /// No description provided for @selectAtLeastOneClass.
  ///
  /// In tr, this message translates to:
  /// **'En az bir sınıf seçmelisiniz.'**
  String get selectAtLeastOneClass;

  /// No description provided for @fillAllFields.
  ///
  /// In tr, this message translates to:
  /// **'Tüm alanlar doldurulmalıdır'**
  String get fillAllFields;

  /// No description provided for @activityCreated.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik başarıyla oluşturuldu.'**
  String get activityCreated;

  /// No description provided for @activityUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik güncellendi'**
  String get activityUpdated;

  /// No description provided for @activityDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite silindi'**
  String get activityDeleted;

  /// No description provided for @activityCreateError.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik oluşturulamadı: '**
  String get activityCreateError;

  /// No description provided for @activityUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme hatası: '**
  String get activityUpdateError;

  /// No description provided for @activityDeleteError.
  ///
  /// In tr, this message translates to:
  /// **'Silme hatası: '**
  String get activityDeleteError;

  /// No description provided for @noDeletePermission.
  ///
  /// In tr, this message translates to:
  /// **'Silme yetkiniz yok'**
  String get noDeletePermission;

  /// No description provided for @noActivityYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz etkinlik yok.'**
  String get noActivityYet;

  /// No description provided for @classLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sınıf/lar'**
  String get classLabel;

  /// No description provided for @placeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yer'**
  String get placeLabel;

  /// No description provided for @dateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get dateLabel;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @editActivity.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliği Düzenle'**
  String get editActivity;

  /// No description provided for @guidance.
  ///
  /// In tr, this message translates to:
  /// **'Rehberlik'**
  String get guidance;

  /// No description provided for @guidanceTitle.
  ///
  /// In tr, this message translates to:
  /// **'REHBERLİK'**
  String get guidanceTitle;

  /// No description provided for @measurement.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm'**
  String get measurement;

  /// No description provided for @guidanceResult.
  ///
  /// In tr, this message translates to:
  /// **'Ölçek Sonuç'**
  String get guidanceResult;

  /// No description provided for @fillForm.
  ///
  /// In tr, this message translates to:
  /// **'Form Doldur'**
  String get fillForm;

  /// No description provided for @getResult.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç Getir'**
  String get getResult;

  /// No description provided for @scaleResultGraph.
  ///
  /// In tr, this message translates to:
  /// **'Ölçek Sonuç Grafiği'**
  String get scaleResultGraph;

  /// No description provided for @result.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç'**
  String get result;

  /// No description provided for @resultNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Test sonucu bulunamadı'**
  String get resultNotFound;

  /// No description provided for @gelisim.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim'**
  String get gelisim;

  /// No description provided for @gelisimTitle.
  ///
  /// In tr, this message translates to:
  /// **'GELİŞİM'**
  String get gelisimTitle;

  /// No description provided for @createGelisim.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kayıt Oluştur'**
  String get createGelisim;

  /// No description provided for @allOfThem.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get allOfThem;

  /// No description provided for @growtType.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim Tipi'**
  String get growtType;

  /// No description provided for @newGrowth.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Gelişim Kaydı'**
  String get newGrowth;

  /// No description provided for @students.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenciler'**
  String get students;

  /// No description provided for @value.
  ///
  /// In tr, this message translates to:
  /// **'Değer'**
  String get value;

  /// No description provided for @editGelisimTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Düzenle / Sil'**
  String get editGelisimTitle;

  /// No description provided for @editGelisimButton.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Düzenle'**
  String get editGelisimButton;

  /// No description provided for @recordsFetchError.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlar alınamadı'**
  String get recordsFetchError;

  /// No description provided for @recordDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt silindi'**
  String get recordDeleted;

  /// No description provided for @noRecordFound.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı'**
  String get noRecordFound;

  /// No description provided for @gelisimDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu gelişim kaydı kalıcı olarak silinecek. Emin misiniz?'**
  String get gelisimDeleteConfirm;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri yok'**
  String get noData;

  /// No description provided for @errKullaniciNoZorunlu.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı No zorunludur.'**
  String get errKullaniciNoZorunlu;

  /// No description provided for @errKullaniciNo11Hane.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı No 11 hane ve sadece rakamlardan oluşmalıdır.'**
  String get errKullaniciNo11Hane;

  /// No description provided for @errKullaniciNoAyniRakam.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı No içinde aynı rakam 8 veya daha fazla kez bulunamaz.'**
  String get errKullaniciNoAyniRakam;

  /// No description provided for @errKayitBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı.'**
  String get errKayitBulunamadi;

  /// No description provided for @errSifreKilidiListesindeDegil.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcı şifre kilidi listesinde değil.'**
  String get errSifreKilidiListesindeDegil;

  /// No description provided for @errSifreSon4HaneGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Şifre telefon numarasının son 4 hanesi olarak güncellendi.'**
  String get errSifreSon4HaneGuncellendi;

  /// No description provided for @errKayitOkulaAitDegil.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı veya bu okula ait değil.'**
  String get errKayitOkulaAitDegil;

  /// No description provided for @errTcknSifreHatali.
  ///
  /// In tr, this message translates to:
  /// **'TCKN veya Şifre hatalı. Tekrar deneyiniz.'**
  String get errTcknSifreHatali;

  /// No description provided for @errTcknSifreTipHatali.
  ///
  /// In tr, this message translates to:
  /// **'TCKN, Şifre veya Kullanıcı Tipi hatalı. Tekrar deneyiniz.'**
  String get errTcknSifreTipHatali;

  /// No description provided for @errKullaniciKilitlendi.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı kilitlendi. Çok fazla hatalı şifre denemesi yapıldı. Okul yöneticiniz ile görüşünüz.'**
  String get errKullaniciKilitlendi;

  /// No description provided for @errLisansDolmus.
  ///
  /// In tr, this message translates to:
  /// **'Lisansınız dolmuş. Okul yöneticiniz ile görüşünüz.'**
  String get errLisansDolmus;

  /// No description provided for @errDogrulamaBasarili.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama başarılı.'**
  String get errDogrulamaBasarili;

  /// No description provided for @errKisiBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Kişi bulunamadı.'**
  String get errKisiBulunamadi;

  /// No description provided for @errKisiGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Kişi güncellendi.'**
  String get errKisiGuncellendi;

  /// No description provided for @errOkulBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Okul bulunamadı.'**
  String get errOkulBulunamadi;

  /// No description provided for @errOkulSilmeHatasi.
  ///
  /// In tr, this message translates to:
  /// **'Okul silinirken hata oluştu. Okula bağlı veriler olabilir.'**
  String get errOkulSilmeHatasi;

  /// No description provided for @errGonderenKisiBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Gönderen kişi bulunamadı.'**
  String get errGonderenKisiBulunamadi;

  /// No description provided for @errSiniflardaOgrenciYok.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilen sınıflarda hiç öğrenci bulunamadı.'**
  String get errSiniflardaOgrenciYok;

  /// No description provided for @errIcSunucuHatasi.
  ///
  /// In tr, this message translates to:
  /// **'İç sunucu hatası.'**
  String get errIcSunucuHatasi;

  /// No description provided for @errMesajAliciYok.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir alıcı bulunamadı, mesaj eklenmedi.'**
  String get errMesajAliciYok;

  /// No description provided for @errMesajGonderildi.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj başarıyla gönderildi.'**
  String get errMesajGonderildi;

  /// No description provided for @errAlanStudentTeacherYok.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir alan student veya teacher bulunamadı.'**
  String get errAlanStudentTeacherYok;

  /// No description provided for @errMesajKisiEklenmedi.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir kişiye mesaj eklenmedi.'**
  String get errMesajKisiEklenmedi;

  /// No description provided for @errDuyuruAliciYok.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir alıcı bulunamadı, duyuru eklenmedi.'**
  String get errDuyuruAliciYok;

  /// No description provided for @errDuyuruGonderildi.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru başarıyla gönderildi.'**
  String get errDuyuruGonderildi;

  /// No description provided for @errGelisimTipiEklendi.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim tipi başarıyla eklendi.'**
  String get errGelisimTipiEklendi;

  /// No description provided for @errDuyuruKisiEklenmedi.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir kişiye duyuru eklenmedi.'**
  String get errDuyuruKisiEklenmedi;

  /// No description provided for @errGelisimTipiBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim tipi bulunamadı.'**
  String get errGelisimTipiBulunamadi;

  /// No description provided for @errGelisimTipiSilindi.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim tipi başarıyla silindi.'**
  String get errGelisimTipiSilindi;

  /// No description provided for @errGelisimTipiOkulaAitDegil.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim tipi bu okula ait değil.'**
  String get errGelisimTipiOkulaAitDegil;

  /// No description provided for @errGelisimKayitEklendi.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim kaydı başarıyla eklendi.'**
  String get errGelisimKayitEklendi;

  /// No description provided for @errGelisimKayitBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim kaydı bulunamadı.'**
  String get errGelisimKayitBulunamadi;

  /// No description provided for @errGelisimKayitGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim kaydı başarıyla güncellendi.'**
  String get errGelisimKayitGuncellendi;

  /// No description provided for @errGelisimKayitSilindi.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim kaydı başarıyla silindi.'**
  String get errGelisimKayitSilindi;

  /// No description provided for @errOgrenciBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci bulunamadı.'**
  String get errOgrenciBulunamadi;

  /// No description provided for @errDesteklenmeyenIliski.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenmeyen ilişki tipi.'**
  String get errDesteklenmeyenIliski;

  /// No description provided for @errAlanKisiBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir alan kişi bulunamadı.'**
  String get errAlanKisiBulunamadi;

  /// No description provided for @errTcknParentDegil.
  ///
  /// In tr, this message translates to:
  /// **'TCKN bir parent değildir.'**
  String get errTcknParentDegil;

  /// No description provided for @errParentOkulIdYok.
  ///
  /// In tr, this message translates to:
  /// **'Parent\'ın okul ID\'si bulunamadı.'**
  String get errParentOkulIdYok;

  /// No description provided for @errParentStudentYok.
  ///
  /// In tr, this message translates to:
  /// **'Parent\'a ait student bulunamadı.'**
  String get errParentStudentYok;

  /// No description provided for @errTcknBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'TCKN bulunamadı.'**
  String get errTcknBulunamadi;

  /// No description provided for @errPersonOkulIdYok.
  ///
  /// In tr, this message translates to:
  /// **'Person\'ın okul ID\'si bulunamadı.'**
  String get errPersonOkulIdYok;

  /// No description provided for @errOtpGecersiz.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz OTP veya kayıt bulunamadı.'**
  String get errOtpGecersiz;

  /// No description provided for @errPersonSinifIdYok.
  ///
  /// In tr, this message translates to:
  /// **'Person\'ın sınıf ID\'si bulunamadı.'**
  String get errPersonSinifIdYok;

  /// No description provided for @errTcknListesiBos.
  ///
  /// In tr, this message translates to:
  /// **'TCKN listesi boş.'**
  String get errTcknListesiBos;

  /// No description provided for @errOlcekZatenTanimli.
  ///
  /// In tr, this message translates to:
  /// **'Bu ölçek zaten okula tanımlı.'**
  String get errOlcekZatenTanimli;

  /// No description provided for @errPersonOkulAtanmamis.
  ///
  /// In tr, this message translates to:
  /// **'Person bulunamadı veya okul atanmamış.'**
  String get errPersonOkulAtanmamis;

  /// No description provided for @errTumSorularCevaplanmali.
  ///
  /// In tr, this message translates to:
  /// **'Tüm sorular cevaplanmalıdır.'**
  String get errTumSorularCevaplanmali;

  /// No description provided for @errEksikSoruCevap.
  ///
  /// In tr, this message translates to:
  /// **'Eksik veya geçersiz soru cevapları.'**
  String get errEksikSoruCevap;

  /// No description provided for @errGecersizSoruCevap.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz soru/cevap.'**
  String get errGecersizSoruCevap;

  /// No description provided for @errMinDegerMaxDegerdenBuyuk.
  ///
  /// In tr, this message translates to:
  /// **'min_deger, max_deger\'dan büyük olamaz.'**
  String get errMinDegerMaxDegerdenBuyuk;

  /// No description provided for @errTcknZorunlu.
  ///
  /// In tr, this message translates to:
  /// **'tckn zorunludur.'**
  String get errTcknZorunlu;

  /// No description provided for @errOgrenciHostesIliskisiYok.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci için tanımlı hostes ilişkisi bulunamadı.'**
  String get errOgrenciHostesIliskisiYok;

  /// No description provided for @errPinEncryptionKeyYok.
  ///
  /// In tr, this message translates to:
  /// **'PinEncryption:Key yapılandırılmamış. appsettings veya PinEncryption__Key ortam değişkenini ayarlayın.'**
  String get errPinEncryptionKeyYok;

  /// No description provided for @errPinEncryptionKeyUzunluk.
  ///
  /// In tr, this message translates to:
  /// **'PinEncryption:Key tam 32 byte (Base64) olmalıdır.'**
  String get errPinEncryptionKeyUzunluk;

  /// No description provided for @errPinEncBos.
  ///
  /// In tr, this message translates to:
  /// **'pin_enc boş.'**
  String get errPinEncBos;

  /// No description provided for @errPinEncFormat.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenmeyen pin_enc formatı.'**
  String get errPinEncFormat;

  /// No description provided for @errPinEncUzunluk.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz pin_enc uzunluğu.'**
  String get errPinEncUzunluk;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
