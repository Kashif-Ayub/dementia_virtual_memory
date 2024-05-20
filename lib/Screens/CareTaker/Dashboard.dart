import 'dart:convert';
import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:dementia_virtual_memory/Screens/Login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CareTakerDashboard extends StatefulWidget {
  const CareTakerDashboard({Key? key}) : super(key: key);

  @override
  State<CareTakerDashboard> createState() => _CareTakerDashboardState();
}

class _CareTakerDashboardState extends State<CareTakerDashboard> {
  late Map<String, dynamic> userData;
  late Future<List<DocumentSnapshot>> _patientsFuture;
  @override
  void initState() {
    super.initState();
    fetchData().then((_) {
      _patientsFuture = fetchPatientsByCaretakerEmail(userData['email']);
    });
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

  Future<List<DocumentSnapshot>> fetchPatientsByCaretakerEmail(
      String caretakerEmail) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('caretakerEmail', isEqualTo: caretakerEmail)
          .where('role', isEqualTo: 'patient')
          .get();
      return querySnapshot.docs;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(414, 896));
    DateFormat dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.sp),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30.sp,
                    backgroundImage: NetworkImage(userData['image']),
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
                        "CARETAKER ACCOUNT",
                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const Login()));
                },
                icon: Icon(Icons.logout, color: Colors.white, size: 30.sp),
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
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _patientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<DocumentSnapshot>? patients = snapshot.data;
                  if (patients == null || patients.isEmpty) {
                    return Center(child: Text('No patients found'));
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20.sp),
                        child: Text(
                          'Patients List',
                          style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: themecolor),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: patients.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 5,
                              margin: EdgeInsets.symmetric(
                                  vertical: 10.h, horizontal: 20.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.sp),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(2.sp),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 5.h),
                                    Container(
                                      child: CircleAvatar(
                                        radius: 50.sp,
                                        backgroundImage: NetworkImage(
                                            patients[index]['image'] ?? ''),
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      patients[index]['name'] ?? '',
                                      style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      '${patients[index]['email'] ?? ''}',
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                    SizedBox(height: 20.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.location_pin,
                                            color: themecolor,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(Icons.video_call,
                                              color: themecolor),
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(Icons.add_photo_alternate,
                                              color: themecolor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
