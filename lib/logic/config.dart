import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:yaml/yaml.dart';

// todo: add ConfigLogic public interface

enum KCNetworkType {
  testnet(42),
  mainnet(21);

  const KCNetworkType(this.value);
  final num value;

  String get name {
    switch (this) {
      case KCNetworkType.testnet:
        return 'Testnet';
      case KCNetworkType.mainnet:
        return 'Mainnet';
    }
  }
}

/// App config logic
class ConfigLogic {
  /// Set to true to work against localhost servers. Otherwise production servers are used
  final bool apiLocalMode = true;

  /// dev mode has some text field input shortcuts to save time in dev
  final bool devMode = true;

  /// in dash mode app displayes public chain data and doesn't require user to sign-in
  final bool dashMode = false;

  /// Defaults to testnet. Change this if user specifies to change between testnet and mainnet. and call init() again to configure connection to mainnet and vice versa when moving from mainnet to testnet... In production app once mainnent is live, the default should be mainnet
  KCNetworkType networkId = KCNetworkType.testnet;

  /// Skip whatsapp verification for local app testing. kc2Api should use the bypass token
  /// obtain from local config file to bypass whatsapp verification.
  final bool skipWhatsappVerification = true;

  /// check internet connections and show error messages
  final bool enableInternetConnectionChecking = false;

  final secureStorage = const FlutterSecureStorage();
  static const _aOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final String _karmaMiningScreenDisplayedKey = "karmaMiningScreenDisplayedKey";

  late final currentLocale = ValueNotifier<String?>(null);
  late final apiHostName = ValueNotifier<String>('127.0.0.1');
  late final apiHostPort = ValueNotifier<int>(9080);
  late final apiProtocol = ValueNotifier<String>('ws');
  late final verifierHostName = ValueNotifier<String>('verifier1.karmaco.in');
  late final verifierHostPort = ValueNotifier<int>(443);
  late final verifierSecureConnection = ValueNotifier<bool>(true);

  // Public key of the verifier account id
  // Client should only accept verifier responses signed by this account
  late final vieriferPublicKey = ValueNotifier<String>(
      'fe9d0c0df86c72ae733bf9ec0eeaff6e43e29bad4488f5e4845e455ea1095bf3');

  late final verifierAccountId =
      ValueNotifier<String>('5EUH4CC5czdqfXbgE1fLkXcqMos1thxJSaj93J6N5bSareuz');

  late final learnYoutubePlaylistUrl =
      'https://www.youtube.com/playlist?list=PLF4zx8ioKJTszWMz1MKiHwStfMCdxh8MP';

  late final firebaseWebPushPubKey =
      "BPCf2pl7oLrgSWJJjEXzKfTIe4atfDay5-Aw9u0Ge8IgtfozLq1jkYPfJ0ccEY9D9cdqoAgxcbx4rGEhQC5nMN4";

  // requested user name entered by the user.
  late final requestedUserName = ValueNotifier<String>('');

// Set received FCM push note token
/*
  Future<void> _setFCMPushNoteToken(String token) async {
    await secureStorage.write(
        key: _pushTokenKey, value: token, aOptions: _aOptions);

    fcmToken.value = token;
  }*/

  // Get known FCM push note token
  final ValueNotifier<String?> fcmToken = ValueNotifier<String?>(null);

  /// set to true after karma mining screen is displayed once
  final ValueNotifier<bool> karmaMiningScreenDisplayed = ValueNotifier(false);

  Future<void> setDisplayedKarmaRewardsScreen(bool value) async {
    await secureStorage.write(
        key: _karmaMiningScreenDisplayedKey,
        value: value.toString(),
        aOptions: _aOptions);

    karmaMiningScreenDisplayed.value = value;
  }

  /// Load optional test config
  Future<dynamic> getTestConfig() async {
    final yamlString = await rootBundle.loadString('assets/private_config.yaml');
    return loadYaml(yamlString);
  }

  /// Call this everytime network is changed from the ui. e.g. a switch between mainnet to testnet...
  Future<void> init() async {
    if (apiLocalMode) {
      // note: we default to testnet in local mode.
      // to connect to a local mainnet mode. set networkId to mainnet and call init()
      debugPrint(
          "Wroking against local kc2 api provider. Expected net id $networkId");
      if (await PlatformInfo.isRunningOnAndroidEmulator()) {
        debugPrint('Running in Android emulator');
        // on android emulator, use the host machine ip address
        apiHostName.value = '10.0.2.2';
      } else {
        apiHostName.value = '127.0.0.1';
      }

      apiHostPort.value = 9944;
      apiProtocol.value = 'ws';
    } else {
      switch (networkId) {
        case KCNetworkType.testnet:
          debugPrint('Working against a remote kc2 testnet api provider');
          apiHostName.value = 'testnet.karmaco.in/testnet/ws';
          apiHostPort.value = 80;
          apiProtocol.value = 'wss';
          //
          // verifier info for testnet
          verifierHostName.value = 'verifier1.karmaco.in';
          verifierHostPort.value = 443;
          verifierSecureConnection.value = true;
          break;
        case KCNetworkType.mainnet:
          debugPrint('Working against a remote kc2 mainnet api provider');
          // todo: add mainnet api node here
          apiHostName.value = '[add mainnent public api node here]';
          apiHostPort.value = 80;
          apiProtocol.value = 'wss';
          //
          // verifier info for mainnet
          verifierHostName.value = 'verifier1.karmaco.in';
          verifierHostPort.value = 443;
          verifierSecureConnection.value = true;
          break;
      }
    }

    // todo: fix me

    // Read last known fcm token for device
    // String? token =
    //     await secureStorage.read(key: _pushTokenKey, aOptions: _aOptions);
    // if (token != null) {
    //  fcmToken.value = token;
    // }

    var displayKarmaMiningScreenData = await secureStorage.read(
        key: _karmaMiningScreenDisplayedKey, aOptions: _aOptions);

    if (displayKarmaMiningScreenData != null) {
      karmaMiningScreenDisplayed.value =
          displayKarmaMiningScreenData.toLowerCase() == 'true';
    }
  }

