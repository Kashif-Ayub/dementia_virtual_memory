// ignore_for_file: file_names

import 'dart:convert';
import 'dart:io';
import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:dementia_virtual_memory/Screens/CareTaker/PatientLocationViewer.dart';
import 'package:dementia_virtual_memory/Screens/CareTaker/UploadsInfo.dart';
import 'package:dementia_virtual_memory/Screens/Login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CareTakerDashboard extends StatefulWidget {
  const CareTakerDashboard({super.key});

  @override
  State<CareTakerDashboard> createState() => _CareTakerDashboardState();
}

class _CareTakerDashboardState extends State<CareTakerDashboard> {
  late Map<String, dynamic> userData;
  late Future<List<DocumentSnapshot>> _patientsFuture;
  File? _image;
  File? _video;
  VideoPlayerController? _videoPlayerController;

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

  Future<void> _getImageFromGallery({required String patientEmail}) async {
    if (await _requestGalleryPermission()) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        _showImageDialog(patientemail: patientEmail);
      }
    }
  }

  Future<void> _getVideoFromGallery({required String patientEmail}) async {
    if (await _requestGalleryPermission()) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _video = File(pickedFile.path);
          _videoPlayerController = VideoPlayerController.file(_video!)
            ..initialize().then((_) {
              setState(() {});
              _showVideoDialog(patientemail: patientEmail);
            });
        });
      }
    }
  }

  Future<bool> _requestGalleryPermission() async {
    var storageStatus = await Permission.storage.request();
    print('Storage permission status: $storageStatus');

    if (storageStatus.isGranted) {
      print('Storage permission granted');
      return true;
    } else {
      var photoStatus = await Permission.photos.request();
      print('Photo permission status: $photoStatus');

      if (photoStatus.isGranted) {
        print('Photo permission granted');
        return true;
      } else {
        print('Permissions denied');
        return false;
      }
    }
  }

  void _showImageDialog({required String patientemail}) {
    String description = '';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Selected Image'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _image != null ? Image.file(_image!) : Container(),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Enter description...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        description = value;
                      },
                    ),
                    if (isUploading) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Upload'),
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (description.isNotEmpty && _image != null) {
                            setState(() {
                              isUploading = true;
                            });
                            String imageURL =
                                await uploadFile(_image!, 'images');
                            if (imageURL.isNotEmpty) {
                              await saveFileDetails(imageURL, description,
                                  userData['email'], patientemail, true);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Image uploaded successfully!')));
                            } else {
                              setState(() {
                                isUploading = false;
                              });
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Failed to upload image')));
                            }
                          } else {
                            // Show error if description is empty or image is null
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Description cannot be empty')));
                          }
                        },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: isUploading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVideoDialog({required String patientemail}) {
    String description = '';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Selected Video'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _videoPlayerController != null &&
                            _videoPlayerController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio:
                                _videoPlayerController!.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(_videoPlayerController!),
                                _ControlsOverlay(
                                    controller: _videoPlayerController!),
                                VideoProgressIndicator(_videoPlayerController!,
                                    allowScrubbing: true),
                              ],
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Enter description...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        description = value;
                      },
                    ),
                    if (isUploading) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Upload'),
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (description.isNotEmpty && _video != null) {
                            setState(() {
                              isUploading = true;
                            });
                            String videoURL =
                                await uploadFile(_video!, 'videos');
                            if (videoURL.isNotEmpty) {
                              await saveFileDetails(videoURL, description,
                                  userData['email'], patientemail, false);
                              Navigator.of(context).pop();
                              _videoPlayerController?.dispose();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Video uploaded successfully!')));
                              setState(() {
                                _videoPlayerController = null;
                              });
                            } else {
                              setState(() {
                                isUploading = false;
                              });
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Failed to upload video')));
                            }
                          } else {
                            // Show error if description is empty or video is null
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Description cannot be empty')));
                          }
                        },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: isUploading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _videoPlayerController?.dispose();
                          setState(() {
                            _videoPlayerController = null;
                          });
                        },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _videoPlayerController?.pause();
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(414, 896));
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
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<DocumentSnapshot>? patients = snapshot.data;
                  if (patients == null || patients.isEmpty) {
                    return const Center(child: Text('No patients found'));
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
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UploadsInfo(
                                      caretakerEmail: userData['email'],
                                      patientEmail: patients[index]['email'],
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 5,
                                margin: EdgeInsets.symmetric(
                                    vertical: 10.h, horizontal: 20.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.sp),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PatientLocationViewer(
                                                    patientName: patients[index]
                                                        ['name'],
                                                    latitude: patients[index][
                                                        'lat'], // Example latitude
                                                    longitude: patients[index][
                                                        'long'], // Example longitude
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.location_pin,
                                              color: themecolor,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              _getVideoFromGallery(
                                                  patientEmail: patients[index]
                                                      ['email']);
                                            },
                                            icon: const Icon(Icons.video_call,
                                                color: themecolor),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              _getImageFromGallery(
                                                  patientEmail: patients[index]
                                                      ['email']);
                                            },
                                            icon: const Icon(
                                              Icons.add_photo_alternate,
                                              color: themecolor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({Key? key, required this.controller})
      : super(key: key);

  final VideoPlayerController controller;

  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  static const _playIcon = Icons.play_arrow;
  static const _pauseIcon = Icons.pause;
  bool isplaying = false;
  Future<void> _changeStateofplaypause() async {
    isplaying = !isplaying;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        widget.controller.value.isPlaying
            ? widget.controller.pause()
            : widget.controller.play();
        await _changeStateofplaypause();
        setState(() {});
      },
      child: Stack(
        children: <Widget>[
          if (!widget.controller.value.isPlaying)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  isplaying ? _pauseIcon : _playIcon,
                  color: Colors.white,
                  size: 50.0,
                ),
              ),
            ),
          Center(
            child: AnimatedOpacity(
              opacity: isplaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isplaying ? _pauseIcon : _playIcon,
                color: Colors.white,
                size: 50.0.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Function to upload image or video to Firebase Storage
Future<String> uploadFile(File file, String path) async {
  try {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference =
        FirebaseStorage.instance.ref().child('$path/$fileName');
    UploadTask uploadTask = storageReference.putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String fileURL = await taskSnapshot.ref.getDownloadURL();
    return fileURL;
  } catch (e) {
    print('Error uploading file: $e');
    return '';
  }
}

// Function to save file details to Firestore
Future<void> saveFileDetails(String fileURL, String description,
    String caretakerEmail, String patientEmail, bool isImage) async {
  try {
    await FirebaseFirestore.instance.collection('uploads').add({
      'caretakerEmail': caretakerEmail,
      'patientEmail': patientEmail,
      'fileURL': fileURL,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'isImage': isImage
    });
  } catch (e) {
    print('Error saving file details: $e');
  }
}
