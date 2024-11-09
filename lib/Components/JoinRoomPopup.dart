// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicly/Room.dart';

class JoinRoomPopup extends StatefulWidget {
  @override
  _JoinRoomPopupState createState() => _JoinRoomPopupState();
}

class _JoinRoomPopupState extends State<JoinRoomPopup> {
  final List<TextEditingController> controllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(5, (_) => FocusNode());
  String verificationMessage = "";
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  bool isLoading = false;

  bool isRoomCodeComplete() {
    return controllers.every((controller) => controller.text.length == 1);
  }

  Future<bool> verifyRoomCode(String roomCode) async {
    // Simulate an API call or database check
    DataSnapshot room = await ref.child("Rooms").child(roomCode).get();
    return room.exists; // Example: only 'abc12' is a valid code
  }

  @override
  Widget build(BuildContext context) {
    return !isLoading?AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      content: Container(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Join Room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the popup
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                return Container(
                  width: 40,
                  child: TextField(
                    controller: controllers[index],
                    textAlign: TextAlign.center,
                    focusNode: focusNodes[index],
                    maxLength: 5, 
                    onChanged: (value) {
                      if (index == 0 && value.length >= 5) {
                        // If user pastes more than 5 characters, split and assign them
                        String code = value.substring(0, 5);
                        for (int i = 0; i < 5; i++) {
                          controllers[i].text = i < code.length ? code[i] : '';
                        }
                        FocusScope.of(context).requestFocus(focusNodes[4]);
                      }else if (value.length == 1) {
                        // Move to the next field if a character is entered
                        if (index < 4) {
                          FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                        }
                      }else if(value=="" && index!=0){
                        FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                      }else if(value.length>=2){
                        controllers[index].text = value[value.length-1];
                        if(index < 4) {
                          FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                        }
                      }
                      setState(() {
                        verificationMessage = "";
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: '', // Hide counter
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            ElevatedButton(
               onPressed:  () async {
                setState(() {
                  isLoading = true;
                });
                String roomCode = controllers.map((controller) => controller.text).join();
                if(!isRoomCodeComplete()){
                  Fluttertoast.showToast(msg: "Enter full Code");
                  setState(() {
                    isLoading = false;
                  });
                  return;
                }
                bool exists = await verifyRoomCode(roomCode);
                if (exists) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => RoomPage(roomCode: roomCode,)),
                    (Route<dynamic> route) => false, // Removes all previous routes
                  );
                } else{
                  setState(() {
                    isLoading = false;
                    verificationMessage = 'Room code does not exist.';
                  });
                }
              },
              child: Text('Join Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRoomCodeComplete() ? Colors.white : Colors.grey, // Set color based on state
              ),
            ),
            SizedBox(height: 10),
            Text(
              verificationMessage,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    ):
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
              'Joining Room, please wait...', // Custom loading text
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    )
    ;
  }
}
