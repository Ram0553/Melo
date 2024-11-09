// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:musicly/Room.dart';

class CreateRoomPopup extends StatefulWidget {
  @override
  State<CreateRoomPopup> createState() => _CreateRoomPopupState();
}

class _CreateRoomPopupState extends State<CreateRoomPopup> {
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  String userName = FirebaseAuth.instance.currentUser!.displayName!;

  bool isLoading = false;

  Future createAndCheckRoomCode() async {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    String code = "";
    while(code==""){
      code = List.generate(5, (index) => characters[random.nextInt(characters.length)]).join();
      ref.child(code).get().then((child) {
        if(child.exists){
          code="";
        }
      });
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController roomNameController = TextEditingController();

    return !isLoading?AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Create Room'),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      ),
      content: TextField(
        controller: roomNameController,
        decoration: InputDecoration(
          labelText: 'Room Name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
         Center(
            child: Container(
                color: Colors.transparent,
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  isLoading = true;
                });
                String roomName = roomNameController.text;
                String roomCode = await createAndCheckRoomCode();
                await ref.child("Rooms").child(roomCode).set({"Name":roomName,"SuperAdmin": userName});
                await ref.child("Users").child(userName).child("Created Rooms").update({roomCode:roomName});
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => RoomPage(roomCode: roomCode,)),
                  (Route<dynamic> route) => false, // Removes all previous routes
                );
                setState(() {
                  isLoading = false;
                });
              },
              child: Text('Create'),
            ),
          ),
        ),
      ],
    )
    :
    Container(
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
              'Creating Room, please wait...', // Custom loading text
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
