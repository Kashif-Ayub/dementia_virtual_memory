import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dementia_virtual_memory/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

const notificationChannelId = 'my_foreground';
const notificationId = 888;

void initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  service.startService();
}

void stopBackgroundService() {
  FlutterBackgroundService().invoke('stopService');
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  Map<String, dynamic> userData = await fetchData();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.show(
    notificationId,
    'DVM REMINDER',
    "INITIALIZED",
    const NotificationDetails(
      android: AndroidNotificationDetails(
          notificationChannelId, 'MY FOREGROUND SERVICE',
          icon: 'ic_bg_service_small', ongoing: false, autoCancel: true),
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  String reminderalreadySentid = "";
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final remindersStream =
            await getMatchingRemindersStream(userData['email']);

        bool isProcessingReminders =
            false; // Flag to track if reminders are currently being processed

        remindersStream.listen((List<Reminder> reminders) async {
          // If reminders are currently being processed, return early
          if (isProcessingReminders) {
            print('Previous reminders are still being processed. Skipping...');
            return;
          }

          isProcessingReminders =
              true; // Set flag to indicate processing has started

          // Process individual reminders if needed
          for (Reminder reminder in reminders) {
            if (await ReturntheTime(reminder.remindertime) <= 15 &&
                reminderalreadySentid != reminder.id) {
              generateReminderNotification(
                id: getRandomNumber(1, 100000),
                title: "DVM REMINDER",
                body:
                    "It's Time for : ${reminder.title} ${reminder.remindertime}",
              );
              reminderalreadySentid = reminder.id;
            }
          }

          // Set flag to indicate processing has finished
          isProcessingReminders = false;
        });
      }
    }
    //   print('Background service running: ${DateTime.now()}');
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  print('iOS background fetch activated');
  return true;
}

class Reminder {
  final String id;
  final String title;
  final String remindertime;
  final String email;
  bool activeinactive;

  Reminder({
    required this.id,
    required this.title,
    required this.activeinactive,
    required this.remindertime,
    required this.email,
  });

  Reminder.fromSnapshot(DocumentSnapshot snapshot)
      : id = snapshot.id,
        title = (snapshot.data() as Map<String, dynamic>)['title'] ?? '',
        activeinactive =
            (snapshot.data() as Map<String, dynamic>)['activeinactive'] ??
                false,
        remindertime =
            (snapshot.data() as Map<String, dynamic>)['remindertime'] ?? '',
        email = (snapshot.data() as Map<String, dynamic>)['email'] ?? '';
}

Future<Stream<List<Reminder>>> getMatchingRemindersStream(String email) async {
  return await FirebaseFirestore.instance
      .collection('Reminders')
      .where('email', isEqualTo: email)
      .where('activeinactive', isEqualTo: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Reminder.fromSnapshot(doc)).toList());
}

Future<Map<String, dynamic>> fetchData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('user');
  if (jsonString != null) {
    return jsonDecode(jsonString);
  }
  throw Exception('User data not found in SharedPreferences');
}

Future<int> ReturntheTime(String time) async {
  int differenceInSeconds = calculateTimeDifference(time);
  return differenceInSeconds;
}

int getRandomNumber(int min, int max) {
  // Create an instance of the Random class
  Random random = Random();

  // Generate a random integer between min (inclusive) and max (inclusive)
  return min + random.nextInt(max - min + 1);
}
       // flutterLocalNotificationsPlugin.show(
              //   notificationId,
              //   'DVM REMINDER',
              //   "It's Time for : ${reminder.title} \n ${reminder.remindertime}",
              //   const NotificationDetails(
              //     android: AndroidNotificationDetails(
              //       notificationChannelId,
              //       'MY FOREGROUND SERVICE',
              //       icon: 'ic_bg_service_small',
              //       ongoing: true,
              //     ),
              //   ),
              // );