import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:dementia_virtual_memory/Screens/Welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class Splash extends StatelessWidget {
  const Splash({Key? key});

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
          nextScreen: const Welcome(),
        ),
      ),
    );
  }
}
