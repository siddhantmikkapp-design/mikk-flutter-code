import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mikk/Demo/AvatarDashBoard.dart';
import 'package:mikk/View_Model/Chat/ChatService.dart';
import 'package:mikk/View_Model/ProfileViewModel.dart';
import 'package:mikk/View_Model/SearchViewModel.dart';
import 'package:mikk/values/Color.dart';
import 'package:mikk/values/StaticText.dart';
import 'package:provider/provider.dart';
import 'ActiveChatTracker.dart';
import 'Demo/AvatarUploadStatus.dart';
import 'Demo/avatar_manager.dart';
import 'View/CustomBottomNavigationBar.dart';
import 'View/SettingsScreen.dart';
import 'View/authScreen/sign_up.dart';
import 'View/chat_screen.dart';
import 'View_Model/AvatarCreatorViewModel.dart';
import 'View_Model/Chat/DatabaseService.dart';
import 'View_Model/Chat/FirestoreChatService.dart';
import 'View_Model/DashboardViewModel.dart';
import 'View_Model/FollowerFollowingViewModel.dart';
import 'View_Model/NotificationViewModel.dart';
import 'View_Model/SettingsDetailViewModel/PersonalInformationViewModel.dart';
import 'View_Model/SettingsDetailViewModel/PrivacySecurityViewModel.dart';
import 'View_Model/SettingsViewModel.dart';
import 'View_Model/auth_view_model.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
  'chat_messages',
  'Chat Messages',
  description: 'Notifications for chat messages',
  importance: Importance.high,
);


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔕 Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyAdqkJtpJBRGapxpxf8M2eHSWvyeqn4q8w",
          authDomain: "mikklabs.firebaseapp.com",
          databaseURL: "https://mikklabs-default-rtdb.asia-southeast1.firebasedatabase.app",
          projectId: "mikklabs",
          storageBucket: "mikklabs.firebasestorage.app",
          messagingSenderId: "477901996890",
          appId: "1:477901996890:web:991548d54432764d3ea963",
          measurementId: "G-LS68DGHR92"
      ),
    );
    AvatarUploadManager().initialize();
    await AvatarManager().initialize(); // NEW


  } else {
    await Firebase.initializeApp();
    AvatarUploadManager().initialize();
    await AvatarManager().initialize(); // NEW

  }

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // Create notification channel (ANDROID)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(chatChannel);

  await ScreenUtil.ensureScreenSize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => SettingViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsDetailViewModel()),
        ChangeNotifierProvider(create: (_) => PersonalInformationViewModel()),
      //  ChangeNotifierProvider(create: (_) => FollowerFollowingViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => AvatarCreatorViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => FirestoreChatService()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> defaultScreen;

  @override
  void initState() {
    super.initState();
    defaultScreen = initialScreen();

    _initFCM();

    // Initialize Firebase Messaging after the app starts
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FOREGROUND messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);


    // When user taps notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // When app was terminated
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }



  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    if (notification == null) return;

    final incomingRoomId = data['roomName'];
    final activeRoomId = ActiveChatTracker.activeRoomId;

    // ❌ User is already in this chat → suppress notification
    if (incomingRoomId != null && incomingRoomId == activeRoomId) {
      return;
    }

    // ✅ Show local notification
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chatChannel.id,
          chatChannel.name,
          channelDescription: chatChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

  }





  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    debugPrint('🔔 Notification tapped: $data');

    if (data['type'] == 'chat') {
      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: data,
      );
    }

  }

  Future<Widget> initialScreen() async {
    final user = await AuthViewModel().checkUserSignIn();
    if (user != null) {
      return CustomBottomNavigationBar();
    } else {
      return const AvatarDashBoard();
    }
  }


/*  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor1),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1.0),
          ),

          /// ✅ Build main screen with Unity overlaid
          home: Stack(
            children: [
              /// 🔸 Your actual navigation / home / signup screen
              FutureBuilder<Widget>(
                future: defaultScreen,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return const Scaffold(
                      body: Center(child: Text("Something went wrong")),
                    );
                  } else {
                    return snapshot.data!;
                  }
                },
              ),

              /// ✅ Unity widget mounted ONCE, globally
              Positioned.fill(
                child: Visibility(
                  visible: GlobalUnityController.dart().isVisible,
                  maintainState: true,
                  child: GlobalUnityController.dart().getUnityWidget(),
                ),
              ),
            ],
          ),

          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: widget!,
            );
          },
        );
      },
    );
  }*/



 @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor1),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1.0),
          ),
          home: FutureBuilder<Widget>(
            future: defaultScreen,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text("Something went wrong")),
                );
              } else {
                return snapshot.data!;
              }
            },
          ),



          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: widget!,
            );
          },
        );
      },
    );
  }
}