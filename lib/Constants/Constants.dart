// ignore_for_file: non_constant_identifier_names

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const themecolor = Color(0xFF744FCD);
const caretakercolor = Color(0xFF03D3CF);
const whitecolor = Color(0xFFFFFFFF);
const blackcolor = Color(0xFF000000);

generateReminderNotification({
  required int id,
  required String title,
  required String body,
}) {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
        id: id,
        channelKey: "basic_channel",
        title: title,
        body: body,
        backgroundColor: themecolor,
        category: NotificationCategory.Alarm,
        color: themecolor,
        wakeUpScreen: true,
        notificationLayout: NotificationLayout.BigText,
        autoDismissible: true,
        fullScreenIntent: false,
        displayOnBackground: true,
        displayOnForeground: true),
    actionButtons: [
      NotificationActionButton(
        key: 'DISMISS',
        label: 'Clear',
        actionType: ActionType.DisabledAction,
        color: themecolor,
      ),
    ],
    // schedule: NotificationInterval(
    //   interval: delay,
    //   repeats: false,
    //   allowWhileIdle: true,
    // ),
  );
}

int calculateTimeDifference(String timeString) {
  // Convert time string to a DateTime object
  DateTime futureTime = _parseTimeString(timeString);

  // Get current time
  DateTime now = DateTime.now();

  // If future time is earlier than current time, add one day
  if (futureTime.isBefore(now)) {
    futureTime = futureTime.add(const Duration(days: 1));
  }

  // Calculate difference in seconds
  int differenceInSeconds = futureTime.difference(now).inSeconds;

  return differenceInSeconds;
}

DateTime _parseTimeString(String timeString) {
  // Split the time string into components
  List<String> components = timeString.split(' ');
  String time = components[0];
  String period = components[1];

  // Split the time into hour and minute
  List<String> timeComponents = time.split(':');
  int hour = int.parse(timeComponents[0]);
  int minute = int.parse(timeComponents[1]);

  // Convert hour to 24-hour format if the period is PM
  if (period == 'PM' && hour != 12) {
    hour += 12;
  }

  // Get current date
  DateTime now = DateTime.now();

  // Return a DateTime object for the future time
  return DateTime(now.year, now.month, now.day, hour, minute);
}

class MiniGame {
  final String name;
  final String url;

  MiniGame({required this.name, required this.url});
}

List<MiniGame> miniGames = [
  MiniGame(
    name: 'Space Invaders',
    url: 'https://elgoog.im/space-invaders/',
  ),

  MiniGame(
    name: 'Snake',
    url:
        'https://www.google.com/search?q=snake+game&rlz=1C1CHBF_enIN830IN830&oq=snake+game&aqs=chrome..69i57j0l5.183j0j7&sourceid=chrome&ie=UTF-8',
  ),

  MiniGame(
    name: 'Cricket',
    url: 'https://www.google.com/logos/2017/cricket17/cricket17.html',
  ),
  MiniGame(
    name: 'Pony Express',
    url: 'https://www.google.com/logos/2015/ponyexpress/ponyexpress15.html',
  ),

  // Add more mini games here as needed
];

// // SMS SEND FUNCTION

String? encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((MapEntry<String, String> e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

Future<void> sendSMS(String message, String recipient) async {
  final Uri smsLaunchUri = Uri(
    scheme: 'sms',
    path: recipient,
    query: encodeQueryParameters(<String, String>{'body': message}),
  );

  try {
    bool launched = await launchUrl(smsLaunchUri);
    if (!launched) {
      // Handle the failure case, e.g., show a message to the user or fallback behavior
      print('Could not launch SMS URI');
    }
  } catch (e) {
    // Handle the exception
    print('Error occurred: $e');
  }
}
