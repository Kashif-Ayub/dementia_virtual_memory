import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:dementia_virtual_memory/Screens/CareTaker/Register.dart';
import 'package:dementia_virtual_memory/Screens/Patient/Register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:slider_button/slider_button.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 65.h, left: 15.w, right: 15.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DefaultTextStyle(
                    style: TextStyle(
                        fontSize: 30.0.sp,
                        color: themecolor,
                        fontWeight: FontWeight.bold),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        WavyAnimatedText('WELCOME TO DVM'),
                      ],
                      repeatForever: true,
                      isRepeatingAnimation: true,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20.h,
              ),
              SizedBox(
                height: 200.h,
                child: DefaultTextStyle(
                  style: TextStyle(
                      fontSize: 40.0.sp,
                      fontFamily: 'Horizon',
                      color: themecolor,
                      fontWeight: FontWeight.bold),
                  child: AnimatedTextKit(
                    repeatForever: true,
                    isRepeatingAnimation: true,
                    animatedTexts: [
                      RotateAnimatedText('DEMENTIA'),
                      RotateAnimatedText('VIRTUAL'),
                      RotateAnimatedText('MEMORY'),
                    ],
                    onTap: () {},
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Center(
                child: Text(
                  "You Are Registering As",
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      wordSpacing: 6.w),
                ),
              ),
              SizedBox(
                height: 60.h,
              ),
              Center(
                  child: SizedBox(
                width: 220.w,
                child: Column(
                  children: [
                    SliderButton(
                        action: () async {
                          ///Do something here OnSlide
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const RegisterCareTaker()));
                          return false;
                        },
                        label: const Text(
                          "CARETAKER",
                          style: TextStyle(
                              color: Color(0xff4a4a4a),
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                        icon: Icon(
                          Icons.health_and_safety,
                          color: caretakercolor,
                          size: 43.sp,
                        )),
                    SizedBox(
                      height: 20.h,
                    ),
                    SliderButton(
                        action: () async {
                          ///Do something here OnSlide

                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const RegisterPatient()));
                          return false;
                        },
                        label: const Text(
                          "PATIENT",
                          style: TextStyle(
                              color: Color(0xff4a4a4a),
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                        icon: Icon(
                          Icons.person,
                          color: const Color(0xFFFFB23E),
                          size: 43.sp,
                        )),
                  ],
                ),
              ))
            ],
          ),
        ),
      ),
    ));
  }
}
