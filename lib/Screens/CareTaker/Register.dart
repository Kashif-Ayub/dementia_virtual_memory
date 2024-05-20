import 'dart:io';

import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:dementia_virtual_memory/Screens/Login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterCareTaker extends StatefulWidget {
  const RegisterCareTaker({super.key});

  @override
  _RegisterCareTakerState createState() => _RegisterCareTakerState();
}

class _RegisterCareTakerState extends State<RegisterCareTaker> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isRegistering = false;
  late File _image = File('');

  Future<void> _getImageFromGallery() async {
    if (await _requestGalleryPermission()) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {}
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
        } else {}
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

  bool _validateInputs() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (!_isEmailValid(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_image.path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your profile photo.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  bool _isEmailValid(String email) {
    final RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  void _register() async {
    if (_isRegistering) return;
    if (_validateInputs()) {
      setState(() {
        _isRegistering = true; // Start registration process
      });
      // Your registration logic here

      // You can also use _image if it's not null to get the selected image

      try {
        // Create user with email and password
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Get user ID
        String userId = userCredential.user!.uid;

        // Upload image to Firebase Storage

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('$userId.jpg');
        UploadTask uploadTask = ref.putFile(_image);
        TaskSnapshot taskSnapshot = await uploadTask;
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        // Add user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'image': imageUrl, // URL of uploaded image
          'role': 'caretaker',
        });

        // Registration successful

        _showSuccessSnackbar("Registration successful!");
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Login()));
      } on FirebaseAuthException catch (e) {
        _showErrorSnackbar(e.message);
      } finally {
        setState(() {
          _isRegistering = false; // End registration process
        });
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF02F70B)),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: themecolor, // Customize background color
        duration: const Duration(seconds: 5), // Set duration for the Snackbar
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String? errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage == "" || errorMessage == null
            ? "An unknown error occurred. Please try again later."
            : errorMessage),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareTaker',
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
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Show options for image selection
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
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 60.w,
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage:
                            _image.path.isNotEmpty ? FileImage(_image) : null,
                        child: _image.path.isEmpty
                            ? Icon(
                                Icons.add_a_photo,
                                size: 60.w,
                                color: whitecolor,
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _buildInputField(
                      context, 'Name', Icons.person, _nameController),
                  SizedBox(height: 20.h),
                  _buildInputField(
                      context, 'Email', Icons.email, _emailController),
                  SizedBox(height: 20.h),
                  _buildPasswordField(context, _passwordController),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 75.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.w),
                      ),
                    ),
                    child: _isRegistering
                        ? const CircularProgressIndicator(
                            color: whitecolor,
                          ) // Show progress indicator
                        : Text(
                            'Register',
                            style:
                                TextStyle(fontSize: 18.sp, color: whitecolor),
                          ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          'OR',
                          style: TextStyle(fontSize: 18.sp),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an Account? ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to login screen
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const Login()));
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String hintText,
      IconData iconData, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.w),
        color: Colors.grey[200],
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15.h),
          prefixIcon: Icon(
            iconData,
            color: themecolor,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      BuildContext context, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.w),
        color: Colors.grey[200],
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: TextField(
        controller: controller,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          hintText: 'Password',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15.h),
          prefixIcon: const Icon(
            Icons.lock,
            color: themecolor,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            child: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
          ),
        ),
      ),
    );
  }
}
