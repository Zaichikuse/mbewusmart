import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ny', 'MW'),
  ];

  static bool isSupported(Locale? locale) {
    if (locale == null) return false;
    return supportedLocales.any(
      (supported) =>
          supported.languageCode == locale.languageCode ||
          (supported.languageCode == 'ny' &&
           (locale.languageCode == 'ny' || locale.countryCode == 'MW')),
    );
  }

  static Locale? getFallbackLocale(Locale? locale) {
    if (locale == null) return const Locale('en');
    if (locale.languageCode == 'en') return const Locale('en');
    if (locale.languageCode == 'ny' || locale.countryCode == 'MW') {
      return const Locale('ny', 'MW');
    }
    return const Locale('en');
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'MbewuSmart',
      'welcome': 'Welcome to MbewuSmart',
      'welcomeMessage': 'Detect crop diseases instantly',
      'goodMorning': 'Good morning',
      'goodAfternoon': 'Good afternoon',
      'goodEvening': 'Good evening',
      'greetingMorning': 'Good morning',
      'greetingAfternoon': 'Good afternoon',
      'greetingEvening': 'Good evening',
      'home': 'Home',
      'scan': 'Scan',
      'history': 'History',
      'settings': 'Settings',
      'profile': 'Profile',
      'logout': 'Logout',
      'scanCrop': 'Scan Crop',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'analyzing': 'Analyzing...',
      'processing': 'Processing image...',
      'diagnosisResult': 'Diagnosis Result',
      'healthy': 'Healthy',
      'diseased': 'Diseased',
      'pestDetected': 'Pest Detected',
      'nutrientDeficiency': 'Nutrient Deficiency',
      'unknown': 'Unknown',
      'confidence': 'Confidence',
      'recommendation': 'Recommendation',
      'saveResult': 'Save Result',
      'viewHistory': 'View History',
      'tryAgain': 'Try Again',
      'noHistory': 'No history yet',
      'noHistoryMessage': 'Start by scanning your crops',
      'recentScans': 'Recent Scans',
      'viewAll': 'View All',
      'noRecentScans': 'No recent scans',
      'startScanning': 'Start Scanning',
      'disease': 'Disease',
      'pest': 'Pest',
      'deficiency': 'Deficiency',
      'severity': 'Severity',
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'treatment': 'Treatment',
      'prevention': 'Prevention',
      'language': 'Language',
      'english': 'English',
      'chichewa': 'Chichewa',
      'selectLanguage': 'Select Language',
      'notifications': 'Notifications',
      'syncStatus': 'Sync Status',
      'lastSynced': 'Last Synced',
      'synced': 'Synced',
      'offline': 'Offline',
      'about': 'About',
      'version': 'Version',
      'login': 'Login',
      'signUp': 'Sign Up',
      'phoneNumber': 'Phone Number',
      'fullName': 'Full Name',
      'nationalId': 'National ID',
      'pin': '4-digit PIN',
      'pinOptional': 'PIN (Optional)',
      'enterPin': 'Enter PIN',
      'confirmPin': 'Confirm PIN',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      'register': 'Register',
      'continueText': 'Continue',
      'skip': 'Skip',
      'farmer': 'Farmer',
      'extensionOfficer': 'Extension Officer',
      'agricultureManager': 'Agriculture Manager',
      'agroDealer': 'Agro-Dealer',
      'selectRole': 'Select Your Role',
      'error': 'Error',
      'tryAgainLater': 'Please try again later',
      'noInternet': 'No internet connection',
      'invalidPhone': 'Please enter a valid phone number',
      'invalidId': 'Please enter a valid National ID',
      'pinMismatch': 'PINs do not match',
      'pinTooShort': 'PIN must be 4 digits',
      'requiredField': 'This field is required',
      'loading': 'Loading...',
      'cameraPermission': 'Camera Permission Required',
      'cameraPermissionMessage': 'Please allow camera access to scan your crops',
      'permissionDenied': 'Permission Denied',
      'openSettings': 'Open Settings',
      'savedSuccessfully': 'Saved Successfully',
      'deletedSuccessfully': 'Deleted Successfully',
      'syncNow': 'Sync Now',
      'syncing': 'Syncing...',
      'crops': 'Crops',
      'diseases': 'Diseases',
      'pests': 'Pests',
      'alerts': 'Alerts',
      'weather': 'Weather',
      'marketPrices': 'Market Prices',
      'reports': 'Reports',
      'contactExtensionOfficer': 'Contact Extension Officer',
      'contactAgroDealer': 'Contact Agro Dealer',
      'reportToManager': 'Report to Manager',
      'sendMessage': 'Send Message',
      'typeMessage': 'Type a message...',
      'noMessages': 'No messages yet',
      'startConversation': 'Start a conversation',
      'newMessage': 'New Message',
      'notificationsTitle': 'Notifications',
      'noNotifications': 'No notifications',
      'diseaseReported': 'New disease reported',
      'inEPA': 'in',
      'extensionPlanningArea': 'Extension Planning Area',
      'epa': 'EPA',
      'nearbyHelp': 'Nearby Help',
      'findOfficers': 'Find Officers',
      'findDealers': 'Find Dealers',
      'communicate': 'Communicate',
      'retry': 'Retry',
      'sendReport': 'Send Report',
      'reportDisease': 'Report Disease',
      'uploadPhoto': 'Upload Photo',
    },
    'ny': {
      'appTitle': 'MbewuSmart',
      'welcome': 'Moni pa MbewuSmart',
      'welcomeMessage': 'peza matenda a mindu mwachangu',
      'goodMorning': 'Mwadzuka bwanji?',
      'goodAfternoon': 'Mwaswera bwanji?',
      'goodEvening': 'Mwaswera bwanji?',
      'greetingMorning': 'Mwadzuka bwanji',
      'greetingAfternoon': 'Mwaswera bwanji',
      'greetingEvening': 'Mwaswera bwanji',
      'home': 'Mphamvu',
      'scan': 'Tani',
      'history': 'Mbiri',
      'settings': 'Zochitika',
      'profile': 'Profile',
      'logout': 'Tuluka',
      'scanCrop': 'Tani Yanga',
      'takePhoto': 'Tenga Photo',
      'chooseFromGallery': 'Sankha Ku Gallery',
      'analyzing': 'Kusanaliza...',
      'processing': 'Kuchita na fasiki...',
      'diagnosisResult': 'Zotsatira Za Tchizo',
      'healthy': 'Kwauchipuka',
      'diseased': 'Mulwiro',
      'pestDetected': 'Khumani Wabwino',
      'nutrientDeficiency': 'Vuto LA Chakudya',
      'unknown': 'Sodziwika',
      'confidence': 'Chikhululuki',
      'recommendation': 'Ndemanga',
      'saveResult': 'Sunga Zotsatira',
      'viewHistory': 'Onani Mbiri',
      'tryAgain': 'Yesani Kenako',
      'noHistory': 'Palibe mbiri',
      'noHistoryMessage': 'Yambani pochita tani ya mindu yanu',
      'recentScans': 'Ma Scan Otsatsa',
      'viewAll': 'Onani Zonse',
      'noRecentScans': 'Palibe ma scan otsatsa',
      'startScanning': 'Yamba Kutanitsa',
      'disease': 'Matenda',
      'pest': 'Khumani',
      'deficiency': 'Vuto',
      'severity': 'Kukula',
      'low': 'Yochepa',
      'medium': 'Ya Pakati',
      'high': 'Yakulu',
      'treatment': 'Gwiyirani',
      'prevention': 'Cholinga',
      'language': 'Chilankhulo',
      'english': 'Chingerezi',
      'chichewa': 'Chichewa',
      'selectLanguage': 'Sankha Chilankhulo',
      'notifications': 'Zizindikiro',
      'syncStatus': 'Mmene Ogwirizana',
      'lastSynced': 'Oyamba Ogwirizana',
      'synced': 'Ogwirizanidwa',
      'offline': 'Wojikira',
      'about': 'Za App',
      'version': 'Version',
      'login': 'Lowani',
      'signUp': 'Lembani',
      'phoneNumber': 'Nambala Ya Fonu',
      'fullName': 'Dzina Lonse',
      'nationalId': 'ID Yoyenera',
      'pin': 'PIN Ya Digidi 4',
      'pinOptional': 'PIN (Osiya)',
      'enterPin': 'Lowa PIN',
      'confirmPin': 'Confirm PIN',
      'dontHaveAccount': 'Palibe account?',
      'alreadyHaveAccount': 'Mali account?',
      'register': 'Register',
      'continueText': 'Pitirizani',
      'skip': 'S.skip',
      'farmer': 'Mlimi',
      'extensionOfficer': 'Afesa Officer',
      'agricultureManager': 'Manager Waulimi',
      'agroDealer': 'Agro-Dealer',
      'selectRole': 'Sankha Umodzi Wanu',
      'error': 'Vuto',
      'tryAgainLater': 'Chonde yesani kenako',
      'noInternet': 'Palibe intaneti',
      'invalidPhone': 'Chonde lowa nambala yoyenera ya fonu',
      'invalidId': 'Chonde lowa ID yoyenera',
      'pinMismatch': 'PIN zosiyana',
      'pinTooShort': 'PIN iyenera kukhala digit 4',
      'requiredField': 'Fani ili yofunika',
      'loading': 'Kuloader...',
      'cameraPermission': 'Kupezeka Kwa Camera Kufunika',
      'cameraPermissionMessage': 'Chonde loleni kugwiritsa ntchito camera kuti mutani yanu',
      'permissionDenied': 'Permission sikuyenera',
      'openSettings': 'Fungula Zochitika',
      'savedSuccessfully': 'Sungidwa',
      'deletedSuccessfully': 'Fatsidwa',
      'syncNow': 'Sync pano',
      'syncing': 'Kusink...',
      'crops': 'Mindu',
      'diseases': 'Matenda',
      'pests': 'Khumani',
      'alerts': 'Mauthenga',
      'weather': 'Njira Yanga',
      'marketPrices': 'Mphalango',
      'reports': 'Ma Report',
      'contactExtensionOfficer': 'Lowa Fono la Afesa Officer',
      'contactAgroDealer': 'Lowa Fono la Agro Dealer',
      'reportToManager': 'Report kwa Manager',
      'sendMessage': 'Tumiza Uthenga',
      'typeMessage': 'Lemba uthenga...',
      'noMessages': 'Palibe uthenga',
      'startConversation': 'Yamba kukambirana',
      'newMessage': 'Uthenga Watsopano',
      'notificationsTitle': 'Mauthenga',
      'noNotifications': 'Palibe mauthenga',
      'diseaseReported': 'Matendaatsopano',
      'inEPA': 'm\'EPA',
      'extensionPlanningArea': 'Extension Planning Area',
      'epa': 'EPA',
      'nearbyHelp': 'Thandizo Langa',
      'findOfficers': 'Pezani Ma Officer',
      'findDealers': 'Pezani Ma Dealer',
      'communicate': 'Kukambirana',
      'retry': 'Yesani Kenako',
      'sendReport': 'Tumiza Report',
      'reportDisease': 'Report Matenda',
      'uploadPhoto': 'Lemba Chithunzi',
    },
  };

  String _translate(String key) {
    String effectiveLocale = locale.languageCode;
    if (locale.countryCode != null) {
      effectiveLocale = '${locale.languageCode}_${locale.countryCode}';
    }

    final localeMap = _localizedValues[effectiveLocale] ??
                       _localizedValues[locale.languageCode] ??
                       _localizedValues['en'];
    
    return localeMap?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  String get appTitle => _translate('appTitle');
  String get welcome => _translate('welcome');
  String get welcomeMessage => _translate('welcomeMessage');
  String get goodMorning => _translate('goodMorning');
  String get goodAfternoon => _translate('goodAfternoon');
  String get goodEvening => _translate('goodEvening');
  String get greetingMorning => _translate('greetingMorning');
  String get greetingAfternoon => _translate('greetingAfternoon');
  String get greetingEvening => _translate('greetingEvening');
  String get home => _translate('home');
  String get scan => _translate('scan');
  String get history => _translate('history');
  String get settings => _translate('settings');
  String get profile => _translate('profile');
  String get logout => _translate('logout');
  String get scanCrop => _translate('scanCrop');
  String get takePhoto => _translate('takePhoto');
  String get chooseFromGallery => _translate('chooseFromGallery');
  String get analyzing => _translate('analyzing');
  String get processing => _translate('processing');
  String get diagnosisResult => _translate('diagnosisResult');
  String get healthy => _translate('healthy');
  String get diseased => _translate('diseased');
  String get pestDetected => _translate('pestDetected');
  String get nutrientDeficiency => _translate('nutrientDeficiency');
  String get unknown => _translate('unknown');
  String get confidence => _translate('confidence');
  String get recommendation => _translate('recommendation');
  String get saveResult => _translate('saveResult');
  String get viewHistory => _translate('viewHistory');
  String get tryAgain => _translate('tryAgain');
  String get noHistory => _translate('noHistory');
  String get noHistoryMessage => _translate('noHistoryMessage');
  String get recentScans => _translate('recentScans');
  String get viewAll => _translate('viewAll');
  String get noRecentScans => _translate('noRecentScans');
  String get startScanning => _translate('startScanning');
  String get disease => _translate('disease');
  String get pest => _translate('pest');
  String get deficiency => _translate('deficiency');
  String get severity => _translate('severity');
  String get low => _translate('low');
  String get medium => _translate('medium');
  String get high => _translate('high');
  String get treatment => _translate('treatment');
  String get prevention => _translate('prevention');
  String get language => _translate('language');
  String get english => _translate('english');
  String get chichewa => _translate('chichewa');
  String get selectLanguage => _translate('selectLanguage');
  String get notifications => _translate('notifications');
  String get syncStatus => _translate('syncStatus');
  String get lastSynced => _translate('lastSynced');
  String get synced => _translate('synced');
  String get offline => _translate('offline');
  String get about => _translate('about');
  String get version => _translate('version');
  String get login => _translate('login');
  String get signUp => _translate('signUp');
  String get phoneNumber => _translate('phoneNumber');
  String get fullName => _translate('fullName');
  String get nationalId => _translate('nationalId');
  String get pin => _translate('pin');
  String get pinOptional => _translate('pinOptional');
  String get enterPin => _translate('enterPin');
  String get confirmPin => _translate('confirmPin');
  String get dontHaveAccount => _translate('dontHaveAccount');
  String get alreadyHaveAccount => _translate('alreadyHaveAccount');
  String get register => _translate('register');
  String get continueText => _translate('continueText');
  String get skip => _translate('skip');
  String get farmer => _translate('farmer');
  String get extensionOfficer => _translate('extensionOfficer');
  String get agricultureManager => _translate('agricultureManager');
  String get agroDealer => _translate('agroDealer');
  String get selectRole => _translate('selectRole');
  String get error => _translate('error');
  String get tryAgainLater => _translate('tryAgainLater');
  String get noInternet => _translate('noInternet');
  String get invalidPhone => _translate('invalidPhone');
  String get invalidId => _translate('invalidId');
  String get pinMismatch => _translate('pinMismatch');
  String get pinTooShort => _translate('pinTooShort');
  String get requiredField => _translate('requiredField');
  String get loading => _translate('loading');
  String get cameraPermission => _translate('cameraPermission');
  String get cameraPermissionMessage => _translate('cameraPermissionMessage');
  String get permissionDenied => _translate('permissionDenied');
  String get openSettings => _translate('openSettings');
  String get savedSuccessfully => _translate('savedSuccessfully');
  String get deletedSuccessfully => _translate('deletedSuccessfully');
  String get syncNow => _translate('syncNow');
  String get syncing => _translate('syncing');
  String get crops => _translate('crops');
  String get diseases => _translate('diseases');
  String get pests => _translate('pests');
  String get alerts => _translate('alerts');
  String get weather => _translate('weather');
  String get marketPrices => _translate('marketPrices');
  String get reports => _translate('reports');
  String get contactExtensionOfficer => _translate('contactExtensionOfficer');
  String get contactAgroDealer => _translate('contactAgroDealer');
  String get reportToManager => _translate('reportToManager');
  String get sendMessage => _translate('sendMessage');
  String get typeMessage => _translate('typeMessage');
  String get noMessages => _translate('noMessages');
  String get startConversation => _translate('startConversation');
  String get newMessage => _translate('newMessage');
  String get notificationsTitle => _translate('notificationsTitle');
  String get noNotifications => _translate('noNotifications');
  String get diseaseReported => _translate('diseaseReported');
  String get inEPA => _translate('inEPA');
  String get extensionPlanningArea => _translate('extensionPlanningArea');
  String get epa => _translate('epa');
  String get nearbyHelp => _translate('nearbyHelp');
  String get findOfficers => _translate('findOfficers');
  String get findDealers => _translate('findDealers');
  String get communicate => _translate('communicate');
  String get retry => _translate('retry');
  String get sendReport => _translate('sendReport');
  String get reportDisease => _translate('reportDisease');
  String get uploadPhoto => _translate('uploadPhoto');

  String translate(String key) => _translate(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.isSupported(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final effectiveLocale = AppLocalizations.isSupported(locale)
        ? locale
        : AppLocalizations.getFallbackLocale(locale) ?? const Locale('en');
    return AppLocalizations(effectiveLocale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
