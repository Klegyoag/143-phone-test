import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ta'), Locale('si')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const _values = <String, Map<String, String>>{
    'en': {
      'startupError': '143 could not finish startup. Please try again.',
      'appUpdates': 'App Updates', 'appUpdatesSubtitle': 'Check release compatibility without embedding store secrets.', 'installedVersion': 'Installed version', 'latestVersion': 'Latest version', 'updateAvailable': 'Update available', 'updateRequired': 'Update required', 'upToDate': 'You’re up to date', 'versionUnknown': 'Latest version was not supplied.', 'updateCheckFailed': 'Could not check for updates', 'updateCheckNotConfigured': 'Update check not configured', 'updateCheckBoundaryBody': 'Set an HTTPS APP_UPDATE_MANIFEST_URL at build time. 143 does not invent a backend endpoint or embed store credentials.', 'openStoreUpdate': 'Open store to update', 'whatsNew': 'What’s New', 'openingWorld': 'Opening your little world…', 'restoringSession': 'Restoring your secure session…', 'checkingRecovery': 'Checking your recovery setup…', 'checkingLegal': 'Checking Terms & Privacy…', 'findingCouple': 'Finding your couple space…', 'retryStartup': 'Retry startup',
      'home': 'Home', 'memories': 'Memories', 'create': 'Create', 'chat': 'Chat', 'us': 'Us',
      'ourLittleWorld': 'Our little world', 'everythingForTwo': 'Everything that belongs to the two of you ♡',
      'save': 'Save', 'cancel': 'Cancel', 'retry': 'Retry', 'loading': 'Loading…',
      'settings': 'Settings', 'security': 'Security', 'privacy': 'Privacy', 'profile': 'My Profile',
      'games': 'Games', 'calendar': 'Calendar', 'goals': 'Goals', 'music': 'Our Music', 'distance': 'Distance',
      'insights': 'Insights', 'journeys': 'Journeys', 'achievements': 'Achievements', 'preferences': 'Preferences',
      'appearance': 'Appearance', 'ourStory': 'Our Story', 'jarsBucket': 'Jars & Bucket', 'ourLists': 'Our Lists',
      'ai143': '143 AI', 'together': 'Together', 'needYou': 'Need You', 'moodNeedYouTitle': 'Mood & Need You', 'tinySignalTitle': 'A tiny signal can say a lot.', 'tinySignalBody': 'Share only what you choose. Need You is always explicit and user-initiated.', 'howFeeling': 'How are you feeling?', 'shareMood': 'Share mood', 'moodShared': 'Mood shared', 'needYouGentleBody': 'A distinctive but gentle signal to your person.', 'sendNeedYou': 'Send “I need you”', 'needYouSent': 'Need You sent gently ♡', 'messageAction': 'Message', 'callAction': 'Call', 'sendLoveAction': 'Send Love', 'callFromChatHint': 'Open Chat and choose Call.', 'touchHold': 'Touch / Hold', 'touchHoldHint': 'Press and release to send a gentle touch', 'touchActive': 'Touch active', 'touchReady': 'Ready to touch', 'scheduledLove': 'Scheduled Love', 'reconnect': 'Reconnect',
      'smartDate': 'Smart Date', 'budget': 'Budget', 'helpData': 'Help & Data', 'littleWorldSubtitle': 'Everything that belongs to the two of you ♡',
'widgets': 'Widgets', 'backup': 'Backup', 'devices': 'Devices',
      'done': 'Done', 'answer': 'Answer', 'decline': 'Decline', 'incomingAudioCall': 'Incoming audio call ♡', 'incomingVideoCall': 'Incoming video call ♡',
      'personCalling': 'Your person is calling.', 'pingReceived': 'Your person sent you a little love ♡', 'needYouReceived': 'Your person needs you right now ♡',
      'achievementUnlocked': 'A new couple achievement unlocked ✨', 'dailyRevealReady': 'Both daily answers are ready to reveal ♡', 'surpriseUnlocked': 'A surprise is ready for you ✨',
      'lockedTitle': 'Your private space is locked', 'lockedBody': 'Unlock with your local PIN or your device authentication.', 'unlockPin': 'Unlock with PIN',
      'useDeviceAuth': 'Use device authentication', 'tooManyAttempts': 'Too many attempts. PIN unlock is temporarily paused.', 'pinMismatch': 'That PIN did not match.',
      'notifications': 'Notifications', 'newNotification': 'New notification', 'open': 'Open', 'enable': 'Enable', 'deviceNotifications': 'Device notifications', 'deviceNotificationsBody': 'Turn on FCM/APNs alerts only when you choose. 143 never asks automatically at startup.', 'pushAuthorized': 'Allowed by this device', 'pushProvisional': 'Quiet/provisional permission is active', 'pushDenied': 'Blocked in device settings', 'pushNotRequested': 'Not requested yet', 'pushEnabled': 'Device notifications are enabled.', 'pushEnableFailed': 'Could not enable device notifications.', 'readAll': 'Read all', 'allQuiet': 'All quiet for now ♡', 'notificationPreferences': 'Notification Preferences', 'stayCloseWithoutNoise': 'Stay close without noise', 'notificationPrefsBody': 'Choose the kinds of updates you want. Phone notification permission is managed separately.', 'hapticsVibration': 'Vibration & haptics', 'hapticsBody': 'Allow gentle vibration for pings, Need You and touch interactions.', 'reduceMotion': 'Reduce motion', 'reduceMotionBody': 'Uses calmer transitions when motion is uncomfortable.', 'messagesPref': 'Messages', 'messagesPrefBody': 'New couple chat messages and replies.', 'pingsPref': 'Pings & hugs', 'pingsPrefBody': 'Romantic pings and Need You moments.', 'memoriesPref': 'Memories', 'memoriesPrefBody': 'Comments, reactions and Time Capsule reveals.', 'callsPref': 'Calls', 'callsPrefBody': 'Incoming audio/video call alerts.', 'calendarPref': 'Dates & reminders', 'calendarPrefBody': 'Shared calendar and special-day reminders.', 'dailyPref': 'Daily connection', 'dailyPrefBody': 'Daily question, appreciation and reveal updates.', 'achievementsPref': 'Achievements', 'achievementsPrefBody': 'Healthy connection milestones and rewards.',
      'quickPing': 'Quick Ping', 'sendLittleLove': 'Send a little love?', 'quickPingConsent': '143 will send a gentle ping only after you confirm here.', 'sendPing': 'Send Ping',
      'sending': 'Sending…', 'pingSent': 'Sent with love ♡', 'pingSentDetail': 'Your person will receive your ping according to their notification and haptic preferences.',
      'togetherRoom': 'Together Room', 'refreshResync': 'Refresh & resync', 'startTogether': 'Start something together', 'youreTogether': 'You’re together',
      'sharedQueue': 'Shared queue', 'queueEmpty': 'Your shared queue is empty', 'privateByDefault': 'Private by default ♡', 'partnerStatus': 'Partner status', 'quickPingWidget': 'Quick Ping',
      'appearanceAccessibility': 'Appearance & Accessibility', 'systemTheme': 'System', 'lightTheme': 'Light', 'darkTheme': 'Dark', 'textSize': 'Text size',
      'accessibility': 'Accessibility', 'higherContrast': 'Higher contrast', 'higherContrastBody': 'Makes text and controls easier to distinguish.', 'language': 'Language',
      'readableLoveSample': 'Love should be easy to read ♡', 'languageAppliesImmediately': 'Language changes apply immediately to localized screens. Remaining legacy strings are being migrated before release.',
      'providerReadiness': 'Provider & Device Readiness', 'securityReviewRequired': 'Security review required',
    },
    'ta': {
      'startupError': '143 startup-ஐ முடிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      'appUpdates': 'ஆப் புதுப்பிப்புகள்', 'appUpdatesSubtitle': 'Store ரகசியங்களை சேர்க்காமல் release compatibility-ஐ சரிபார்க்கவும்.', 'installedVersion': 'நிறுவப்பட்ட பதிப்பு', 'latestVersion': 'புதிய பதிப்பு', 'updateAvailable': 'புதுப்பிப்பு உள்ளது', 'updateRequired': 'புதுப்பிப்பு அவசியம்', 'upToDate': 'உங்கள் ஆப் புதுப்பிக்கப்பட்டுள்ளது', 'versionUnknown': 'புதிய பதிப்பு வழங்கப்படவில்லை.', 'updateCheckFailed': 'புதுப்பிப்பை சரிபார்க்க முடியவில்லை', 'updateCheckNotConfigured': 'புதுப்பிப்பு சரிபார்ப்பு அமைக்கப்படவில்லை', 'updateCheckBoundaryBody': 'Build நேரத்தில் HTTPS APP_UPDATE_MANIFEST_URL அமைக்கவும். 143 போலியான backend endpoint அல்லது store credentials சேர்க்காது.', 'openStoreUpdate': 'Store-ஐ திறந்து புதுப்பிக்கவும்', 'whatsNew': 'புதியவை', 'openingWorld': 'உங்கள் சிறிய உலகம் திறக்கப்படுகிறது…', 'restoringSession': 'பாதுகாப்பான session மீட்கப்படுகிறது…', 'checkingRecovery': 'Recovery அமைப்பு சரிபார்க்கப்படுகிறது…', 'checkingLegal': 'Terms & Privacy சரிபார்க்கப்படுகிறது…', 'findingCouple': 'உங்கள் couple space தேடப்படுகிறது…', 'retryStartup': 'Startup மீண்டும் முயற்சி',
      'home': 'முகப்பு', 'memories': 'நினைவுகள்', 'create': 'உருவாக்கு', 'chat': 'அரட்டை', 'us': 'நாம்',
      'ourLittleWorld': 'நம்முடைய சிறிய உலகம்', 'everythingForTwo': 'உங்களிருவருக்குமான தனிப்பட்ட இடம் ♡',
      'save': 'சேமி', 'cancel': 'ரத்து', 'retry': 'மீண்டும் முயற்சி', 'loading': 'ஏற்றுகிறது…',
      'settings': 'அமைப்புகள்', 'security': 'பாதுகாப்பு', 'privacy': 'தனியுரிமை', 'profile': 'என் சுயவிவரம்',
      'games': 'விளையாட்டுகள்', 'calendar': 'நாட்காட்டி', 'goals': 'இலக்குகள்', 'music': 'நம்முடைய இசை', 'distance': 'தொலைவு',
      'insights': 'சுருக்கங்கள்', 'journeys': 'பயணங்கள்', 'achievements': 'சாதனைகள்', 'preferences': 'விருப்பங்கள்',
      'appearance': 'தோற்றம்', 'ourStory': 'நம்முடைய கதை', 'jarsBucket': 'ஜார்கள் & விருப்பப்பட்டியல்', 'ourLists': 'நம்முடைய பட்டியல்கள்',
      'ai143': '143 AI', 'together': 'ஒன்றாக', 'needYou': 'நீ வேண்டும்', 'moodNeedYouTitle': 'மூட் & நீ வேண்டும்', 'tinySignalTitle': 'ஒரு சிறிய சைகை பலத்தைச் சொல்லும்.', 'tinySignalBody': 'நீங்கள் விரும்புவது மட்டுமே பகிருங்கள். Need You எப்போதும் உங்கள் தெளிவான செயலால் தொடங்கும்.', 'howFeeling': 'இப்போது எப்படி உணர்கிறீர்கள்?', 'shareMood': 'மூட்டை பகிர்', 'moodShared': 'மூட் பகிரப்பட்டது', 'needYouGentleBody': 'உங்கள் துணைக்கு தனித்துவமான ஆனால் மென்மையான சைகை.', 'sendNeedYou': '“நீ வேண்டும்” அனுப்பு', 'needYouSent': 'Need You மென்மையாக அனுப்பப்பட்டது ♡', 'messageAction': 'செய்தி', 'callAction': 'அழைப்பு', 'sendLoveAction': 'அன்பு அனுப்பு', 'callFromChatHint': 'Chat-ஐ திறந்து Call-ஐ தேர்வு செய்யுங்கள்.', 'touchHold': 'தொடு / பிடி', 'touchHoldHint': 'மென்மையான touch அனுப்ப அழுத்தி விடுங்கள்', 'touchActive': 'Touch செயலில் உள்ளது', 'touchReady': 'Touch செய்ய தயார்', 'scheduledLove': 'திட்டமிட்ட அன்பு', 'reconnect': 'மீண்டும் இணை',
      'smartDate': 'ஸ்மார்ட் டேட்', 'budget': 'பட்ஜெட்', 'helpData': 'உதவி & தரவு', 'littleWorldSubtitle': 'உங்களிருவருக்குமான தனிப்பட்ட இடம் ♡',
'widgets': 'விட்ஜெட்கள்', 'backup': 'காப்புப்பிரதி', 'devices': 'சாதனங்கள்',
      'done': 'முடிந்தது', 'answer': 'பதில்', 'decline': 'நிராகரி', 'incomingAudioCall': 'வரும் குரல் அழைப்பு ♡', 'incomingVideoCall': 'வரும் வீடியோ அழைப்பு ♡',
      'personCalling': 'உங்கள் துணை அழைக்கிறார்.', 'pingReceived': 'உங்கள் துணை ஒரு சிறிய அன்பு பிங் அனுப்பினார் ♡', 'needYouReceived': 'உங்கள் துணைக்கு இப்போது நீங்கள் வேண்டும் ♡',
      'achievementUnlocked': 'புதிய ஜோடி சாதனை திறக்கப்பட்டது ✨', 'dailyRevealReady': 'இருவரின் தினசரி பதில்களும் பார்க்கத் தயாராக உள்ளன ♡', 'surpriseUnlocked': 'உங்களுக்கான சர்ப்ரைஸ் தயாராக உள்ளது ✨',
      'lockedTitle': 'உங்கள் தனிப்பட்ட இடம் பூட்டப்பட்டுள்ளது', 'lockedBody': 'உங்கள் உள்ளூர் PIN அல்லது சாதன அங்கீகாரத்தை பயன்படுத்தி திறக்கவும்.', 'unlockPin': 'PIN மூலம் திற',
      'useDeviceAuth': 'சாதன அங்கீகாரத்தை பயன்படுத்து', 'tooManyAttempts': 'அதிக முயற்சிகள். PIN திறப்பு தற்காலிகமாக நிறுத்தப்பட்டுள்ளது.', 'pinMismatch': 'அந்த PIN பொருந்தவில்லை.',
      'notifications': 'அறிவிப்புகள்', 'newNotification': 'புதிய அறிவிப்பு', 'open': 'திற', 'enable': 'இயக்கு', 'deviceNotifications': 'சாதன அறிவிப்புகள்', 'deviceNotificationsBody': 'நீங்கள் தேர்வு செய்யும் போது மட்டுமே FCM/APNs அறிவிப்புகளை இயக்கவும். Startup-ல் 143 தானாக அனுமதி கேட்காது.', 'pushAuthorized': 'இந்த சாதனத்தில் அனுமதிக்கப்பட்டுள்ளது', 'pushProvisional': 'அமைதியான / provisional அனுமதி செயலில் உள்ளது', 'pushDenied': 'சாதன அமைப்புகளில் தடுக்கப்பட்டுள்ளது', 'pushNotRequested': 'இன்னும் கேட்கப்படவில்லை', 'pushEnabled': 'சாதன அறிவிப்புகள் இயக்கப்பட்டன.', 'pushEnableFailed': 'சாதன அறிவிப்புகளை இயக்க முடியவில்லை.', 'readAll': 'அனைத்தையும் வாசித்ததாக குறி', 'allQuiet': 'இப்போது அமைதியாக உள்ளது ♡', 'notificationPreferences': 'அறிவிப்பு விருப்பங்கள்', 'stayCloseWithoutNoise': 'சத்தமில்லாமல் நெருக்கமாக இருங்கள்', 'notificationPrefsBody': 'எந்த வகை புதுப்பிப்புகளை பெற வேண்டும் என்பதை தேர்வு செய்யுங்கள். தொலைபேசி அறிவிப்பு அனுமதி தனியாக நிர்வகிக்கப்படுகிறது.', 'hapticsVibration': 'அதிர்வு & ஹாப்டிக்ஸ்', 'hapticsBody': 'பிங், Need You மற்றும் touch interaction-களுக்கு மென்மையான அதிர்வை அனுமதிக்கவும்.', 'reduceMotion': 'இயக்கத்தை குறை', 'reduceMotionBody': 'இயக்கம் சிரமமாக இருந்தால் அமைதியான மாற்றங்களை பயன்படுத்தும்.', 'messagesPref': 'செய்திகள்', 'messagesPrefBody': 'புதிய ஜோடி அரட்டை செய்திகள் மற்றும் பதில்கள்.', 'pingsPref': 'பிங்ஸ் & அணைப்புகள்', 'pingsPrefBody': 'ரொமான்டிக் பிங்ஸ் மற்றும் Need You தருணங்கள்.', 'memoriesPref': 'நினைவுகள்', 'memoriesPrefBody': 'கருத்துகள், ரியாக்ஷன்கள் மற்றும் Time Capsule திறப்புகள்.', 'callsPref': 'அழைப்புகள்', 'callsPrefBody': 'வரும் குரல்/வீடியோ அழைப்பு அறிவிப்புகள்.', 'calendarPref': 'டேட்ஸ் & நினைவூட்டல்கள்', 'calendarPrefBody': 'பகிரப்பட்ட நாட்காட்டி மற்றும் சிறப்பு நாள் நினைவூட்டல்கள்.', 'dailyPref': 'தினசரி இணைப்பு', 'dailyPrefBody': 'தினசரி கேள்வி, பாராட்டு மற்றும் reveal புதுப்பிப்புகள்.', 'achievementsPref': 'சாதனைகள்', 'achievementsPrefBody': 'ஆரோக்கியமான இணைப்பு மைல்கற்கள் மற்றும் பரிசுகள்.',
      'quickPing': 'விரைவு பிங்', 'sendLittleLove': 'சிறிய அன்பை அனுப்பவா?', 'quickPingConsent': 'நீங்கள் உறுதிப்படுத்திய பிறகே 143 மென்மையான பிங்கை அனுப்பும்.', 'sendPing': 'பிங் அனுப்பு',
      'sending': 'அனுப்புகிறது…', 'pingSent': 'அன்புடன் அனுப்பப்பட்டது ♡', 'pingSentDetail': 'அவர்களின் அறிவிப்பு மற்றும் அதிர்வு விருப்பங்களுக்கு ஏற்ப பிங் கிடைக்கும்.',
      'togetherRoom': 'ஒன்றாக அறை', 'refreshResync': 'புதுப்பித்து ஒத்திசை', 'startTogether': 'ஒன்றாக ஏதாவது தொடங்குங்கள்', 'youreTogether': 'நீங்கள் ஒன்றாக இருக்கிறீர்கள்',
      'sharedQueue': 'பகிரப்பட்ட வரிசை', 'queueEmpty': 'பகிரப்பட்ட வரிசை காலியாக உள்ளது', 'privateByDefault': 'இயல்பாக தனிப்பட்டது ♡', 'partnerStatus': 'துணை நிலை', 'quickPingWidget': 'விரைவு பிங்',
      'appearanceAccessibility': 'தோற்றம் & அணுகல்திறன்', 'systemTheme': 'சிஸ்டம்', 'lightTheme': 'ஒளி', 'darkTheme': 'இருள்', 'textSize': 'எழுத்து அளவு',
      'accessibility': 'அணுகல்திறன்', 'higherContrast': 'அதிக கான்ட்ராஸ்ட்', 'higherContrastBody': 'உரை மற்றும் கட்டுப்பாடுகளை தெளிவாக வேறுபடுத்த உதவும்.', 'language': 'மொழி',
      'readableLoveSample': 'அன்பை எளிதாக வாசிக்க முடியும் ♡', 'languageAppliesImmediately': 'மொழி மாற்றங்கள் மொழிபெயர்க்கப்பட்ட திரைகளில் உடனடியாக அமலும். மீதமுள்ள பழைய உரைகள் வெளியீட்டுக்கு முன் மாற்றப்படுகின்றன.',
      'providerReadiness': 'Provider & Device தயார்நிலை', 'securityReviewRequired': 'பாதுகாப்பு மதிப்பாய்வு தேவை',
    },
    'si': {
      'startupError': '143 startup අවසන් කළ නොහැකි විය. නැවත උත්සාහ කරන්න.',
      'appUpdates': 'යෙදුම් යාවත්කාලීන', 'appUpdatesSubtitle': 'Store රහස් ඇතුළත් නොකර release compatibility පරීක්ෂා කරන්න.', 'installedVersion': 'ස්ථාපිත අනුවාදය', 'latestVersion': 'නවතම අනුවාදය', 'updateAvailable': 'යාවත්කාලීනයක් ඇත', 'updateRequired': 'යාවත්කාලීනය අවශ්‍යයි', 'upToDate': 'ඔබ නවතම අනුවාදයේ', 'versionUnknown': 'නවතම අනුවාදය සපයා නැත.', 'updateCheckFailed': 'යාවත්කාලීන පරීක්ෂා කළ නොහැක', 'updateCheckNotConfigured': 'යාවත්කාලීන පරීක්ෂාව සකසා නැත', 'updateCheckBoundaryBody': 'Build අවස්ථාවේ HTTPS APP_UPDATE_MANIFEST_URL සකසන්න. 143 ව්‍යාජ backend endpoint හෝ store credentials ඇතුළත් නොකරයි.', 'openStoreUpdate': 'යාවත්කාලීන කිරීමට Store විවෘත කරන්න', 'whatsNew': 'අලුත් දේ', 'openingWorld': 'ඔබේ පුංචි ලෝකය විවෘත වෙමින්…', 'restoringSession': 'ආරක්ෂිත session නැවත සකසමින්…', 'checkingRecovery': 'Recovery සැකසුම පරීක්ෂා කරමින්…', 'checkingLegal': 'Terms සහ Privacy පරීක්ෂා කරමින්…', 'findingCouple': 'ඔබේ couple space සොයමින්…', 'retryStartup': 'Startup නැවත උත්සාහ කරන්න',
      'home': 'මුල් පිටුව', 'memories': 'මතක', 'create': 'සාදන්න', 'chat': 'කතාබහ', 'us': 'අපි',
      'ourLittleWorld': 'අපේ පුංචි ලෝකය', 'everythingForTwo': 'ඔබ දෙදෙනාටම අයිති පුද්ගලික ඉඩක් ♡',
      'save': 'සුරකින්න', 'cancel': 'අවලංගු කරන්න', 'retry': 'නැවත උත්සාහ කරන්න', 'loading': 'පූරණය වෙමින්…',
      'settings': 'සැකසුම්', 'security': 'ආරක්ෂාව', 'privacy': 'පෞද්ගලිකත්වය', 'profile': 'මගේ පැතිකඩ',
      'games': 'ක්‍රීඩා', 'calendar': 'දින දර්ශනය', 'goals': 'ඉලක්ක', 'music': 'අපේ සංගීතය', 'distance': 'දුරස්ථ',
      'insights': 'සාරාංශ', 'journeys': 'ගමන්', 'achievements': 'ජයග්‍රහණ', 'preferences': 'කැමැත්ත',
      'appearance': 'පෙනුම', 'ourStory': 'අපේ කතාව', 'jarsBucket': 'ජාර් සහ බකට්', 'ourLists': 'අපේ ලැයිස්තු',
      'ai143': '143 AI', 'together': 'එකට', 'needYou': 'ඔබ අවශ්‍යයි', 'moodNeedYouTitle': 'Mood සහ Need You', 'tinySignalTitle': 'පුංචි සංඥාවක් ගොඩක් දේ කියන්න පුළුවන්.', 'tinySignalBody': 'ඔබ තෝරන දේ පමණක් බෙදාගන්න. Need You සෑමවිටම ඔබ විසින් පැහැදිලිව ආරම්භ කරන ක්‍රියාවකි.', 'howFeeling': 'ඔබට දැන් කොහොමද?', 'shareMood': 'Mood බෙදාගන්න', 'moodShared': 'Mood බෙදාගන්නා ලදී', 'needYouGentleBody': 'ඔබේ සහකරුට විශේෂ නමුත් මෘදු සංඥාවක්.', 'sendNeedYou': '“I need you” යවන්න', 'needYouSent': 'Need You මෘදුව යවන ලදී ♡', 'messageAction': 'පණිවිඩය', 'callAction': 'ඇමතුම', 'sendLoveAction': 'ආදරය යවන්න', 'callFromChatHint': 'Chat විවෘත කර Call තෝරන්න.', 'touchHold': 'Touch / Hold', 'touchHoldHint': 'මෘදු touch එකක් යැවීමට ඔබා අතහරින්න', 'touchActive': 'Touch ක්‍රියාත්මකයි', 'touchReady': 'Touch කිරීමට සූදානම්', 'scheduledLove': 'කාලසටහන් කළ ආදරය', 'reconnect': 'නැවත සම්බන්ධ වන්න',
      'smartDate': 'ස්මාර්ට් දිනය', 'budget': 'අයවැය', 'helpData': 'උදව් සහ දත්ත', 'littleWorldSubtitle': 'ඔබ දෙදෙනාටම අයිති පුද්ගලික ඉඩක් ♡',
'widgets': 'විජට්', 'backup': 'උපස්ථ', 'devices': 'උපාංග',
      'done': 'අවසන්', 'answer': 'පිළිතුරු දෙන්න', 'decline': 'ප්‍රතික්ෂේප කරන්න', 'incomingAudioCall': 'එන හඬ ඇමතුම ♡', 'incomingVideoCall': 'එන වීඩියෝ ඇමතුම ♡',
      'personCalling': 'ඔබේ සහකරු අමතමින් සිටී.', 'pingReceived': 'ඔබේ සහකරු කුඩා ආදර පණිවිඩයක් එවා ඇත ♡', 'needYouReceived': 'ඔබේ සහකරුට දැන් ඔබ අවශ්‍යයි ♡',
      'achievementUnlocked': 'නව යුවළ ජයග්‍රහණයක් විවෘත විය ✨', 'dailyRevealReady': 'දෙදෙනාගේ දෛනික පිළිතුරු දැන් බැලීමට සූදානම් ♡', 'surpriseUnlocked': 'ඔබ වෙනුවෙන් අරුමයක් සූදානම් ✨',
      'lockedTitle': 'ඔබේ පුද්ගලික ඉඩ අගුළු දමා ඇත', 'lockedBody': 'දේශීය PIN එක හෝ උපාංග සත්‍යාපනය භාවිතා කර විවෘත කරන්න.', 'unlockPin': 'PIN සමඟ විවෘත කරන්න',
      'useDeviceAuth': 'උපාංග සත්‍යාපනය භාවිතා කරන්න', 'tooManyAttempts': 'උත්සාහ වැඩියි. PIN විවෘත කිරීම තාවකාලිකව නවතා ඇත.', 'pinMismatch': 'එම PIN එක ගැලපෙන්නේ නැහැ.',
      'notifications': 'දැනුම්දීම්', 'newNotification': 'නව දැනුම්දීම', 'open': 'විවෘත කරන්න', 'enable': 'සක්‍රීය කරන්න', 'deviceNotifications': 'උපාංග දැනුම්දීම්', 'deviceNotificationsBody': 'ඔබ තෝරන විට පමණක් FCM/APNs දැනුම්දීම් සක්‍රීය කරන්න. 143 ආරම්භයේදී ස්වයංක්‍රීයව අවසර ඉල්ලන්නේ නැහැ.', 'pushAuthorized': 'මෙම උපාංගයෙන් අවසර දී ඇත', 'pushProvisional': 'නිහඬ / තාවකාලික අවසරය සක්‍රීයයි', 'pushDenied': 'උපාංග සැකසුම් තුළ අවහිර කර ඇත', 'pushNotRequested': 'තවම ඉල්ලා නැත', 'pushEnabled': 'උපාංග දැනුම්දීම් සක්‍රීයයි.', 'pushEnableFailed': 'උපාංග දැනුම්දීම් සක්‍රීය කළ නොහැක.', 'readAll': 'සියල්ල කියවූ ලෙස සලකුණු කරන්න', 'allQuiet': 'දැනට සියල්ල නිහඬයි ♡', 'notificationPreferences': 'දැනුම්දීම් කැමැත්ත', 'stayCloseWithoutNoise': 'ශබ්දයකින් තොරව සමීපව ඉන්න', 'notificationPrefsBody': 'ඔබට අවශ්‍ය යාවත්කාලීන වර්ග තෝරන්න. දුරකථන දැනුම්දීම් අවසරය වෙනම පාලනය වේ.', 'hapticsVibration': 'කම්පන සහ හැප්ටික්ස්', 'hapticsBody': 'Ping, Need You සහ touch සඳහා මෘදු කම්පන ඉඩ දෙන්න.', 'reduceMotion': 'චලනය අඩු කරන්න', 'reduceMotionBody': 'චලනය අපහසු නම් සන්සුන් මාරු භාවිතා කරයි.', 'messagesPref': 'පණිවිඩ', 'messagesPrefBody': 'නව යුවළ චැට් පණිවිඩ සහ පිළිතුරු.', 'pingsPref': 'Pings සහ hugs', 'pingsPrefBody': 'රොමාන්ටික් pings සහ Need You මොහොතවල්.', 'memoriesPref': 'මතක', 'memoriesPrefBody': 'අදහස්, ප්‍රතිචාර සහ Time Capsule විවෘත කිරීම.', 'callsPref': 'ඇමතුම්', 'callsPrefBody': 'එන හඬ/වීඩියෝ ඇමතුම් දැනුම්දීම්.', 'calendarPref': 'දින සහ මතක් කිරීම්', 'calendarPrefBody': 'හවුල් දිනදර්ශන සහ විශේෂ දින මතක් කිරීම්.', 'dailyPref': 'දෛනික සම්බන්ධතාව', 'dailyPrefBody': 'දෛනික ප්‍රශ්න, අගය කිරීම සහ reveal යාවත්කාලීන.', 'achievementsPref': 'ජයග්‍රහණ', 'achievementsPrefBody': 'සෞඛ්‍ය සම්පන්න සම්බන්ධතා මයිල්ස්ටෝන් සහ ත්‍යාග.',
      'quickPing': 'ඉක්මන් Ping', 'sendLittleLove': 'පුංචි ආදරයක් යවන්නද?', 'quickPingConsent': 'ඔබ මෙහි තහවුරු කළ පසු පමණක් 143 මෘදු ping එකක් යවයි.', 'sendPing': 'Ping යවන්න',
      'sending': 'යවමින්…', 'pingSent': 'ආදරයෙන් යැව්වා ♡', 'pingSentDetail': 'ඔබේ සහකරුගේ දැනුම්දීම් සහ හප්ටික් සැකසුම් අනුව ping එක ලැබේ.',
      'togetherRoom': 'එකට කාමරය', 'refreshResync': 'නැවුම් කර නැවත සමමුහුර්ත කරන්න', 'startTogether': 'එකට දෙයක් ආරම්භ කරන්න', 'youreTogether': 'ඔබ දෙදෙනා එකටයි',
      'sharedQueue': 'හවුල් පෝලිම', 'queueEmpty': 'හවුල් පෝලිම හිස්', 'privateByDefault': 'පෙරනිමියෙන් පුද්ගලිකයි ♡', 'partnerStatus': 'සහකරු තත්ත්වය', 'quickPingWidget': 'ඉක්මන් Ping',
      'appearanceAccessibility': 'පෙනුම සහ ප්‍රවේශතාව', 'systemTheme': 'පද්ධතිය', 'lightTheme': 'ආලෝක', 'darkTheme': 'අඳුරු', 'textSize': 'අකුරු ප්‍රමාණය',
      'accessibility': 'ප්‍රවේශතාව', 'higherContrast': 'වැඩි ප්‍රතිවිරුද්ධතාව', 'higherContrastBody': 'පෙළ සහ පාලක වඩා පැහැදිලිව වෙන්කර පෙන්වයි.', 'language': 'භාෂාව',
      'readableLoveSample': 'ආදරය පහසුවෙන් කියවිය යුතුයි ♡', 'languageAppliesImmediately': 'භාෂා වෙනස්කම් පරිවර්තනය කළ තිරවල වහාම යෙදේ. ඉතිරි පැරණි පෙළ නිකුතුවට පෙර මාරු කරමින් පවතී.',
      'providerReadiness': 'Provider සහ Device සූදානම', 'securityReviewRequired': 'ආරක්ෂක සමාලෝචනය අවශ්‍යයි',
    },
  };

  String t(String key) => _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override bool isSupported(Locale locale) => const {'en', 'ta', 'si'}.contains(locale.languageCode);
  @override Future<AppLocalizations> load(Locale locale) => SynchronousFuture(AppLocalizations(locale));
  @override bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
