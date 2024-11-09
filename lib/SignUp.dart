// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicly/Home.dart';
import 'package:musicly/SignIn.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? usernameError;
  DatabaseReference ref = FirebaseDatabase.instance.ref("Users");
  bool isLoading =false;

  void validateUsername(String username) {
    ref.child(username).get().then((child) {
      setState(() {
        if (child.exists) {
          usernameError = 'Username already exists';
        } else {
          usernameError = null; // Clear the error if username is valid
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent, // Transparent background
        elevation: 0, // No shadow
      ),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular logo
                ClipOval(
                  child: Image.asset(
                    'assets/ic_launcher.png', // Ensure the correct asset path
                    width: 120, // Set width for the circular image
                    height: 120, // Set height for the circular image
                    fit: BoxFit.cover, // Cover the entire area
                  ),
                ),
                SizedBox(height: 20.0), // Space between logo and fields
          
                // Username TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        spreadRadius: 1.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 95, 95, 95)), // Color of label text
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 95, 95, 95), // Border color when inactive
                          width: 1.0, // Border width
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 0, 0, 0), // Border color when focused
                          width: 2.0, // Thicker border when focused
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: usernameError, // Show error message if exists
                    ),
                    onChanged: validateUsername, // Validate on change
                  ),
                ),
                SizedBox(height: 16.0), // Spacing between text fields
          
                // Email TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        spreadRadius: 1.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 95, 95, 95)), // Color of label text
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 95, 95, 95), // Border color when inactive
                          width: 1.0, // Border width
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 0, 0, 0), // Border color when focused
                          width: 2.0, // Thicker border when focused
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16.0), // Spacing between text fields
          
                // Password TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        spreadRadius: 1.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 95, 95, 95)), // Color of label text
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 95, 95, 95), // Border color when inactive
                          width: 1.0, // Border width
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 0, 0, 0), // Border color when focused
                          width: 2.0, // Thicker border when focused
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20.0), // Spacing before button
          
                ElevatedButton(
                  onPressed: usernameError == null ? () async {
                    setState(() {
                      isLoading = true;
                    });
                    try {
                      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      if (credential.user != null) {
                        await credential.user!.updateDisplayName(usernameController.text);
                        ref.child(usernameController.text).set({
                          "UserId": credential.user!.uid,
                          "EmailId": credential.user!.email,
                          "Created Rooms": "",
                          "Joined Rooms": "",
                          "Playlist": ""
                        }).then((onValue) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => Home()),
                            (Route<dynamic> route) => false, // Removes all previous routes
                          );
                        }).onError((error, stackTrace) {
                          
                        });
                      }
                    } on FirebaseAuthException catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      if (e.code == 'weak-password') {
                        Fluttertoast.showToast(
                          msg: "The password provided is too weak.",
                          toastLength: Toast.LENGTH_LONG,
                          timeInSecForIosWeb: 5,
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                          textColor: const Color.fromARGB(255, 255, 217, 0),
                          fontSize: 16.0
                        );
                      } else if (e.code == 'email-already-in-use') {
                        Fluttertoast.showToast(
                          msg: "The account already exists for that email.",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.TOP,
                          timeInSecForIosWeb: 5,
                          backgroundColor: Colors.white.withOpacity(0.6),
                          textColor: Colors.black,
                          fontSize: 16.0
                        );
                      }
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      Fluttertoast.showToast(
                        msg: "An error occurred. Please check your connection and try again.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Button color
                    foregroundColor: const Color.fromARGB(255, 248, 205, 50),
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0), // Button padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                  ),
                  child: Text('Sign Up'),
                ),
                SizedBox(height: 20.0), // Spacing before the navigation text
          
                TextButton(
                  onPressed: () {
                    // Navigate to Sign In page
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => SignIn()),
                      (Route<dynamic> route) => false, // Removes all previous routes
                    );
                  },
                  child: Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: Colors.black), // Set text color to black
                  ),
                ),
              ],
            ),
          ),
          if(isLoading)Container(
            color: Colors.black.withOpacity(0.5), // Semi-transparent background
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Center the column vertically
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 20), // Space between progress bar and text
                  Text(
                    'Signing Up, please wait...', // Custom loading text
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
