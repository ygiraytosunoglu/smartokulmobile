// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Smart School';

  @override
  String get userCode => 'Номер пользователя';

  @override
  String get login => 'Вход';

  @override
  String get userType => 'Тип пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get enter => 'Войти';

  @override
  String get galleries => 'Галереи';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get err => 'Ошибка';

  @override
  String get userEmpty => 'Номер пользователя не может быть пустым';

  @override
  String get userLength => 'Номер пользователя должен состоять из 11 цифр';

  @override
  String get userHint => 'Введите 11-значный номер пользователя';

  @override
  String get pswHint => 'Введите пароль';

  @override
  String get pswEmpty => 'Пароль не может быть пустым';

  @override
  String get teacher => 'Учитель';

  @override
  String get parent => 'Родитель';

  @override
  String get manager => 'Администратор';

  @override
  String get hostes => 'Сопровождающий';

  @override
  String get enterLoading => 'Выполняется вход...';

  @override
  String get enterError => 'Произошла ошибка. Попробуйте снова.';

  @override
  String get pswForget => 'Забыли пароль';

  @override
  String get messages => 'СООБЩЕНИЯ';

  @override
  String get gallery => 'ГАЛЕРЕЯ';

  @override
  String get notification => 'ОБЪЯВЛЕНИЕ';

  @override
  String get profile => 'ПРОФИЛЬ';

  @override
  String get anouncement => 'ОБЪЯВЛЕНИЯ';

  @override
  String get attendance => 'ПОСЕЩАЕМОСТЬ';

  @override
  String get medicine => 'ЛЕКАРСТВО';

  @override
  String get gateControl => 'КОНТРОЛЬ ДВЕРИ';

  @override
  String get activities => 'МЕРОПРИЯТИЯ';

  @override
  String get daily => 'ЕЖЕДНЕВНО';

  @override
  String get mealList => 'МЕНЮ';

  @override
  String get survey => 'ОПРОСЫ';

  @override
  String get qrCode => 'QR-КОД';

  @override
  String get homework => 'ДОМАШНЕЕ ЗАДАНИЕ';

  @override
  String get studentNotification => 'Уведомление ученика';

  @override
  String get notification1 => 'Оставил';

  @override
  String get notification2 => 'Подъезжаю';

  @override
  String get notification3 => 'Забрал';

  @override
  String get notification4 => 'Прибыл';

  @override
  String get mainScreen => 'Главная страница';

  @override
  String get studentLengthMsg => 'Необходимо выбрать хотя бы одного ученика';

  @override
  String get notificationSuccessMsg => 'Уведомление отправлено';

  @override
  String get notificationFailMsg => 'Не удалось отправить уведомление';

  @override
  String get teachersTitle => 'Учителя';

  @override
  String get teacherNotFound => 'Учитель не найден';

  @override
  String get unnamedTeacher => 'Безымянный учитель';

  @override
  String get parentMessages => 'Сообщения родителей';

  @override
  String get messagesTitle => 'Сообщения';

  @override
  String get noMessagesYet => 'Сообщений пока нет';

  @override
  String get conversationWarning =>
      '* Переписка контролируется администрацией школы';

  @override
  String get galleryTitle => 'Галерея';

  @override
  String get studentListNotLoaded => 'Список учеников не загружен';

  @override
  String get selectStudentsTitle => 'Ученики для отправки';

  @override
  String get selectAll => 'Все';

  @override
  String get cancel => 'Отмена';

  @override
  String get contin => 'Продолжить';

  @override
  String get noStudentSelected => 'Ученик не выбран';

  @override
  String galleryLoadError(Object error) {
    return 'Не удалось загрузить галерею: $error';
  }

  @override
  String get photoPermissionRequired => 'Требуется разрешение на доступ к фото';

  @override
  String get mediaSavedToGallery => 'Медиа сохранено в галерею';

  @override
  String get mediaSaveFailed => 'Не удалось сохранить в галерею';

  @override
  String errorMessage(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get deleteMediaTitle => 'Удалить медиа';

  @override
  String get deleteMediaConfirm =>
      'Это медиа будет удалено навсегда. Вы уверены?';

  @override
  String get delete => 'Удалить';

  @override
  String get mediaDeleted => 'Медиа удалено';

  @override
  String deleteFailed(Object error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String get uploading => 'Загрузка...';

  @override
  String get addMedia => 'Добавить медиа';

  @override
  String get mealScreenTitle => 'Меню питания';

  @override
  String get mealNotFound => 'Меню не найдено.';

  @override
  String get mealBreakfast => 'Завтрак:';

  @override
  String get mealLunch => 'Обед:';

  @override
  String get mealSnack => 'Полдник:';

  @override
  String mealDateHeader(Object date) {
    return '$date';
  }

  @override
  String get profileTitle => 'Страница профиля';

  @override
  String get userInfoTitle => '👤 Информация о пользователе';

  @override
  String get studentsTitle => '👧 Ученики';

  @override
  String get attendanceTitle => 'Посещаемость';

  @override
  String get parentInfoTitle => '👪 Информация о родителях';

  @override
  String get labelFullName => 'Имя и фамилия:';

  @override
  String get labelProfession => 'Профессия:';

  @override
  String get labelHobby => 'Хобби:';

  @override
  String get labelPhone => 'Телефон:';

  @override
  String get close => 'Закрыть';

  @override
  String get labelAllergy => 'Аллергия:';

  @override
  String get labelMedicine => 'Лекарство:';

  @override
  String get labelClass => 'Класс:';

  @override
  String get labelSchoolNumber => 'Школьный номер:';

  @override
  String get qrOrCodeCreateTitle => 'Создать QR / Код';

  @override
  String get receiverLabel => 'Получатель';

  @override
  String get receiverHint => 'Введите имя получателя';

  @override
  String get fieldRequired => 'Это поле обязательно';

  @override
  String get createQrButton => 'Создать QR';

  @override
  String get createCodeButton => 'Создать код';

  @override
  String get generatedResultTitle => 'Сгенерированный результат';

  @override
  String get copyButton => 'Копировать';

  @override
  String get copiedSnackBar => 'Скопировано';

  @override
  String get shareButton => 'Поделиться';

  @override
  String get qrVerifyTitle => 'Проверка QR / Кода';

  @override
  String get tabQrScan => 'Сканировать QR';

  @override
  String get tabManualCode => 'Ввести код';

  @override
  String get cameraInstruction => 'Наведите камеру на QR-код';

  @override
  String get copiedToClipboard => 'Код скопирован в буфер обмена';

  @override
  String get scanAgain => 'Сканировать снова';

  @override
  String get otpLabel => 'OTP код';

  @override
  String get verifyButton => 'Проверить';

  @override
  String get otpEmptyError => 'OTP не может быть пустым';

  @override
  String get verifySuccessTitle => '✅ Код подтвержден:';

  @override
  String get verifyInvalid => 'Неверный код';

  @override
  String verifyPersonLine(Object logName, Object personName) {
    return '• $logName - $personName';
  }

  @override
  String get attendanceStatusTitle => 'Статус посещаемости';

  @override
  String get unknownStudent => 'Неизвестный';

  @override
  String get attendanceNotFound => 'Данные о посещаемости не найдены.';

  @override
  String get attended => 'Присутствовал';

  @override
  String get absent => 'Отсутствовал';

  @override
  String get medicineListTitle => 'Список лекарств';

  @override
  String get createNewMedicine => 'Создать новую запись о лекарстве';

  @override
  String get noMedicineYet => 'Записей о лекарствах пока нет.';

  @override
  String get medicineDetailTitle => 'Детали лекарства';

  @override
  String get description => 'Описание';

  @override
  String get noDescription => 'Нет';

  @override
  String get ok => 'Хорошо';

  @override
  String get create => 'Создать';

  @override
  String get creating => 'Создание...';

  @override
  String get createMedicineTitle => 'Создать новую запись о лекарстве';

  @override
  String get medicineStartDay => 'Дата начала приёма лекарства';

  @override
  String get medicineEndDay => 'Дата окончания приёма лекарства';

  @override
  String get medicineTime => 'Время приёма лекарства';

  @override
  String get selectStudent => 'Выберите ученика:';

  @override
  String get fillAllDateFields => 'Пожалуйста, заполните все поля с датами.';

  @override
  String get selectStudentError => 'Необходимо выбрать ученика.';

  @override
  String get medicineCreated => 'Запись о лекарстве успешно создана.';

  @override
  String get deleteMedicineTitle => 'Удалить запись о лекарстве';

  @override
  String get deleteMedicineConfirm =>
      'Эта запись о лекарстве будет удалена. Вы уверены?';

  @override
  String get medicineDeactivated => 'Запись о лекарстве удалена.';

  @override
  String get date => 'Дата';

  @override
  String get student => 'Ученик';

  @override
  String get homeworkTitle => 'Домашние задания';

  @override
  String get createHomework => 'Создать домашнее задание';

  @override
  String get noHomeworkYet => 'Домашних заданий пока нет.';

  @override
  String get homeworkDetailTitle => 'Детали задания';

  @override
  String get lesson => 'Урок';

  @override
  String get dueDate => 'Срок сдачи';

  @override
  String get attachedFiles => 'Прикреплённые файлы';

  @override
  String get fileOpenError => 'Не удалось открыть файл';

  @override
  String get file => 'Файл';

  @override
  String get deleteHomeworkTitle => 'Удалить задание';

  @override
  String get deleteHomeworkConfirm => 'Это задание будет удалено. Вы уверены?';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get homeworkDeleted => 'Задание удалено';

  @override
  String get homeworkNotFound => 'Задание не найдено';

  @override
  String get deleteError => 'Ошибка удаления';

  @override
  String get update => 'Изменить';

  @override
  String get newHomeworkTitle => 'Создать новое домашнее задание';

  @override
  String get lessonRequired => 'Урок *';

  @override
  String get descriptionRequired => 'Описание *';

  @override
  String get dueDateRequired => 'Срок сдачи *';

  @override
  String get addFile => 'Добавить файл';

  @override
  String get save => 'Сохранить';

  @override
  String get fillRequiredFields => 'Заполните обязательные поля';

  @override
  String get lessonDetail => 'Детали задания';

  @override
  String get surveyListTitle => 'Список опросов';

  @override
  String get newSurvey => 'Создать новый опрос';

  @override
  String get noSurvey => 'Опросов пока нет.';

  @override
  String get send => 'Отправить';

  @override
  String get answer => 'Ответ';

  @override
  String get unanswered => 'Без ответа';

  @override
  String get answerDetails => 'Детали ответа';

  @override
  String get noAnswer => 'Нет ответа';

  @override
  String get deleteConfirmTitle => 'Подтверждение удаления';

  @override
  String get deleteConfirmMessage =>
      'Вы уверены, что хотите удалить это мероприятие?';

  @override
  String get deleteSuccess => 'Мероприятие удалено';

  @override
  String get deleteNoPermission => 'У вас нет прав на удаление';

  @override
  String get submitError => 'Не удалось отправить ответ';

  @override
  String get noTitle => 'Без названия';

  @override
  String get doorControlTitle => 'Панель управления дверью';

  @override
  String get mainGateControl => 'Управление главными воротами';

  @override
  String get parkingControl => 'Управление парковкой';

  @override
  String get mainGateRequestSent =>
      'Запрос на открытие главных ворот отправлен';

  @override
  String get mainGateRequestFailed =>
      'Не удалось отправить запрос для главных ворот';

  @override
  String get parkingRequestSent =>
      'Запрос на открытие ворот парковки отправлен';

  @override
  String get parkingRequestFailed => 'Не удалось отправить запрос для парковки';

  @override
  String get errorOccurred => 'Произошла ошибка';

  @override
  String get notifyArrivalTitle => 'Сообщить о прибытии';

  @override
  String get attendanceSaved => 'Данные о посещаемости сохранены';

  @override
  String get dailyInfoTitle => 'Ежедневная информация';

  @override
  String get studentDefaultName => 'Ученик';

  @override
  String get breakfast => 'Завтрак';

  @override
  String get lunch => 'Обед';

  @override
  String get snack => 'Полдник';

  @override
  String get didNotEat => 'Не ел';

  @override
  String get ateLittle => 'Поел немного';

  @override
  String get ateAll => 'Съел всё';

  @override
  String get moodTitle => 'Настроение';

  @override
  String get sleepTitle => 'Сон';

  @override
  String get moodHappy => 'Весёлый';

  @override
  String get moodSad => 'Грустный';

  @override
  String get moodTired => 'Уставший';

  @override
  String get moodPeaceful => 'Спокойный';

  @override
  String get moodAngry => 'Злой';

  @override
  String get sleepNone => 'Не спал';

  @override
  String get sleepLittle => 'Поспал немного';

  @override
  String get sleepSlept => 'Спал';

  @override
  String get studentNotFound => 'Ученик не найден.';

  @override
  String get savedAll => 'Все данные сохранены';

  @override
  String get saveError => 'Ошибка сохранения';

  @override
  String get plans => 'Планы';

  @override
  String get monthly => 'Ежемесячно';

  @override
  String get addPlan => 'Добавить план';

  @override
  String get fetch => 'Получить';

  @override
  String get noPlansYet => 'Планов пока не найдено';

  @override
  String get planFound => ' план(а) найдено.';

  @override
  String get planFetchError => 'Не удалось получить планы';

  @override
  String get planUploadSuccess => 'План успешно загружен';

  @override
  String get planUploadError => 'Не удалось загрузить план';

  @override
  String get permissionPhotosRequired =>
      'Требуется разрешение на доступ к фото';

  @override
  String get planSavedToGallery => 'План сохранён в галерею';

  @override
  String get planSaveFailed => 'Не удалось сохранить план';

  @override
  String error(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get selectFileCanceled => 'Файл не выбран';

  @override
  String get filePathError => 'Не удалось получить путь к файлу';

  @override
  String get loading => 'Загрузка';

  @override
  String get activityListTitle => 'Список мероприятий';

  @override
  String get activityDetailTitle => 'Детали мероприятия';

  @override
  String get newActivity => 'Создать новое мероприятие';

  @override
  String get createActivity => 'Создать мероприятие';

  @override
  String get activityDay => 'День мероприятия';

  @override
  String get activityTime => 'Время мероприятия';

  @override
  String get activityPlace => 'Место мероприятия';

  @override
  String get activityDescription => 'Описание';

  @override
  String get classes => 'Классы';

  @override
  String get updating => 'Обновление...';

  @override
  String get selectDayTime => 'Пожалуйста, выберите день и время мероприятия.';

  @override
  String get placeDescriptionEmpty => 'Место и описание не могут быть пустыми.';

  @override
  String get selectAtLeastOneClass => 'Необходимо выбрать хотя бы один класс.';

  @override
  String get fillAllFields => 'Необходимо заполнить все поля';

  @override
  String get activityCreated => 'Мероприятие успешно создано.';

  @override
  String get activityUpdated => 'Мероприятие обновлено';

  @override
  String get activityDeleted => 'Мероприятие удалено';

  @override
  String get activityCreateError => 'Не удалось создать мероприятие: ';

  @override
  String get activityUpdateError => 'Ошибка обновления: ';

  @override
  String get activityDeleteError => 'Ошибка удаления: ';

  @override
  String get noDeletePermission => 'У вас нет прав на удаление';

  @override
  String get noActivityYet => 'Мероприятий пока нет.';

  @override
  String get classLabel => 'Класс(ы)';

  @override
  String get placeLabel => 'Место';

  @override
  String get dateLabel => 'Дата';

  @override
  String get edit => 'Редактировать';

  @override
  String get editActivity => 'Редактировать мероприятие';

  @override
  String get guidance => 'Психологическая поддержка';

  @override
  String get guidanceTitle => 'ПСИХОЛОГИЧЕСКАЯ ПОДДЕРЖКА';

  @override
  String get measurement => 'Измерение';

  @override
  String get guidanceResult => 'Результат оценки';

  @override
  String get fillForm => 'Заполнить форму';

  @override
  String get getResult => 'Получить результат';

  @override
  String get scaleResultGraph => 'График результатов оценки';

  @override
  String get result => 'Результат';

  @override
  String get resultNotFound => 'Результат не найден';

  @override
  String get gelisim => 'Развитие';

  @override
  String get gelisimTitle => 'РАЗВИТИЕ';

  @override
  String get createGelisim => 'Создать новую запись';

  @override
  String get allOfThem => 'Все';

  @override
  String get growtType => 'Тип развития';

  @override
  String get newGrowth => 'Новая запись о развитии';

  @override
  String get students => 'Ученики';

  @override
  String get value => 'Значение';

  @override
  String get editGelisimTitle => 'Редактировать / Удалить запись';

  @override
  String get editGelisimButton => 'Редактировать запись';

  @override
  String get recordsFetchError => 'Не удалось получить записи';

  @override
  String get recordDeleted => 'Запись удалена';

  @override
  String get noRecordFound => 'Запись не найдена';

  @override
  String get gelisimDeleteConfirm =>
      'Эта запись о развитии будет безвозвратно удалена. Вы уверены?';

  @override
  String get noData => 'Нет данных';

  @override
  String get errKullaniciNoZorunlu => 'Требуется номер пользователя.';

  @override
  String get errKullaniciNo11Hane =>
      'Номер пользователя должен состоять из 11 цифр и содержать только цифры.';

  @override
  String get errKullaniciNoAyniRakam =>
      'Одна и та же цифра не может встречаться в номере пользователя 8 или более раз.';

  @override
  String get errKayitBulunamadi => 'Запись не найдена.';

  @override
  String get errSifreKilidiListesindeDegil =>
      'Этот пользователь отсутствует в списке блокировки паролей.';

  @override
  String get errSifreSon4HaneGuncellendi =>
      'Пароль был сброшен на последние 4 цифры номера телефона.';

  @override
  String get errKayitOkulaAitDegil =>
      'Запись не найдена или не принадлежит данной школе.';

  @override
  String get errTcknSifreHatali =>
      'Неверный TCKN или пароль. Пожалуйста, попробуйте снова.';

  @override
  String get errTcknSifreTipHatali =>
      'Неверный TCKN, пароль или тип пользователя. Пожалуйста, попробуйте снова.';

  @override
  String get errKullaniciKilitlendi =>
      'Учетная запись пользователя заблокирована. Слишком много неудачных попыток ввода пароля. Обратитесь к администратору школы.';

  @override
  String get errLisansDolmus =>
      'Срок действия лицензии истек. Обратитесь к администратору школы.';

  @override
  String get errDogrulamaBasarili => 'Проверка успешно выполнена.';

  @override
  String get errKisiBulunamadi => 'Человек не найден.';

  @override
  String get errKisiGuncellendi => 'Данные человека успешно обновлены.';

  @override
  String get errOkulBulunamadi => 'Школа не найдена.';

  @override
  String get errOkulSilmeHatasi =>
      'Произошла ошибка при удалении школы. Возможно, существуют связанные данные.';

  @override
  String get errGonderenKisiBulunamadi => 'Отправитель не найден.';

  @override
  String get errSiniflardaOgrenciYok =>
      'В указанных классах не найдено ни одного ученика.';

  @override
  String get errIcSunucuHatasi => 'Внутренняя ошибка сервера.';

  @override
  String get errMesajAliciYok =>
      'Получатели не найдены. Сообщение не было создано.';

  @override
  String get errMesajGonderildi => 'Сообщение успешно отправлено.';

  @override
  String get errAlanStudentTeacherYok =>
      'Не найдено ни одного действительного ученика или учителя.';

  @override
  String get errMesajKisiEklenmedi =>
      'К сообщению не был добавлен ни один получатель.';

  @override
  String get errDuyuruAliciYok =>
      'Получатели не найдены. Объявление не было создано.';

  @override
  String get errDuyuruGonderildi => 'Объявление успешно отправлено.';

  @override
  String get errGelisimTipiEklendi => 'Тип развития успешно добавлен.';

  @override
  String get errDuyuruKisiEklenmedi =>
      'К объявлению не был добавлен ни один получатель.';

  @override
  String get errGelisimTipiBulunamadi => 'Тип развития не найден.';

  @override
  String get errGelisimTipiSilindi => 'Тип развития успешно удален.';

  @override
  String get errGelisimTipiOkulaAitDegil =>
      'Этот тип развития не принадлежит данной школе.';

  @override
  String get errGelisimKayitEklendi => 'Запись о развитии успешно добавлена.';

  @override
  String get errGelisimKayitBulunamadi => 'Запись о развитии не найдена.';

  @override
  String get errGelisimKayitGuncellendi =>
      'Запись о развитии успешно обновлена.';

  @override
  String get errGelisimKayitSilindi => 'Запись о развитии успешно удалена.';

  @override
  String get errOgrenciBulunamadi => 'Ученик не найден.';

  @override
  String get errDesteklenmeyenIliski => 'Неподдерживаемый тип связи.';

  @override
  String get errAlanKisiBulunamadi =>
      'Не найдено ни одного подходящего человека.';

  @override
  String get errTcknParentDegil => 'Указанный TCKN не принадлежит родителю.';

  @override
  String get errParentOkulIdYok =>
      'Не удалось найти идентификатор школы родителя.';

  @override
  String get errParentStudentYok =>
      'Для данного родителя не найдено ни одного ученика.';

  @override
  String get errTcknBulunamadi => 'TCKN не найден.';

  @override
  String get errPersonOkulIdYok =>
      'Не удалось найти идентификатор школы для данного человека.';

  @override
  String get errOtpGecersiz => 'Недействительный OTP или запись не найдена.';

  @override
  String get errPersonSinifIdYok =>
      'Не удалось найти идентификатор класса для данного человека.';

  @override
  String get errTcknListesiBos => 'Список TCKN пуст.';

  @override
  String get errOlcekZatenTanimli => 'Эта шкала уже назначена данной школе.';

  @override
  String get errPersonOkulAtanmamis =>
      'Человек не найден или не назначен ни одной школе.';

  @override
  String get errTumSorularCevaplanmali => 'На все вопросы необходимо ответить.';

  @override
  String get errEksikSoruCevap =>
      'Отсутствуют или недействительны ответы на вопросы.';

  @override
  String get errGecersizSoruCevap => 'Недействительный вопрос или ответ.';

  @override
  String get errMinDegerMaxDegerdenBuyuk =>
      'min_value не может быть больше max_value.';

  @override
  String get errTcknZorunlu => 'TCKN обязателен.';

  @override
  String get errOgrenciHostesIliskisiYok =>
      'Для ученика не найдена связь с сопровождающим.';

  @override
  String get errPinEncryptionKeyYok =>
      'PinEncryption:Key не настроен. Укажите его в appsettings или через переменную среды PinEncryption__Key.';

  @override
  String get errPinEncryptionKeyUzunluk =>
      'PinEncryption:Key должен быть ровно 32 байта (Base64).';

  @override
  String get errPinEncBos => 'pin_enc пуст.';

  @override
  String get errPinEncFormat => 'Неподдерживаемый формат pin_enc.';

  @override
  String get errPinEncUzunluk => 'Недопустимая длина pin_enc.';
}
