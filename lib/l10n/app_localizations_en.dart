// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Okul';

  @override
  String get userCode => 'User Code';

  @override
  String get login => 'Login';

  @override
  String get userType => 'User Type';

  @override
  String get password => 'Password';

  @override
  String get enter => 'Enter';

  @override
  String get galleries => 'Galleries';

  @override
  String get welcome => 'Welcome';

  @override
  String get err => 'Error';

  @override
  String get userEmpty => 'User Code cannot be empty';

  @override
  String get userLength => 'User Code must be 11 characters';

  @override
  String get userHint => '11 characters User Code please';

  @override
  String get pswHint => 'Password please';

  @override
  String get pswEmpty => 'Password cannot be empty';

  @override
  String get teacher => 'Teacher';

  @override
  String get parent => 'Parent';

  @override
  String get manager => 'Manager';

  @override
  String get hostes => 'Hostes';

  @override
  String get enterLoading => 'Entering...';

  @override
  String get enterError => 'An error occurred. Please try again.';

  @override
  String get pswForget => 'I lost my password';

  @override
  String get messages => 'MESSAGES';

  @override
  String get gallery => 'GALLERY';

  @override
  String get notification => 'NOTIFICATION';

  @override
  String get profile => 'PROFILE';

  @override
  String get anouncement => 'ANOUNCEMENT';

  @override
  String get attendance => 'ATTENDANCE';

  @override
  String get medicine => 'MEDICINE';

  @override
  String get gateControl => 'GATE CONTROL';

  @override
  String get activities => 'ACTIVITIES';

  @override
  String get daily => 'DAILY';

  @override
  String get mealList => 'MEAL LIST';

  @override
  String get survey => 'SURVEYS';

  @override
  String get qrCode => 'QR CODE';

  @override
  String get homework => 'HOMEWORK';

  @override
  String get studentNotification => 'Student Noitification';

  @override
  String get notification1 => 'Left';

  @override
  String get notification2 => 'Near';

  @override
  String get notification3 => 'Took';

  @override
  String get notification4 => 'Came';

  @override
  String get mainScreen => 'Main Screen';

  @override
  String get studentLengthMsg => 'At least one student must be selected';

  @override
  String get notificationSuccessMsg => 'Notification sent';

  @override
  String get notificationFailMsg => 'Notification not sent';

  @override
  String get teachersTitle => 'Teachers';

  @override
  String get teacherNotFound => 'No teachers found';

  @override
  String get unnamedTeacher => 'Unnamed Teacher';

  @override
  String get parentMessages => 'Parent Messages';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get conversationWarning =>
      '* Conversation content is monitored by school administration';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get studentListNotLoaded => 'Student list not loaded';

  @override
  String get selectStudentsTitle => 'Select Students';

  @override
  String get selectAll => 'Select All';

  @override
  String get cancel => 'Cancel';

  @override
  String get contin => 'Continue';

  @override
  String get noStudentSelected => 'No student selected';

  @override
  String galleryLoadError(Object error) {
    return 'Gallery could not be loaded: $error';
  }

  @override
  String get photoPermissionRequired => 'Photo permission required';

  @override
  String get mediaSavedToGallery => 'Media saved to gallery';

  @override
  String get mediaSaveFailed => 'Failed to save to gallery';

  @override
  String errorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get deleteMediaTitle => 'Delete Media';

  @override
  String get deleteMediaConfirm =>
      'This media will be permanently deleted. Are you sure?';

  @override
  String get delete => 'Delete';

  @override
  String get mediaDeleted => 'Media deleted';

  @override
  String deleteFailed(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get uploading => 'Uploading...';

  @override
  String get addMedia => 'Add Media';

  @override
  String get mealScreenTitle => 'Meal List';

  @override
  String get mealNotFound => 'Meal list not found.';

  @override
  String get mealBreakfast => 'Breakfast:';

  @override
  String get mealLunch => 'Lunch:';

  @override
  String get mealSnack => 'Afternoon Snack:';

  @override
  String mealDateHeader(Object date) {
    return '$date';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get userInfoTitle => '👤 User Information';

  @override
  String get studentsTitle => '👧 Students';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get parentInfoTitle => '👪 Parent Information';

  @override
  String get labelFullName => 'Full Name:';

  @override
  String get labelProfession => 'Profession:';

  @override
  String get labelHobby => 'Hobby:';

  @override
  String get labelPhone => 'Phone:';

  @override
  String get close => 'Close';

  @override
  String get labelAllergy => 'Allergy:';

  @override
  String get labelMedicine => 'Medication:';

  @override
  String get labelClass => 'Class:';

  @override
  String get labelSchoolNumber => 'School No:';

  @override
  String get qrOrCodeCreateTitle => 'Create QR / Code';

  @override
  String get receiverLabel => 'Receiver';

  @override
  String get receiverHint => 'Enter receiver name';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get createQrButton => 'Create QR';

  @override
  String get createCodeButton => 'Create Code';

  @override
  String get generatedResultTitle => 'Generated Result';

  @override
  String get copyButton => 'Copy';

  @override
  String get copiedSnackBar => 'Copied';

  @override
  String get shareButton => 'Share';

  @override
  String get qrVerifyTitle => 'QR / Code Verification';

  @override
  String get tabQrScan => 'Scan QR';

  @override
  String get tabManualCode => 'Enter Code';

  @override
  String get cameraInstruction => 'Please point the camera at a QR code';

  @override
  String get copiedToClipboard => 'Code copied to clipboard';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get otpLabel => 'OTP Code';

  @override
  String get verifyButton => 'Verify';

  @override
  String get otpEmptyError => 'OTP cannot be empty';

  @override
  String get verifySuccessTitle => '✅ Code Verified:';

  @override
  String get verifyInvalid => '❌ OTP is invalid or expired';

  @override
  String verifyPersonLine(Object logName, Object personName) {
    return '• $logName - $personName';
  }

  @override
  String get attendanceStatusTitle => 'Attendance Status';

  @override
  String get unknownStudent => 'Unknown';

  @override
  String get attendanceNotFound => 'No attendance record found.';

  @override
  String get attended => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get medicineListTitle => 'Medicine List';

  @override
  String get createNewMedicine => 'Create New Medicine';

  @override
  String get noMedicineYet => 'No medicine record yet.';

  @override
  String get medicineDetailTitle => 'Medicine Detail';

  @override
  String get description => 'Description';

  @override
  String get noDescription => 'None';

  @override
  String get ok => 'OK';

  @override
  String get create => 'Create';

  @override
  String get creating => 'Creating...';

  @override
  String get createMedicineTitle => 'Create New Medicine Record';

  @override
  String get medicineStartDay => 'Medicine Start Date';

  @override
  String get medicineEndDay => 'Medicine End Date';

  @override
  String get medicineTime => 'Medicine Time';

  @override
  String get selectStudent => 'Select Student:';

  @override
  String get fillAllDateFields => 'Please fill all date fields.';

  @override
  String get selectStudentError => 'You must select a student.';

  @override
  String get medicineCreated => 'Medicine record created successfully.';

  @override
  String get deleteMedicineTitle => 'Delete Medicine Record';

  @override
  String get deleteMedicineConfirm =>
      'This medicine record will be deleted. Are you sure?';

  @override
  String get medicineDeactivated => 'Medicine record deleted.';

  @override
  String get date => 'Date';

  @override
  String get student => 'Student';

  @override
  String get homeworkTitle => 'Homework';

  @override
  String get createHomework => 'Create Homework';

  @override
  String get noHomeworkYet => 'No homework yet.';

  @override
  String get homeworkDetailTitle => 'Homework Detail';

  @override
  String get lesson => 'Lesson';

  @override
  String get dueDate => 'Due Date';

  @override
  String get attachedFiles => 'Attached Files';

  @override
  String get fileOpenError => 'File cannot be opened';

  @override
  String get file => 'File';

  @override
  String get deleteHomeworkTitle => 'Delete Homework';

  @override
  String get deleteHomeworkConfirm =>
      'This homework will be deleted. Are you sure?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get homeworkDeleted => 'Homework deleted';

  @override
  String get homeworkNotFound => 'Homework not found';

  @override
  String get deleteError => 'Delete error';

  @override
  String get update => 'Update';

  @override
  String get newHomeworkTitle => 'Create New Homework';

  @override
  String get lessonRequired => 'Lesson *';

  @override
  String get descriptionRequired => 'Description *';

  @override
  String get dueDateRequired => 'Due Date *';

  @override
  String get addFile => 'Add File';

  @override
  String get save => 'Save';

  @override
  String get fillRequiredFields => 'Fill required fields';

  @override
  String get lessonDetail => 'Lesson Detail';

  @override
  String get surveyListTitle => 'Survey List';

  @override
  String get newSurvey => 'Create New Survey';

  @override
  String get noSurvey => 'No surveys available yet.';

  @override
  String get send => 'Send';

  @override
  String get answer => 'Answer';

  @override
  String get unanswered => 'Unanswered';

  @override
  String get answerDetails => 'Answer Details';

  @override
  String get noAnswer => 'No Answer';

  @override
  String get deleteConfirmTitle => 'Delete Confirmation';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this activity?';

  @override
  String get deleteSuccess => 'Activity deleted';

  @override
  String get deleteNoPermission => 'You do not have permission to delete';

  @override
  String get submitError => 'Answer could not be sent';

  @override
  String get noTitle => 'No Title';

  @override
  String get doorControlTitle => 'Door Control Panel';

  @override
  String get mainGateControl => 'Main Gate Control';

  @override
  String get parkingControl => 'Parking Control';

  @override
  String get mainGateRequestSent => 'Main gate opening request sent';

  @override
  String get mainGateRequestFailed => 'Main gate request failed';

  @override
  String get parkingRequestSent => 'Parking gate opening request sent';

  @override
  String get parkingRequestFailed => 'Parking request failed';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get notifyArrivalTitle => 'Notify Arrival';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String get dailyInfoTitle => 'Daily Information';

  @override
  String get studentDefaultName => 'Student';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get snack => 'Snack';

  @override
  String get didNotEat => 'Did not eat';

  @override
  String get ateLittle => 'Ate a little';

  @override
  String get ateAll => 'Ate all';

  @override
  String get moodTitle => 'Mood';

  @override
  String get sleepTitle => 'Sleep';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodPeaceful => 'Peaceful';

  @override
  String get moodAngry => 'Angry';

  @override
  String get sleepNone => 'Did not sleep';

  @override
  String get sleepLittle => 'Slept a little';

  @override
  String get sleepSlept => 'Slept';

  @override
  String get studentNotFound => 'Student not found.';

  @override
  String get savedAll => 'All information saved';

  @override
  String get saveError => 'Save error';

  @override
  String get plans => 'Plans';

  @override
  String get monthly => 'Monthly';

  @override
  String get addPlan => 'Add Plan';

  @override
  String get fetch => 'Fetch';

  @override
  String get noPlansYet => 'No plans found yet';

  @override
  String get planFound => ' plans found.';

  @override
  String get planFetchError => 'Could not fetch plans';

  @override
  String get planUploadSuccess => 'Plan uploaded successfully';

  @override
  String get planUploadError => 'Plan upload failed';

  @override
  String get permissionPhotosRequired => 'Photo permission required';

  @override
  String get planSavedToGallery => 'Plan saved to gallery';

  @override
  String get planSaveFailed => 'Failed to save to plan';

  @override
  String error(Object error) {
    return 'Error: $error';
  }

  @override
  String get selectFileCanceled => 'No file selected';

  @override
  String get filePathError => 'File path could not be retrieved';

  @override
  String get loading => 'Loading';

  @override
  String get activityListTitle => 'Activity List';

  @override
  String get activityDetailTitle => 'Activity Detail';

  @override
  String get newActivity => 'Create New Activity';

  @override
  String get createActivity => 'Create Activity';

  @override
  String get activityDay => 'Activity Day';

  @override
  String get activityTime => 'Activity Time';

  @override
  String get activityPlace => 'Activity Place';

  @override
  String get activityDescription => 'Description';

  @override
  String get classes => 'Classes';

  @override
  String get updating => 'Updating...';

  @override
  String get selectDayTime => 'Please select activity day and time.';

  @override
  String get placeDescriptionEmpty => 'Place and description cannot be empty.';

  @override
  String get selectAtLeastOneClass => 'You must select at least one class.';

  @override
  String get fillAllFields => 'All fields must be filled';

  @override
  String get activityCreated => 'Activity created successfully.';

  @override
  String get activityUpdated => 'Activity updated';

  @override
  String get activityDeleted => 'Activity deleted';

  @override
  String get activityCreateError => 'Activity could not be created: ';

  @override
  String get activityUpdateError => 'Update error: ';

  @override
  String get activityDeleteError => 'Delete error: ';

  @override
  String get noDeletePermission => 'You do not have permission to delete';

  @override
  String get noActivityYet => 'No activities yet.';

  @override
  String get classLabel => 'Class(es)';

  @override
  String get placeLabel => 'Place';

  @override
  String get dateLabel => 'Date';

  @override
  String get edit => 'Edit';

  @override
  String get editActivity => 'Edit Activity';

  @override
  String get guidance => 'Guidance';

  @override
  String get guidanceTitle => 'GUIDANCE';

  @override
  String get measurement => 'Measurenent';

  @override
  String get guidanceResult => 'Guidance Result';

  @override
  String get fillForm => 'Fill Form';

  @override
  String get getResult => 'Get Result';

  @override
  String get scaleResultGraph => 'Scale Result Graph';

  @override
  String get result => 'Result';

  @override
  String get resultNotFound => 'Result not found';

  @override
  String get gelisim => 'Growth';

  @override
  String get gelisimTitle => 'GROWTH';

  @override
  String get createGelisim => 'Create New Record';

  @override
  String get allOfThem => 'All';

  @override
  String get growtType => 'Growth Type';

  @override
  String get newGrowth => 'New Growth Record';

  @override
  String get students => 'Students';

  @override
  String get value => 'Value';

  @override
  String get editGelisimTitle => 'Edit / Delete Record';

  @override
  String get editGelisimButton => 'Edit Record';

  @override
  String get recordsFetchError => 'Could not fetch records';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get noRecordFound => 'No record found';

  @override
  String get gelisimDeleteConfirm =>
      'This growth record will be permanently deleted. Are you sure?';

  @override
  String get noData => 'No data';
}
