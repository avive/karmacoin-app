import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/data/kc_user.dart';

// todo: add settings interface

// todo: migrate from json file to a hive box

/// App config logic
class ConfigLogic {
  /// Set to true to work against localhost servers. Otherwise production servers are used
  final bool apiLocalMode = false;

  // dev mode has some text field input shortcuts to save time in dev
  final bool devMode = false;

  // check internet connections and show error messages
  final bool enableInternetConnectionChecking = false;

  late final currentLocale = ValueNotifier<String?>(null);
  late final apiHostName = ValueNotifier<String>('127.0.0.1');
  late final apiHostPort = ValueNotifier<int>(9080);
  late final apiSecureConnection = ValueNotifier<bool>(false);
  late final verifierHostName = ValueNotifier<String>('127.0.0.1');
  late final verifierHostPort = ValueNotifier<int>(9080);
  late final verifierSecureConnection = ValueNotifier<bool>(false);

  // Public key of the verifier account id
  // Client should only accept verifier responses signed by this account
  late final verifierAccountId = ValueNotifier<String>(
      'fe9d0c0df86c72ae733bf9ec0eeaff6e43e29bad4488f5e4845e455ea1095bf3');

  late final learnYoutubePlaylistUrl =
      'https://www.youtube.com/playlist?list=PLF4zx8ioKJTszWMz1MKiHwStfMCdxh8MP';

  late final firebaseWebPushPubKey =
      "BPCf2pl7oLrgSWJJjEXzKfTIe4atfDay5-Aw9u0Ge8IgtfozLq1jkYPfJ0ccEY9D9cdqoAgxcbx4rGEhQC5nMN4";

  // requested user name entered by the user. For the canonical user-name, check AccountLogic
  late final requestedUserName = ValueNotifier<String>('');

  Future<void> init() async {
    if (apiLocalMode) {
      debugPrint("Wroking against local servers");
      if (await PlatformInfo.isRunningOnAndroidEmulator()) {
        debugPrint('Running in Android emulator');
        // on android emulator, use the host machine ip address
        apiHostName.value = '10.0.2.2';
        verifierHostName.value = '10.0.2.2';
      } else {
        apiHostName.value = '127.0.0.1';
        verifierHostName.value = '127.0.0.1';
      }
      apiHostPort.value = 9080;
      verifierHostPort.value = 9080;
      apiSecureConnection.value = false;
      verifierSecureConnection.value = false;
    } else {
      debugPrint('Working against production servers');
      apiHostName.value = 'api.karmaco.in';
      apiHostPort.value = 443;
      apiSecureConnection.value = true;
      verifierHostName.value = 'api.karmaco.in';
      verifierHostPort.value = 443;
      verifierSecureConnection.value = true;
    }
  }

  // push notificaiton handling
  ////////////////////

  /// Handle push token change
  /// Note: This callback is fired at each app startup and whenever a new
  /// token is generated.
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

    KarmaCoinUser? karmaUser = accountLogic.karmaCoinUser.value;
    if (karmaUser == null) {
      debugPrint('No local karma coin user. Cannot send token to server.');
      return;
    }

    final fireStore = FirebaseFirestore.instance;
    String userId = firebaseAuth.currentUser!.uid;
    debugPrint('Firebase auth user id: $userId');
    final data = <String, String>{
      'token': token,
      'timeStamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    await fireStore.collection('users').doc(userId).get().then((doc) async {
      if (!doc.exists) {
        debugPrint('User not found in firestore. creating record...');

        await fireStore.collection('users').doc(userId).set({
          'tokens': [data],
          'accountId': karmaUser.userData.accountId.data.toBase64(),
          'phoneNumber': karmaUser.userData.mobileNumber.number,
          'userName': karmaUser.userData.userName,
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
    await accountLogic.setFCMPushNoteToken(token);
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
            .getToken(vapidKey: settingsLogic.firebaseWebPushPubKey);
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
  }
}
