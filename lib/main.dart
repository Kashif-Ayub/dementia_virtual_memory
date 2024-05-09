import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:dementia_virtual_memory/Screens/Splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
