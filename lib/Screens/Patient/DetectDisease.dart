import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetectDisease extends StatefulWidget {
  const DetectDisease({super.key});

  @override
  State<DetectDisease> createState() => _DetectDiseaseState();
}

class _DetectDiseaseState extends State<DetectDisease> {
  File? _image;
  String _result = "";
  bool _isLoading = false;

  Future<void> _getImageFromGallery() async {
    if (await _requestGalleryPermission()) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          _image = null;
        }
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    if (await _requestCameraPermission()) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          _image = null;
        }
      });
    }
  }

  Future<bool> _requestGalleryPermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    } else {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        // Display a dialog explaining why permission is needed
      }
      return false;
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (await Permission.camera.request().isGranted) {
      return true;
    } else {
      // Handle permissions not granted
      return false;
    }
  }

  Future<void> _detectDisease() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.0.4:8051/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();

      final responseData = json.decode(responseBody);
      setState(() {
        _result = responseData.toString();
      });
    } else {
      setState(() {
        _result = "Error detecting disease";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: const Size(375, 812), minTextAdapt: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detect Disease',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from gallery'),
                          onTap: () {
                            _getImageFromGallery();
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take a picture'),
                          onTap: () {
                            _getImageFromCamera();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _image != null
                  ? Container(
                      height: 0.4.sh,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        image: DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Expanded(
                      child: Center(
                        child: Text(
                          "Upload Image to Detect",
                          style: TextStyle(fontSize: 18.sp),
                        ),
                      ),
                    ),
              SizedBox(height: 20.h),
              if (_image != null)
                Container(
                  width: double.infinity,
                  height: 50.h,
                  child: InkWell(
                    onTap: _isLoading ? null : _detectDisease,
                    child: Container(
                      decoration: BoxDecoration(
                        color: themecolor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Detect",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              if (_image != null) SizedBox(height: 20.h),
              Text(
                " Result :    $_result",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
