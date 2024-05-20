import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

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
