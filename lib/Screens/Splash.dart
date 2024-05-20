import 'dart:convert';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dementia_virtual_memory/Controllers/NotificationsController.dart';
import 'package:dementia_virtual_memory/Screens/CareTaker/Dashboard.dart';
import 'package:dementia_virtual_memory/Screens/Patient/Dashboard.dart';
import 'package:dementia_virtual_memory/Screens/Welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late dynamic role;
  Future<dynamic> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user')) {
      return false; // Return false if user data doesn't exist
    }

    String? jsonString = prefs.getString('user');
    if (jsonString != null) {
      Map<String, dynamic> userData = jsonDecode(jsonString);
      return userData['role']; // Return the role value if user data exists
    } else {
      return false; // Return false if user data is empty
    }
  }

  @override
  void initState() {
    fetchData().then((value) {
      setState(() {
        role = value;
      });
    });
    // TODO: implement initState
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationsController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationsController.onNotificationCreatedMethod,
        onDismissActionReceivedMethod:
            NotificationsController.onDismissActionReceivedMethod,
        onNotificationDisplayedMethod:
            NotificationsController.onNotificationDisplayedMethod);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(bottom: ScreenUtil().screenHeight * 0.5),
        child: AnimatedSplashScreen(
          centered: true,
          splashTransition: SplashTransition.fadeTransition,
          splash: Lottie.asset(
            'assets/animations/splashanimation.json',
            width: ScreenUtil().screenWidth,
            height: ScreenUtil().screenHeight,
            fit: BoxFit.cover,
          ),
          nextScreen: role == false
              ? const Welcome()
              : role == 'patient'
                  ? const PatientDashboard()
                  : role == 'caretaker'
                      ? const CareTakerDashboard()
                      : const Welcome(),
        ),
      ),
    );
  }
}
