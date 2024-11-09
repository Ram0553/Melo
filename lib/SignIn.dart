// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicly/Home.dart';
import 'package:musicly/SignUp.dart';

class SignIn extends StatefulWidget {

  SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController usernameController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

   bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Added title for better identification
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
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
          
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
                SizedBox(height: 20.0), // Spacing between text fields
                
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // Handle forgot password logic
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.black), // Set text color to black
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp()));
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.black), // Set text color to black
                    ),
                  ),
                ],
              ),
          
                SizedBox(height: 20.0), // Spacing before button
                
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });
                    try {
                      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: usernameController.text.trim(),
                        password: passwordController.text.trim(),
                      );
          
                      if (credential.user != null) {
                        Fluttertoast.showToast(
                          msg: "Login successful!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
          
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => Home()),
                          (Route<dynamic> route) => false, // Removes all previous routes
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      String errorMessage;
          
                      switch (e.code) {
                        case 'user-not-found':
                          errorMessage = "No user found with this email.";
                          break;
                        case 'wrong-password':
                          errorMessage = "Incorrect password. Please try again.";
                          break;
                        case 'invalid-email':
                          errorMessage = "The email address is not valid.";
                          break;
                        case 'user-disabled':
                          errorMessage = "This user has been disabled.";
                          break;
                        case 'too-many-requests':
                          errorMessage = "Too many attempts. Please try again later.";
                          break;
                        case 'operation-not-allowed':
                          errorMessage = "Email/password sign-in is disabled.";
                          break;
                        default:
                          errorMessage = "An unknown error occurred.";
                      }
          
                      Fluttertoast.showToast(
                        msg: errorMessage,
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                      );
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
                  },
                  child: Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Button color changed to a neutral grey
                    foregroundColor: const Color.fromARGB(255, 248, 205, 50),
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0), // Button padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
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
                    'Signing in, please wait...', // Custom loading text
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
