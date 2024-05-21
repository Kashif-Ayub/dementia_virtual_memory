import 'dart:convert';

import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:dementia_virtual_memory/Screens/Login.dart';
import 'package:dementia_virtual_memory/Screens/Patient/DetectDisease.dart';
import 'package:dementia_virtual_memory/Screens/Patient/Reminders.dart';
import 'package:dementia_virtual_memory/Services/background_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  late Map<String, dynamic> userData;
  @override
  void initState() {
    fetchData();
    initializeService();
    super.initState();
  }

  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('user');
    if (jsonString != null) {
      setState(() {
        userData = jsonDecode(jsonString);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(414, 896));
    DateFormat dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.sp),
        child: AppBar(
          automaticallyImplyLeading: false, // Hide default back button
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30.sp,
                    backgroundImage: NetworkImage(
                        userData['image']), // Set your profile image
                  ),
                  SizedBox(width: 20.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'],
                        style: TextStyle(color: Colors.white, fontSize: 18.sp),
                      ),
                      Text(
                        dateFormat.format(DateTime.now()),
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                      Text(
                        "PATIENT ACCOUNT",
                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () async {
                  // Add functionality here
                  stopBackgroundService();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('user');
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const Login()));
                },
                icon: Icon(Icons.logout,
                    color: Colors.white, size: 30.sp), // Set your icon
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.sp)),
          ),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.sp),
                topRight: Radius.circular(30.sp),
              ),
              color: Colors.white,
            ),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20.h,
              crossAxisSpacing: 20.w,
              padding: EdgeInsets.all(20.w),
              children: [
                InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const Reminders()));
                    },
                    child: _buildCard(Icons.alarm, 'Reminder')),
                _buildCard(Icons.photo, 'Photos'),
                InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const DetectDisease()));
                    },
                    child: _buildCard(
                        Icons.medical_information, 'Detect Disease')),
                _buildCard(Icons.video_library, 'VIDEOS'),
              ],
            ),
          ),
          Positioned(
            left: 20.w,
            right: 20.w,
            bottom: 80.h,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.sp)),
              child: ListTile(
                tileColor: themecolor, // Set background color to white
                leading: Icon(
                  Icons.call,
                  color: whitecolor,
                  size: 30.sp,
                ), // Icon at leading
                title: Text(
                  'Emergency Contact',
                  style: TextStyle(
                      color: whitecolor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp),
                ), // Title
                subtitle: Text(userData['emergencyNumber'],
                    style: TextStyle(
                        color: whitecolor, fontSize: 17.sp)), // Subtitle
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(IconData iconData, String title, {String? subtitle}) {
    return Card(
      shadowColor: themecolor,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.sp)),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 50.sp,
              color: themecolor,
            ),
            SizedBox(height: 20.h),
            Text(title, style: TextStyle(fontSize: 18.sp, color: themecolor)),
            if (subtitle != null) ...[
              SizedBox(height: 10.h),
              Text(subtitle, style: TextStyle(fontSize: 14.sp)),
            ],
          ],
        ),
      ),
    );
  }
}
