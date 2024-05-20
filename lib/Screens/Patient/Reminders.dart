import 'dart:convert';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Reminders extends StatefulWidget {
  const Reminders({super.key});

  @override
  State<Reminders> createState() => _RemindersState();
}

class _RemindersState extends State<Reminders> {
  final stt.SpeechToText speech = stt.SpeechToText();
  late Map<String, dynamic> userData = <String, dynamic>{};
  bool isAvailable = false;
  late Stream<List<Reminder>> remindersStream;

  @override
  void initState() {
    super.initState();
    fetchData();

    Initializer();
  }

  Initializer() async {
    isAvailable = await speech.initialize();
    setState(() {});
  }

  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('user');
    if (jsonString != null) {
      setState(() {
        userData = jsonDecode(jsonString);
      });
      startListeningToReminders();
    }
  }

  void startListeningToReminders() {
    remindersStream = FirebaseFirestore.instance
        .collection('Reminders')
        .where('email', isEqualTo: userData['email'])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Reminder.fromSnapshot(doc)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Reminders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              height: ScreenUtil().screenHeight * 0.8,
              width: ScreenUtil().screenWidth,
              padding: EdgeInsets.all(20.w),
              child: StreamBuilder<List<Reminder>>(
                stream: remindersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  List<Reminder> reminders = snapshot.data!;

                  // Iterate through reminders and schedule notifications for those that are active and have a valid remindertime

                  return ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      // if (reminders[index].activeinactive &&
                      //     reminders[index].remindertime.isNotEmpty) {
                      //   // Parse remindertime string to DateTime

                      //   // int differenceInSeconds = calculateTimeDifference(
                      //   //     reminders[index].remindertime);

                      //   // generateReminderNotification(
                      //   //   id: index,
                      //   //   title: "DVM REMINDER",
                      //   //   body:
                      //   //       "It's Time for : ${reminders[index].title} ${reminders[index].remindertime}",
                      //   //   delay: differenceInSeconds,
                      //   // );
                      // }
                      return InkWell(
                        onLongPress: () {
                          _showDeleteConfirmationDialog(
                              context, reminders[index]);
                        },
                        child: Card(
                          elevation: 10,
                          child: ListTile(
                            title: Text(
                              reminders[index].title,
                              style: const TextStyle(
                                  color: themecolor,
                                  fontWeight: FontWeight.bold),
                            ),
                            trailing: Switch(
                              value: reminders[index].activeinactive,
                              onChanged: (value) {
                                updateReminderStatus(
                                    reminders[index].id, value);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: true,
        glowColor: themecolor,
        child: FloatingActionButton(
          backgroundColor: themecolor,
          onPressed: () {
            _showAddReminderDialog(
                context, isAvailable, speech, userData['email']);
          },
          child: const Icon(
            Icons.add_alarm,
            color: whitecolor,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddReminderDialog(BuildContext context, bool isAvailable,
      stt.SpeechToText speech, String email) async {
    String reminderText = '';
    TimeOfDay selectedTime = TimeOfDay.now();
    bool startrecord = false;
    TextEditingController mytext = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: mytext,
                      onChanged: (value) {
                        reminderText = value;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter reminder',
                      ),
                    ),
                  ),
                  AvatarGlow(
                    animate: startrecord,
                    glowColor:
                        startrecord ? const Color(0xFF00B0C7) : whitecolor,
                    child: InkWell(
                      onTapUp: (up) async {
                        await Future.delayed(const Duration(seconds: 2));
                        setState(() {
                          mytext.text = reminderText;
                          startrecord = false;
                        });
                        speech.stop();
                      },
                      onTapDown: (down) async {
                        PermissionStatus status =
                            await Permission.microphone.request();
                        if (status == PermissionStatus.granted) {
                          if (isAvailable) {
                            speech.listen(onResult: (value) {
                              reminderText = "${value.recognizedWords} ";
                            });
                          }
                        } else {}

                        setState(() {
                          startrecord = true;
                        });
                      },
                      child: const Icon(
                        Icons.mic,
                        color: themecolor,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Time:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                _formatTime(selectedTime),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('Reminders')
                        .add({
                      'title': reminderText,
                      'email': email, // Use the appropriate email here
                      'remindertime': '${_formatTime(selectedTime)}',
                      'activeinactive':
                          true, // Assuming all new reminders are active by default
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> fetchRemindersFromFirestore(
      String userEmail) async {
    // Fetch reminders from Firestore for a specific user
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Reminders')
        .where('email', isEqualTo: userEmail)
        .get();
    return querySnapshot.docs;
  }

  String _formatTime(TimeOfDay timeOfDay) {
    String period = timeOfDay.hour < 12 ? 'AM' : 'PM';
    int hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    String minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void updateReminderStatus(String reminderId, bool newStatus) async {
    try {
      // Update reminder status in Firestore
      await FirebaseFirestore.instance
          .collection('Reminders')
          .doc(reminderId)
          .update({'activeinactive': newStatus});

      // If the update is successful, call setState to rebuild the UI
      setState(() {
        // You can add any additional state updates here if needed
      });
    } catch (e) {
      // Handle the error if the update operation fails
      // You can show a snackbar, toast, or any other UI element to notify the user about the error
    }
  }
}

Future<void> _showDeleteConfirmationDialog(
    BuildContext context, Reminder reminder) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Reminder'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Would you like to delete this reminder?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Yes'),
            onPressed: () {
              // Delete the reminder from Firestore
              deleteReminder(reminder.id);
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void deleteReminder(String reminderId) async {
  try {
    await FirebaseFirestore.instance
        .collection('Reminders')
        .doc(reminderId)
        .delete();
  } catch (e) {
    // Handle error
  }
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
