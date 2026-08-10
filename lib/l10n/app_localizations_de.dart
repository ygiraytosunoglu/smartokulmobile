// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Smart Schule';

  @override
  String get userCode => 'Benutzernummer';

  @override
  String get login => 'Anmelden';

  @override
  String get userType => 'Benutzertyp';

  @override
  String get password => 'Passwort';

  @override
  String get enter => 'Einloggen';

  @override
  String get galleries => 'Galerien';

  @override
  String get welcome => 'Willkommen';

  @override
  String get err => 'Fehler';

  @override
  String get userEmpty => 'Benutzernummer darf nicht leer sein';

  @override
  String get userLength => 'Benutzernummer muss 11 Stellen haben';

  @override
  String get userHint => 'Bitte 11-stellige Benutzernummer eingeben';

  @override
  String get pswHint => 'Bitte Passwort eingeben';

  @override
  String get pswEmpty => 'Passwort darf nicht leer sein';

  @override
  String get teacher => 'Lehrer';

  @override
  String get parent => 'Elternteil';

  @override
  String get manager => 'Verwaltung';

  @override
  String get hostes => 'Begleiter';

  @override
  String get enterLoading => 'Wird angemeldet...';

  @override
  String get enterError =>
      'Ein Fehler ist aufgetreten. Bitte erneut versuchen.';

  @override
  String get pswForget => 'Passwort vergessen';

  @override
  String get messages => 'NACHRICHTEN';

  @override
  String get gallery => 'GALERIE';

  @override
  String get notification => 'ANKÜNDIGUNG';

  @override
  String get profile => 'PROFIL';

  @override
  String get anouncement => 'BEKANNTMACHUNGEN';

  @override
  String get attendance => 'ANWESENHEIT';

  @override
  String get medicine => 'MEDIKAMENT';

  @override
  String get gateControl => 'TORKONTROLLE';

  @override
  String get activities => 'AKTIVITÄTEN';

  @override
  String get daily => 'TÄGLICH';

  @override
  String get mealList => 'SPEISEPLAN';

  @override
  String get survey => 'UMFRAGEN';

  @override
  String get qrCode => 'QR-CODE';

  @override
  String get homework => 'HAUSAUFGABEN';

  @override
  String get studentNotification => 'Schülerbenachrichtigung';

  @override
  String get notification1 => 'Abgegeben';

  @override
  String get notification2 => 'Nähert sich';

  @override
  String get notification3 => 'Abgeholt';

  @override
  String get notification4 => 'Angekommen';

  @override
  String get mainScreen => 'Startseite';

  @override
  String get studentLengthMsg =>
      'Mindestens ein Schüler muss ausgewählt werden';

  @override
  String get notificationSuccessMsg => 'Benachrichtigung gesendet';

  @override
  String get notificationFailMsg =>
      'Benachrichtigung konnte nicht gesendet werden';

  @override
  String get teachersTitle => 'Lehrer';

  @override
  String get teacherNotFound => 'Kein Lehrer gefunden';

  @override
  String get unnamedTeacher => 'Unbekannter Lehrer';

  @override
  String get parentMessages => 'Elternnachrichten';

  @override
  String get messagesTitle => 'Nachrichten';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get conversationWarning =>
      '* Der Gesprächsinhalt wird von der Schulleitung überwacht';

  @override
  String get galleryTitle => 'Galerie';

  @override
  String get studentListNotLoaded => 'Schülerliste nicht geladen';

  @override
  String get selectStudentsTitle => 'Schüler auswählen';

  @override
  String get selectAll => 'Alle';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get contin => 'Weiter';

  @override
  String get noStudentSelected => 'Kein Schüler ausgewählt';

  @override
  String galleryLoadError(Object error) {
    return 'Galerie konnte nicht geladen werden: $error';
  }

  @override
  String get photoPermissionRequired =>
      'Zugriffsberechtigung für Fotos erforderlich';

  @override
  String get mediaSavedToGallery => 'Medien in Galerie gespeichert';

  @override
  String get mediaSaveFailed => 'Speichern in Galerie fehlgeschlagen';

  @override
  String errorMessage(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get deleteMediaTitle => 'Medien löschen';

  @override
  String get deleteMediaConfirm =>
      'Diese Medien werden dauerhaft gelöscht. Sind Sie sicher?';

  @override
  String get delete => 'Löschen';

  @override
  String get mediaDeleted => 'Medien gelöscht';

  @override
  String deleteFailed(Object error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get uploading => 'Wird hochgeladen...';

  @override
  String get addMedia => 'Medien hinzufügen';

  @override
  String get mealScreenTitle => 'Speiseplan';

  @override
  String get mealNotFound => 'Speiseplan nicht gefunden.';

  @override
  String get mealBreakfast => 'Frühstück:';

  @override
  String get mealLunch => 'Mittagessen:';

  @override
  String get mealSnack => 'Nachmittagssnack:';

  @override
  String mealDateHeader(Object date) {
    return '$date';
  }

  @override
  String get profileTitle => 'Profilseite';

  @override
  String get userInfoTitle => '👤 Benutzerinformationen';

  @override
  String get studentsTitle => '👧 Schüler';

  @override
  String get attendanceTitle => 'Anwesenheit';

  @override
  String get parentInfoTitle => '👪 Elterninformationen';

  @override
  String get labelFullName => 'Vor- und Nachname:';

  @override
  String get labelProfession => 'Beruf:';

  @override
  String get labelHobby => 'Hobby:';

  @override
  String get labelPhone => 'Telefon:';

  @override
  String get close => 'Schließen';

  @override
  String get labelAllergy => 'Allergie:';

  @override
  String get labelMedicine => 'Medikament:';

  @override
  String get labelClass => 'Klasse:';

  @override
  String get labelSchoolNumber => 'Schulnummer:';

  @override
  String get qrOrCodeCreateTitle => 'QR / Code erstellen';

  @override
  String get receiverLabel => 'Empfänger';

  @override
  String get receiverHint => 'Empfängername eingeben';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich';

  @override
  String get createQrButton => 'QR erstellen';

  @override
  String get createCodeButton => 'Code erstellen';

  @override
  String get generatedResultTitle => 'Erzeugtes Ergebnis';

  @override
  String get copyButton => 'Kopieren';

  @override
  String get copiedSnackBar => 'Kopiert';

  @override
  String get shareButton => 'Teilen';

  @override
  String get qrVerifyTitle => 'QR / Code Verifizierung';

  @override
  String get tabQrScan => 'QR scannen';

  @override
  String get tabManualCode => 'Code eingeben';

  @override
  String get cameraInstruction => 'Bitte Kamera auf einen QR-Code richten';

  @override
  String get copiedToClipboard => 'Code in Zwischenablage kopiert';

  @override
  String get scanAgain => 'Erneut scannen';

  @override
  String get otpLabel => 'OTP Code';

  @override
  String get verifyButton => 'Verifizieren';

  @override
  String get otpEmptyError => 'OTP darf nicht leer sein';

  @override
  String get verifySuccessTitle => '✅ Code verifiziert:';

  @override
  String get verifyInvalid => 'Falscher Code';

  @override
  String verifyPersonLine(Object logName, Object personName) {
    return '• $logName - $personName';
  }

  @override
  String get attendanceStatusTitle => 'Anwesenheitsstatus';

  @override
  String get unknownStudent => 'Unbekannt';

  @override
  String get attendanceNotFound => 'Kein Anwesenheitseintrag gefunden.';

  @override
  String get attended => 'Anwesend';

  @override
  String get absent => 'Abwesend';

  @override
  String get medicineListTitle => 'Medikamentenliste';

  @override
  String get createNewMedicine => 'Neues Medikament anlegen';

  @override
  String get noMedicineYet => 'Noch keine Medikamenteinträge.';

  @override
  String get medicineDetailTitle => 'Medikamentendetails';

  @override
  String get description => 'Beschreibung';

  @override
  String get noDescription => 'Keine';

  @override
  String get ok => 'OK';

  @override
  String get create => 'Erstellen';

  @override
  String get creating => 'Wird erstellt...';

  @override
  String get createMedicineTitle => 'Neuen Medikamenteneintrag erstellen';

  @override
  String get medicineStartDay => 'Startdatum der Medikation';

  @override
  String get medicineEndDay => 'Enddatum der Medikation';

  @override
  String get medicineTime => 'Einnahmezeit';

  @override
  String get selectStudent => 'Schüler auswählen:';

  @override
  String get fillAllDateFields => 'Bitte alle Datumsfelder ausfüllen.';

  @override
  String get selectStudentError => 'Sie müssen einen Schüler auswählen.';

  @override
  String get medicineCreated => 'Medikamenteneintrag erfolgreich erstellt.';

  @override
  String get deleteMedicineTitle => 'Medikamenteneintrag löschen';

  @override
  String get deleteMedicineConfirm =>
      'Dieser Medikamenteneintrag wird gelöscht. Sind Sie sicher?';

  @override
  String get medicineDeactivated => 'Medikamenteneintrag gelöscht.';

  @override
  String get date => 'Datum';

  @override
  String get student => 'Schüler';

  @override
  String get homeworkTitle => 'Hausaufgaben';

  @override
  String get createHomework => 'Hausaufgabe erstellen';

  @override
  String get noHomeworkYet => 'Noch keine Hausaufgaben.';

  @override
  String get homeworkDetailTitle => 'Hausaufgabendetails';

  @override
  String get lesson => 'Fach';

  @override
  String get dueDate => 'Abgabedatum';

  @override
  String get attachedFiles => 'Anhänge';

  @override
  String get fileOpenError => 'Datei konnte nicht geöffnet werden';

  @override
  String get file => 'Datei';

  @override
  String get deleteHomeworkTitle => 'Hausaufgabe löschen';

  @override
  String get deleteHomeworkConfirm =>
      'Diese Hausaufgabe wird gelöscht. Sind Sie sicher?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get homeworkDeleted => 'Hausaufgabe gelöscht';

  @override
  String get homeworkNotFound => 'Hausaufgabe nicht gefunden';

  @override
  String get deleteError => 'Fehler beim Löschen';

  @override
  String get update => 'Ändern';

  @override
  String get newHomeworkTitle => 'Neue Hausaufgabe erstellen';

  @override
  String get lessonRequired => 'Fach *';

  @override
  String get descriptionRequired => 'Beschreibung *';

  @override
  String get dueDateRequired => 'Abgabedatum *';

  @override
  String get addFile => 'Datei hinzufügen';

  @override
  String get save => 'Speichern';

  @override
  String get fillRequiredFields => 'Pflichtfelder ausfüllen';

  @override
  String get lessonDetail => 'Hausaufgabendetails';

  @override
  String get surveyListTitle => 'Umfrageliste';

  @override
  String get newSurvey => 'Neue Umfrage erstellen';

  @override
  String get noSurvey => 'Noch keine Umfragen vorhanden.';

  @override
  String get send => 'Senden';

  @override
  String get answer => 'Antwort';

  @override
  String get unanswered => 'Unbeantwortet';

  @override
  String get answerDetails => 'Antwortdetails';

  @override
  String get noAnswer => 'Keine Antwort';

  @override
  String get deleteConfirmTitle => 'Löschbestätigung';

  @override
  String get deleteConfirmMessage =>
      'Möchten Sie diese Aktivität wirklich löschen?';

  @override
  String get deleteSuccess => 'Aktivität gelöscht';

  @override
  String get deleteNoPermission => 'Keine Löschberechtigung';

  @override
  String get submitError => 'Antwort konnte nicht gesendet werden';

  @override
  String get noTitle => 'Kein Titel';

  @override
  String get doorControlTitle => 'Torkontrollpanel';

  @override
  String get mainGateControl => 'Haupttor Kontrolle';

  @override
  String get parkingControl => 'Parkplatz Kontrolle';

  @override
  String get mainGateRequestSent => 'Anfrage zum Öffnen des Haupttors gesendet';

  @override
  String get mainGateRequestFailed =>
      'Anfrage für Haupttor konnte nicht gesendet werden';

  @override
  String get parkingRequestSent =>
      'Anfrage zum Öffnen des Parkplatztors gesendet';

  @override
  String get parkingRequestFailed =>
      'Anfrage für Parkplatz konnte nicht gesendet werden';

  @override
  String get errorOccurred => 'Ein Fehler ist aufgetreten';

  @override
  String get notifyArrivalTitle => 'Ankunft melden';

  @override
  String get attendanceSaved => 'Anwesenheit gespeichert';

  @override
  String get dailyInfoTitle => 'Tagesinformationen';

  @override
  String get studentDefaultName => 'Schüler';

  @override
  String get breakfast => 'Frühstück';

  @override
  String get lunch => 'Mittagessen';

  @override
  String get snack => 'Nachmittagssnack';

  @override
  String get didNotEat => 'Hat nicht gegessen';

  @override
  String get ateLittle => 'Wenig gegessen';

  @override
  String get ateAll => 'Alles gegessen';

  @override
  String get moodTitle => 'Stimmung';

  @override
  String get sleepTitle => 'Schlaf';

  @override
  String get moodHappy => 'Fröhlich';

  @override
  String get moodSad => 'Traurig';

  @override
  String get moodTired => 'Müde';

  @override
  String get moodPeaceful => 'Ruhig';

  @override
  String get moodAngry => 'Wütend';

  @override
  String get sleepNone => 'Nicht geschlafen';

  @override
  String get sleepLittle => 'Wenig geschlafen';

  @override
  String get sleepSlept => 'Geschlafen';

  @override
  String get studentNotFound => 'Schüler nicht gefunden.';

  @override
  String get savedAll => 'Alle Informationen gespeichert';

  @override
  String get saveError => 'Fehler beim Speichern';

  @override
  String get plans => 'Pläne';

  @override
  String get monthly => 'Monatlich';

  @override
  String get addPlan => 'Plan hinzufügen';

  @override
  String get fetch => 'Abrufen';

  @override
  String get noPlansYet => 'Noch keine Pläne gefunden';

  @override
  String get planFound => ' Plan/Pläne gefunden.';

  @override
  String get planFetchError => 'Pläne konnten nicht abgerufen werden';

  @override
  String get planUploadSuccess => 'Plan erfolgreich hochgeladen';

  @override
  String get planUploadError => 'Plan konnte nicht hochgeladen werden';

  @override
  String get permissionPhotosRequired =>
      'Zugriffsberechtigung für Fotos erforderlich';

  @override
  String get planSavedToGallery => 'Plan in Galerie gespeichert';

  @override
  String get planSaveFailed => 'Plan konnte nicht gespeichert werden';

  @override
  String error(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get selectFileCanceled => 'Keine Datei ausgewählt';

  @override
  String get filePathError => 'Dateipfad konnte nicht abgerufen werden';

  @override
  String get loading => 'Wird geladen';

  @override
  String get activityListTitle => 'Aktivitätsliste';

  @override
  String get activityDetailTitle => 'Aktivitätsdetails';

  @override
  String get newActivity => 'Neue Aktivität erstellen';

  @override
  String get createActivity => 'Aktivität erstellen';

  @override
  String get activityDay => 'Aktivitätstag';

  @override
  String get activityTime => 'Aktivitätszeit';

  @override
  String get activityPlace => 'Aktivitätsort';

  @override
  String get activityDescription => 'Beschreibung';

  @override
  String get classes => 'Klassen';

  @override
  String get updating => 'Wird geändert...';

  @override
  String get selectDayTime => 'Bitte Aktivitätstag und -uhrzeit auswählen.';

  @override
  String get placeDescriptionEmpty =>
      'Ort und Beschreibung dürfen nicht leer sein.';

  @override
  String get selectAtLeastOneClass =>
      'Mindestens eine Klasse muss ausgewählt werden.';

  @override
  String get fillAllFields => 'Alle Felder müssen ausgefüllt werden';

  @override
  String get activityCreated => 'Aktivität erfolgreich erstellt.';

  @override
  String get activityUpdated => 'Aktivität aktualisiert';

  @override
  String get activityDeleted => 'Aktivität gelöscht';

  @override
  String get activityCreateError => 'Aktivität konnte nicht erstellt werden: ';

  @override
  String get activityUpdateError => 'Aktualisierungsfehler: ';

  @override
  String get activityDeleteError => 'Löschfehler: ';

  @override
  String get noDeletePermission => 'Keine Löschberechtigung';

  @override
  String get noActivityYet => 'Noch keine Aktivitäten.';

  @override
  String get classLabel => 'Klasse(n)';

  @override
  String get placeLabel => 'Ort';

  @override
  String get dateLabel => 'Datum';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editActivity => 'Aktivität bearbeiten';

  @override
  String get guidance => 'Beratung';

  @override
  String get guidanceTitle => 'BERATUNG';

  @override
  String get measurement => 'Messung';

  @override
  String get guidanceResult => 'Bewertungsergebnis';

  @override
  String get fillForm => 'Formular ausfüllen';

  @override
  String get getResult => 'Ergebnis abrufen';

  @override
  String get scaleResultGraph => 'Bewertungsergebnisgrafik';

  @override
  String get result => 'Ergebnis';

  @override
  String get resultNotFound => 'Ergebnis nicht gefunden';

  @override
  String get gelisim => 'Entwicklung';

  @override
  String get gelisimTitle => 'ENTWICKLUNG';

  @override
  String get createGelisim => 'Neuen Eintrag erstellen';

  @override
  String get allOfThem => 'Alle';

  @override
  String get growtType => 'Entwicklungstyp';

  @override
  String get newGrowth => 'Neuer Entwicklungseintrag';

  @override
  String get students => 'Schüler';

  @override
  String get value => 'Wert';

  @override
  String get editGelisimTitle => 'Eintrag bearbeiten / löschen';

  @override
  String get editGelisimButton => 'Eintrag bearbeiten';

  @override
  String get recordsFetchError => 'Einträge konnten nicht abgerufen werden';

  @override
  String get recordDeleted => 'Eintrag gelöscht';

  @override
  String get noRecordFound => 'Kein Eintrag gefunden';

  @override
  String get gelisimDeleteConfirm =>
      'Dieser Entwicklungseintrag wird dauerhaft gelöscht. Sind Sie sicher?';

  @override
  String get noData => 'Keine Daten';

  @override
  String get errKullaniciNoZorunlu => 'Benutzernummer ist erforderlich.';

  @override
  String get errKullaniciNo11Hane =>
      'Die Benutzernummer muss aus 11 Ziffern bestehen und darf nur Zahlen enthalten.';

  @override
  String get errKullaniciNoAyniRakam =>
      'Dieselbe Ziffer darf in der Benutzernummer nicht 8-mal oder häufiger vorkommen.';

  @override
  String get errKayitBulunamadi => 'Datensatz nicht gefunden.';

  @override
  String get errSifreKilidiListesindeDegil =>
      'Dieser Benutzer befindet sich nicht in der Liste gesperrter Passwörter.';

  @override
  String get errSifreSon4HaneGuncellendi =>
      'Das Passwort wurde auf die letzten 4 Ziffern der Telefonnummer zurückgesetzt.';

  @override
  String get errKayitOkulaAitDegil =>
      'Datensatz nicht gefunden oder gehört nicht zu dieser Schule.';

  @override
  String get errTcknSifreHatali =>
      'TCKN oder Passwort ist falsch. Bitte versuchen Sie es erneut.';

  @override
  String get errTcknSifreTipHatali =>
      'TCKN, Passwort oder Benutzertyp ist falsch. Bitte versuchen Sie es erneut.';

  @override
  String get errKullaniciKilitlendi =>
      'Benutzerkonto wurde gesperrt. Zu viele fehlerhafte Passwortversuche. Bitte wenden Sie sich an Ihre Schulverwaltung.';

  @override
  String get errLisansDolmus =>
      'Ihre Lizenz ist abgelaufen. Bitte wenden Sie sich an Ihre Schulverwaltung.';

  @override
  String get errDogrulamaBasarili => 'Verifizierung erfolgreich.';

  @override
  String get errKisiBulunamadi => 'Person nicht gefunden.';

  @override
  String get errKisiGuncellendi => 'Person erfolgreich aktualisiert.';

  @override
  String get errOkulBulunamadi => 'Schule nicht gefunden.';

  @override
  String get errOkulSilmeHatasi =>
      'Beim Löschen der Schule ist ein Fehler aufgetreten. Möglicherweise sind noch zugehörige Daten vorhanden.';

  @override
  String get errGonderenKisiBulunamadi => 'Absender nicht gefunden.';

  @override
  String get errSiniflardaOgrenciYok =>
      'In den angegebenen Klassen wurden keine Schüler gefunden.';

  @override
  String get errIcSunucuHatasi => 'Interner Serverfehler.';

  @override
  String get errMesajAliciYok =>
      'Keine Empfänger gefunden. Nachricht wurde nicht erstellt.';

  @override
  String get errMesajGonderildi => 'Nachricht erfolgreich gesendet.';

  @override
  String get errAlanStudentTeacherYok =>
      'Keine gültigen Schüler oder Lehrer gefunden.';

  @override
  String get errMesajKisiEklenmedi =>
      'Der Nachricht wurden keine Empfänger hinzugefügt.';

  @override
  String get errDuyuruAliciYok =>
      'Keine Empfänger gefunden. Ankündigung wurde nicht erstellt.';

  @override
  String get errDuyuruGonderildi => 'Ankündigung erfolgreich gesendet.';

  @override
  String get errGelisimTipiEklendi =>
      'Entwicklungstyp erfolgreich hinzugefügt.';

  @override
  String get errDuyuruKisiEklenmedi =>
      'Der Ankündigung wurden keine Empfänger hinzugefügt.';

  @override
  String get errGelisimTipiBulunamadi => 'Entwicklungstyp nicht gefunden.';

  @override
  String get errGelisimTipiSilindi => 'Entwicklungstyp erfolgreich gelöscht.';

  @override
  String get errGelisimTipiOkulaAitDegil =>
      'Dieser Entwicklungstyp gehört nicht zu dieser Schule.';

  @override
  String get errGelisimKayitEklendi =>
      'Entwicklungsdatensatz erfolgreich hinzugefügt.';

  @override
  String get errGelisimKayitBulunamadi =>
      'Entwicklungsdatensatz nicht gefunden.';

  @override
  String get errGelisimKayitGuncellendi =>
      'Entwicklungsdatensatz erfolgreich aktualisiert.';

  @override
  String get errGelisimKayitSilindi =>
      'Entwicklungsdatensatz erfolgreich gelöscht.';

  @override
  String get errOgrenciBulunamadi => 'Schüler nicht gefunden.';

  @override
  String get errDesteklenmeyenIliski => 'Nicht unterstützter Beziehungstyp.';

  @override
  String get errAlanKisiBulunamadi => 'Keine gültigen Personen gefunden.';

  @override
  String get errTcknParentDegil =>
      'Die angegebene TCKN gehört keinem Elternteil.';

  @override
  String get errParentOkulIdYok =>
      'Die Schul-ID des Elternteils konnte nicht gefunden werden.';

  @override
  String get errParentStudentYok =>
      'Für das Elternteil wurden keine Schüler gefunden.';

  @override
  String get errTcknBulunamadi => 'TCKN nicht gefunden.';

  @override
  String get errPersonOkulIdYok =>
      'Die Schul-ID der Person konnte nicht gefunden werden.';

  @override
  String get errOtpGecersiz => 'Ungültige OTP oder Datensatz nicht gefunden.';

  @override
  String get errPersonSinifIdYok =>
      'Die Klassen-ID der Person konnte nicht gefunden werden.';

  @override
  String get errTcknListesiBos => 'Die TCKN-Liste ist leer.';

  @override
  String get errOlcekZatenTanimli =>
      'Diese Skala ist der Schule bereits zugeordnet.';

  @override
  String get errPersonOkulAtanmamis =>
      'Person nicht gefunden oder keiner Schule zugewiesen.';

  @override
  String get errTumSorularCevaplanmali =>
      'Alle Fragen müssen beantwortet werden.';

  @override
  String get errEksikSoruCevap =>
      'Fehlende oder ungültige Antworten auf Fragen.';

  @override
  String get errGecersizSoruCevap => 'Ungültige Frage oder Antwort.';

  @override
  String get errMinDegerMaxDegerdenBuyuk =>
      'min_value darf nicht größer als max_value sein.';

  @override
  String get errTcknZorunlu => 'TCKN ist erforderlich.';

  @override
  String get errOgrenciHostesIliskisiYok =>
      'Für den Schüler wurde keine Betreuer-Beziehung gefunden.';

  @override
  String get errPinEncryptionKeyYok =>
      'PinEncryption:Key ist nicht konfiguriert. Bitte konfigurieren Sie ihn in appsettings oder über die Umgebungsvariable PinEncryption__Key.';

  @override
  String get errPinEncryptionKeyUzunluk =>
      'PinEncryption:Key muss genau 32 Byte (Base64) lang sein.';

  @override
  String get errPinEncBos => 'pin_enc ist leer.';

  @override
  String get errPinEncFormat => 'Nicht unterstütztes pin_enc-Format.';

  @override
  String get errPinEncUzunluk => 'Ungültige pin_enc-Länge.';
}
