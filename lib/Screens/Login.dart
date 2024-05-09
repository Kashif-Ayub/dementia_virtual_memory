import 'package:dementia_virtual_memory/Constants/Constants.dart';
import 'package:dementia_virtual_memory/Screens/CareTaker/Dashboard.dart';
import 'package:dementia_virtual_memory/Screens/Patient/Dashboard.dart';
import 'package:dementia_virtual_memory/Screens/Welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLogingin = false;
  bool _validateInputs() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
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
    return true;
  }

  bool _isEmailValid(String email) {
    final RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  void _login() async {
    if (_isLogingin) return;
    if (_validateInputs()) {
      setState(() {
        _isLogingin = true; // Start Log in process
      });

      try {
        // Sign in with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);

        // Get user ID
        String userId = userCredential.user!.uid;

        // Retrieve user data from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        dynamic data = userData.data(); // Assign your data here

// Check if userData is not null
        if (data != null) {
          // Cast userData to Map<String, dynamic> and assign it to user
          Map<String, dynamic> user = data as Map<String, dynamic>;

          _showSuccessSnackbar("Welcome  ${user['name']}!");
          if (user['role'] == "patient") {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const PatientDashboard()));
          } else if (user['role'] == "caretaker") {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const CareTakerDashboard()));
          }
        }

        // Navigate to the next screen or perform any other actions
      } on FirebaseAuthException catch (e) {
        // Handle login errors
        _showErrorSnackbar(e.message);
      } finally {
        setState(() {
          _isLogingin = false; // End registration process
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
        margin: EdgeInsets.only(bottom: ScreenUtil().screenHeight * 0.8),
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
          'Login',
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 50.h),
                        child: Column(
                          children: [
                            Text(
                              "D V M",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: themecolor,
                                fontSize: 35.sp,
                              ),
                            ),
                            Text(
                              "Dementia Virtual Memory",
                              style:
                                  TextStyle(color: themecolor, fontSize: 20.sp),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _buildInputField(
                      context, 'Email', Icons.email, _emailController),
                  SizedBox(height: 20.h),
                  _buildPasswordField(context, _passwordController),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 75.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.w),
                      ),
                    ),
                    child: _isLogingin
                        ? const CircularProgressIndicator(
                            color: whitecolor,
                          ) // Show progress indicator
                        : Text(
                            'Login',
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
                        'New User? ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const Welcome()));
                          // Navigate to login screen
                        },
                        child: Text(
                          'Register',
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
