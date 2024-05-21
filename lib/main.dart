import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:dementia_virtual_memory/Controllers/NotificationsController.dart';
import 'package:dementia_virtual_memory/Screens/Splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
        channelGroupKey: "basic_channel_group",
        channelKey: "basic_channel",
        channelName: "Reminder Notifications",
        channelDescription: "REMINDERS NOTIFICATION DESCRIPTION",
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        playSound: true,
        enableVibration: true,
        onlyAlertOnce: true,
        defaultColor: themecolor)
  ], channelGroups: [
    NotificationChannelGroup(
        channelGroupKey: "basic_channel_group",
        channelGroupName: "Reminders Group")
  ]);
  bool isAllwedNotifications =
      await AwesomeNotifications().isNotificationAllowed();
  if (!isAllwedNotifications) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationsController.onActionReceivedMethod,
    onNotificationCreatedMethod:
        NotificationsController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationsController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationsController.onDismissActionReceivedMethod,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil
    Size screenSize = MediaQuery.of(context).size;
    double designWidth = screenSize.width;
    double designHeight = screenSize.height;
    ScreenUtil.init(context, designSize: Size(designWidth, designHeight));

    // Ensure the app remains in portrait mode only on mobile platforms
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: themecolor, // Set your primary color here
        appBarTheme: const AppBarTheme(
          color: themecolor,
        ),
      ),
      home: const Splash(),
    );
  }
}