  /// Returns connection url for kc2 api
  String get kc2ApiUrl =>
      '${apiProtocol.value}://${apiHostName.value}:${apiHostPort.value}';

  // todo: completely revamp push notes to new auth scheme

  // push notificaiton handling
  ////////////////////

  /// Handle push token change
  /// Note: This callback is fired at each app startup and whenever a new
  /// token is generated.
  /*
  Future<void> setupPushNotifications() async {
    debugPrint('Setting up push notes...');
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      String? lastToken = accountLogic.fcmToken.value;

      if (lastToken != null && lastToken == fcmToken) {
        // we already sent this token to the server and it is stored locally
        return;
      }

      _processPushNoteToken(fcmToken);
    }).onError((err) {
      // Error getting token.
    });

    // Get any messages which caused the application to open from a
    // terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  /// Process a push note token.
  /// Store it in cloud firestore for the user and locally.
  Future<void> _processPushNoteToken(String token) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    if (firebaseAuth.currentUser == null) {
      debugPrint(
          'User not firebase authenticated. Cannot send token to server.');
      return;
    }

    if (!kc2User.previouslySignedUp) {
      debugPrint('No local karma coin user. Cannot send token to server.');
      return;
    }

    final fireStore = FirebaseFirestore.instance;
    String userId = firebaseAuth.currentUser!.uid;
    debugPrint('Firebase auth user id: $userId');

    if (kc2User.identity.phoneNumber == null) {
      debugPrint('No phone number. Cannot send token to server.');
      return;
    }

    final data = <String, String>{
      'token': token,
      'timeStamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    await fireStore.collection('users').doc(userId).get().then((doc) async {
      if (!doc.exists) {
        debugPrint('User not found in firestore. creating record...');

        await fireStore.collection('users').doc(userId).set({
          'tokens': [data],
          'accountId': kc2User.identity.accountId,
          'phoneNumber': kc2User.identity.phoneNumber,
          'userName': kc2User.userInfo.value!.userName,
        });

        debugPrint("Stored token in firestore");
      } else {
        debugPrint('user tokens exist - read the tokens and update as needed');

        dynamic tokens = doc.data()!['tokens'] as List<dynamic>;

        for (Map<String, dynamic> tokenData in tokens) {
          String? aToken = tokenData['token'];
          if (token == aToken) {
            debugPrint('Token already stored in cloud firestore');
            tokenData['timeStamp'] = data['timeStamp'];
            await fireStore.collection('users').doc(userId).update({
              'tokens': tokens,
            });
            debugPrint('Updated token timestamp in cloud firestore');
            return;
          }
        }

        // token not in fire store - add it...
        await fireStore.collection('users').doc(userId).update({
          'tokens': FieldValue.arrayUnion([data]),
        });

        debugPrint("Added token to firestore");
      }
    });

    // store locally in account logic
    await _setFCMPushNoteToken(token);
  }

  /// Register for push notes - may show dialog box to allow notifications
  Future<void> registerPushNotifications() async {
    try {
      // request permissions before FCM registraiton
      // ref: https://firebase.google.com/codelabs/firebase-fcm-flutter#3
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (PlatformInfo.isMobile) {
        // iOS push notes - will trigger dialog box to allow notificaitons
        final fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('Got FCM Token: $fcmToken');
        if (fcmToken != null) {
          await _processPushNoteToken(fcmToken);
        }
      } else if (kIsWeb) {
        final fcmToken = await FirebaseMessaging.instance
            .getToken(vapidKey: configLogic.firebaseWebPushPubKey);
        debugPrint('Got FCM Token: $fcmToken');
        if (fcmToken != null) {
          await _processPushNoteToken(fcmToken);
        }
      }
    } catch (err) {
      debugPrint('Error registering for push notifications: $err');
    }
  }

  /// Handle a received push note
  void _handleMessage(RemoteMessage message) {
    debugPrint('Got push notification: $message');

    // todo: get all transactions and show appreciations screen

    Future.delayed(Duration.zero, () async {
      await FirebaseAnalytics.instance.logEvent(name: "push_note_received");

      if (accountLogic.karmaCoinUser.value != null) {
        // fetch transactions so we have the latest data
        await txsBoss.fetchTransactions();
        if (message.data["type"] == "payment") {
          if (appRouter.location != ScreenPaths.appreciations) {
            appRouter.push(ScreenPaths.appreciations);
          }
        }
      }
    });
  }*/
}
