// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:http/http.dart' as http;
import 'package:musicly/Components/SongListItem.dart';
import 'package:musicly/Components/player_widget.dart';
import 'package:musicly/Home.dart';
import 'package:musicly/Objects/SongObject.dart';
import 'package:share_plus/share_plus.dart';

class RoomPage extends StatefulWidget {
  final String roomCode;

  const RoomPage({super.key, required this.roomCode});

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  String userName = FirebaseAuth.instance.currentUser!.displayName!;
  String superAdmin="", admin="", roomCode="", roomName="";
  List<String> roomUsers=[];
  var tracks = [];
  List<Song> playlist = [];
  late AudioPlayer player = AudioPlayer();
  Timer? timer;
  TextEditingController searchController = TextEditingController();

  String query = "";
  Song? currentSong;
  bool isTyping = false;
  int currentIndex = -1;

  @override
  void initState() {
    super.initState();

    player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);
    player.onPlayerComplete.listen((event) {
      if((superAdmin!="" && userName==superAdmin) || (superAdmin=="" && userName==admin)){
        onNextSong();
      }
    });

    roomCode = widget.roomCode;
    ref.child("Rooms").child(roomCode).keepSynced(true);
    DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    ForegroundService().start();
    fetchAdminDetails().then((value){
      _listenForRoomUsers();
      listenSongUpdate();
      listenPlaylistUpdates();
      setPresence();
    });
  }

  @override
  void dispose() {
    leaveRoom();
    super.dispose();
  }

  void setPresence() {
      final userStatusDatabaseRef = FirebaseDatabase.instance.ref().child("Rooms/$roomCode");
      if(superAdmin==userName){
        userStatusDatabaseRef.child("SuperAdmin").onDisconnect().remove();
      }
      else if(userName==admin){
        userStatusDatabaseRef.child("Users/$userName").onDisconnect().cancel();
        userStatusDatabaseRef.child("Admin").onDisconnect().remove();
      }else{
        userStatusDatabaseRef.child("Admin").onDisconnect().cancel();
        userStatusDatabaseRef.child("Users/$userName").onDisconnect().remove();
      }
  }

  void updateSeek() async {
    if((superAdmin!="" && userName==superAdmin) || (superAdmin=="" && userName==admin)){
      if(timer!=null)return;
      timer = Timer.periodic(Duration(seconds: 3), (Timer t) async {
        if(timer!=null && player.state!=PlayerState.playing)return;
        var curDur = (await player.getCurrentPosition() as Duration).inMilliseconds;
        await ref.child("Rooms").child(roomCode).child("Current Song").update({"SeekTo":curDur});
      });
    }else{
      timer?.cancel();
      timer = null;
    }
  }

  Future fetchAdminDetails() async {
    DataSnapshot result = await ref.child("Rooms").child(roomCode).child("Name").get();
    roomName = result.value.toString();
      
    result = await ref.child("Users").child(userName).child("Created Rooms").child(roomCode).get();
    if(result.exists){
      superAdmin = userName;
      setState(() {
        superAdmin = userName;
      });
      await ref.child("Rooms").child(roomCode).update({"SuperAdmin": userName});
    }
    result = await ref.child("Rooms").child(roomCode).child("Admin").get();
    if(result.exists){
      admin = result.value.toString();
      setState(() {
        admin = result.value.toString();
      });
    }

    if(superAdmin!=userName){
      result = await ref.child("Rooms").child(roomCode).child("SuperAdmin").get();
      if(result.exists){
        superAdmin = result.value.toString();
        setState(() {
          superAdmin = result.value.toString();
        });
      }
      if(admin=="" && superAdmin==""){
        await _makeAdmin(userName);
        await ref.child("Users").child(userName).child("Joined Rooms").update({roomCode:roomName});
      }else{
        await ref.child("Rooms").child(roomCode).child("Users").update({userName:"True"});
        await ref.child("Users").child(userName).child("Joined Rooms").update({roomCode:roomName});
      }
    }
  }

  void _listenForRoomUsers() {
    ref.child("Rooms").child(roomCode).child("Users").onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> usersMap = event.snapshot.value as Map<dynamic, dynamic>;
        roomUsers = usersMap.keys.cast<String>().toList();
        setState(() {});
      } else {
        roomUsers = [];
        setState(() {roomUsers = [];});
      }
      updateSeek();
      setPresence();
    });

    ref.child("Rooms").child(roomCode).child("SuperAdmin").onValue.listen((event) async {
      if (event.snapshot.value != null) {
        String newSuperAdmin = event.snapshot.value as String;
        superAdmin = newSuperAdmin;
        setState(() {});
      } else {
        superAdmin = "";
        if(admin==""){
          if(userName==roomUsers[0]){
            await _makeAdmin(userName);
          }
        }
      }
      updateSeek();
      setPresence();
    });

    ref.child("Rooms").child(roomCode).child("Admin").onValue.listen((event) async {
      if (event.snapshot.exists) {
        String newAdmin = event.snapshot.value as String;
        setState(() {
          admin = newAdmin;
        });
      } else {
        if(superAdmin==""){
          if(userName==roomUsers[0]){
            await _makeAdmin(userName);
          }
        }else{
          setState(() {
            admin = "";
          });
        }
      }
      updateSeek();
      setPresence();
    });
  }

  void listenPlaylistUpdates(){
    ref.child("Rooms").child(roomCode).child("Playlist").onValue.listen((event) {
      if (event.snapshot.value != null) {
        DataSnapshot playlistMap = event.snapshot;
        List<Song?> newPlaylist = List.filled(playlistMap.children.length,null);
        playlistMap.children.forEach((value) {
          Song newSong = Song(
            album: value.child("Album").value.toString(),
            artist: value.child("Artist").value.toString(),
            downloadUrl: value.child("DownloadUrl").value.toString(),
            imageUrl: value.child("ImageUrl").value.toString(),
            title: value.child("Title").value.toString()
          );
          newPlaylist[value.child("Order").value as int] = newSong;
          if(currentSong!=null && currentSong!.downloadUrl==newSong.downloadUrl){
            currentIndex = value.child("Order").value as int;
          }
        });
        setState(() {
          playlist = newPlaylist.whereType<Song>().toList();
        });
      } else {
        setState(() {
          playlist=[]; // Reset if no joined rooms
        });
      }
    });
  }

  Future _makeAdmin(String selectedUser) async {
    await ref.child("Rooms").child(roomCode).update({"Admin": selectedUser});
    setState(() {
      admin = selectedUser;
    });
    await ref.child("Rooms").child(roomCode).child("Users").child(selectedUser).remove();
  }

  void _removeAdmin() async {
    await ref.child("Rooms").child(roomCode).child("Users").update({admin:"True"});
    await ref.child("Rooms").child(roomCode).child("Admin").remove(); // Remove admin from Firebase
    setState(() {
      admin = "";
    });
  }

  Future<bool> leaveRoom() async {
    player.dispose();
    ForegroundService().stop();
    if(superAdmin!=userName && admin!=userName){
      await ref.child("Rooms").child(roomCode).child("Users").child(userName).remove();
    }else if(userName==admin){
      await ref.child("Rooms").child(roomCode).child("Admin").remove();
      if(superAdmin==""){
        roomUsers.forEach((user) async {
          if(user!=superAdmin && user!=admin){
            await _makeAdmin(user);
            admin = user;
          }
        });
      }
    }else{
      await ref.child("Rooms").child(roomCode).child("SuperAdmin").remove();
      if(admin==""){
        roomUsers.forEach((user) async {
          if(user!=superAdmin && user!=admin){
            await _makeAdmin(user);
            admin = user;
          }
        });
      }
    }

    player.stop();
    superAdmin="";
    updateSeek();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Home()),
      (Route<dynamic> route) => false, // Removes all previous routes
    );
    return false;
  }

  void updateCurrentSong(Song? newSong) async {
    setState(() {
      currentSong = newSong;
    });
    if(newSong!=null){
      await ref.child("Rooms").child(roomCode).child("Current Song").set(
        {
          "ImageUrl": newSong.imageUrl,
          "Title": newSong.title,
          "Artist": newSong.artist,  // Adjust according to your API response
          "Album": newSong.album,    // Adjust according to your API response
          "DownloadUrl": newSong.downloadUrl,
          "SeekTo": 0,
          "Index":currentIndex
        }
      );
      player.play(UrlSource(newSong.downloadUrl));
    }else{
      player.stop();
    }
  }

  void playCurrentSong(newSong){
    setState(() {
      currentSong = newSong;
    });
    player.stop();
    if(newSong!=null){
      player.play(UrlSource(newSong.downloadUrl));
    }
  }

  void listenSongUpdate() {
    ref.child("Rooms").child(roomCode).child("Current Song").onValue.listen((event) async {
      ref.child("Rooms").child(roomCode).keepSynced(true);
      if (event.snapshot.value != null) {
        DataSnapshot value = event.snapshot;
        if(currentSong!=null && value.child("DownloadUrl").value.toString()==currentSong!.downloadUrl){
          if(value.child("State").exists){
            value.child("State").value.toString()=="Play"?player.resume():player.pause();
          }
          int seek = (value.child("SeekTo").value as int?) ?? 0;
          int curDur = (await player.getCurrentPosition() as Duration).inMilliseconds;
          if((curDur - seek).abs() < 2000){
            return;
          }
          Duration duration = Duration(milliseconds: seek);
          player.seek(duration);
        }else{
          DataSnapshot value = event.snapshot;
          Song newSong = Song(album: value.child("Album").value.toString(),
          artist: value.child("Artist").value.toString(),
          downloadUrl: value.child("DownloadUrl").value.toString(),
          imageUrl: value.child("ImageUrl").value.toString(),
          title: value.child("Title").value.toString());
          if(value.child("Index").exists) {
            currentIndex = int.parse(value.child("Index").value.toString());
          }
          playCurrentSong(newSong);
          if(value.child("State").exists && value.child("State").value.toString()=="Pause"){
            player.pause();
          }
          if(value.child("SeekTo").exists) {
            int seek = (value.child("SeekTo").value as int?) ?? 0;
            Duration duration = Duration(milliseconds: seek);
            player.seek(duration);
          }

        }
      } else {
        playCurrentSong(null);
      }
    });
  }

  void customSeek(int duration) async {
    await ref.child("Rooms").child(roomCode).child("Current Song").set(
        {
          "ImageUrl": currentSong!.imageUrl,
          "Title": currentSong!.title,
          "Artist": currentSong!.artist,  // Adjust according to your API response
          "Album": currentSong!.album,    // Adjust according to your API response
          "DownloadUrl": currentSong!.downloadUrl,
          "SeekTo": duration,
        }
      );
  }

  void customPause() async {
    await ref.child("Rooms").child(roomCode).child("Current Song").set(
        {
          "ImageUrl": currentSong!.imageUrl,
          "Title": currentSong!.title,
          "Artist": currentSong!.artist,  // Adjust according to your API response
          "Album": currentSong!.album,    // Adjust according to your API response
          "DownloadUrl": currentSong!.downloadUrl,
          "SeekTo": (await player.getCurrentPosition() as Duration).inMilliseconds,
          "State":"Pause"
        }
      );
  }

  void customPlay() async {
    await ref.child("Rooms").child(roomCode).child("Current Song").set(
        {
          "ImageUrl": currentSong!.imageUrl,
          "Title": currentSong!.title,
          "Artist": currentSong!.artist,  // Adjust according to your API response
          "Album": currentSong!.album,    // Adjust according to your API response
          "DownloadUrl": currentSong!.downloadUrl,
          "SeekTo": (await player.getCurrentPosition() as Duration).inMilliseconds,
          "State":"Play"
        }
      );
  }

  void onNextSong() {
    if(currentSong==null)return;
    if(playlist.isEmpty){
      updateCurrentSong(currentSong);
      return;
    }
    if(currentIndex<0 || currentIndex >= playlist.length-1){
      currentIndex = 0;
    }else{
      currentIndex ++;
    }
    updateCurrentSong(playlist[currentIndex]);
    updatePlaylist();
  }

  void onPreviousSong() {
    if(currentSong==null)return;
    if(playlist.isEmpty){
      updateCurrentSong(currentSong);
      return;
    }
    if(currentIndex<=0 || currentIndex > playlist.length-1){
      currentIndex = playlist.length-1;
    }else{
      currentIndex --;
    }
    updateCurrentSong(playlist[currentIndex]);
    updatePlaylist();
  }

  void updatePlaylist() {
    if (currentIndex < 0 || currentIndex >= playlist.length) {
      return;
    }
    Song songToMove = playlist[currentIndex];

    List<Song> updatedPlaylist = [songToMove];

    for (int i = currentIndex + 1; i < playlist.length; i++) {
      updatedPlaylist.add(playlist[i]);
    }

    for (int i = 0; i < currentIndex; i++) {
      updatedPlaylist.add(playlist[i]);
    }
    uploadPlaylist(updatedPlaylist);
  }

  void uploadPlaylist(newPlaylist) {
    const int paddingWidth = 4;
    Map<String, Map<String, dynamic>> playlistMap = {};

    for (int i = 0; i < newPlaylist.length; i++) {
      Song song = newPlaylist[i];
      playlistMap[i.toString().padLeft(paddingWidth, '0')] = {
        "Order": i,
        "ImageUrl": song.imageUrl,
        "Title": song.title,
        "Artist": song.artist,
        "Album": song.album,
        "DownloadUrl": song.downloadUrl,
      };
    }
    ref.child("Rooms").child(roomCode).child("Playlist").set(playlistMap);
  }

  Future<void> fetchTracks(String query) async {
    if(query==""){
      return;
    }
    final response = await http.get(
      Uri.parse('https://saavn.dev/api/search/songs').replace(queryParameters: {
        'query': query,
        'limit': '15',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Assuming the relevant data is in data['data'] and it's a list of songs
      setState(() {
        tracks.clear(); // Clear previous tracks
        for (var track in data['data']['results']) {
          tracks.add(Song.fromMap(track)); // Modify as per the API response structure
        }
      });
    } else {
      
    }
  }
  
  void addToPlaylist(Song song){
    const int paddingWidth = 4;
    ref.child("Rooms").child(roomCode).child("Playlist").update({ 
      playlist.length.toString().padLeft(paddingWidth, '0'):
      {
        "ImageUrl": song.imageUrl,
        "Title": song.title,
        "Artist": song.artist,
        "Album": song.album,
        "DownloadUrl": song.downloadUrl,
        "Order":playlist.length
      }
    });
  }

  void removeFromPlaylist(Song song){
    playlist.remove(song);
    currentIndex++;
    updatePlaylist();
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: leaveRoom,
      child: Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer(); // Open the drawer
          },);}),
        bottom:(userName==admin || userName==superAdmin)?PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                query = value;
                fetchTracks(query);
              },
              decoration: InputDecoration(
                hintText: 'Search for tracks...',
                hintStyle: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic), // Subtle hint text
                filled: true, // Adds a background color
                fillColor: Colors.grey[100], // Light background color
                contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0), // Proper padding
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0), // Rounded corners
                  borderSide: BorderSide.none, // No visible border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0), // Subtle border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0), // Accent border when focused
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]), // Stylish search icon
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]), // Clear icon to reset search
                        onPressed: () {
                          setState(() {
                            query = '';
                            tracks.clear();
                            searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ) : null,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(roomCode),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    // Copy room code to clipboard
                    Clipboard.setData(ClipboardData(text: roomCode));
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              final String message = 'Join my room: $roomName\n\n'
                           'Room Code: *$roomCode*\n\n'
                           'Please copy the code above to join!';
              Share.share(message);
            },
          ),
        ],
      ),
      drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 237, 219, 250),
                ),
                child: SizedBox(
                  height: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, 
                    mainAxisAlignment: MainAxisAlignment.center,// Align children to the start
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/ic_launcher.png', // Update with your logo asset path
                          width: 80, // Set width for the logo
                          height: 80, // Set height for the logo
                          fit: BoxFit.cover, // Cover the entire area
                        ),
                      ),// Space between logo and username
                      // Username
                      Text(
                        roomName, // Replace this with the actual username variable
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                title: Text('Leave Room'),
                onTap: () {
                  leaveRoom();
                },
              ),
              if(superAdmin!="")Divider(),
              // Admin Section
              if(superAdmin!="")ListTile(
                title: Text('Super Admin'),
                subtitle: Text(superAdmin),
              ),
              
              if(admin!="") Divider(),
              // Admin Section
              if(admin!="") ListTile(
                title: Text('Admin'),
                subtitle: admin.isNotEmpty ? Text(admin) : Text('No admin assigned'),
                trailing: superAdmin == userName
                    ? ElevatedButton(
                        onPressed: _removeAdmin,
                        child: Text('Remove Admin'),
                      )
                    : null, 
              ),
              Divider(),
              ListTile(
                title: Text('Users in Room'),
              ),
              // Display users with the "Make Admin" button
              for (String user in roomUsers)
                ListTile(
                  title: Text(user),
                  trailing: (userName==superAdmin || userName==admin)? ElevatedButton(
                    onPressed: () {
                      if(admin==userName){
                        ref.child("Rooms").child(roomCode).child("Users").update({userName:"True"});
                      }
                      _makeAdmin(user);
                    },
                    child: Text('Make Admin'),
                  ):null,
                ),
            ],
          ),
        ),
      body: Column(
        children: [
          if(currentSong!=null && (userName==admin || userName==superAdmin))PlayerWidget(player: player,currentSong:currentSong, onNext: onNextSong , onPrevious: onPreviousSong, customSeek: customSeek,customPause: customPause,customPlay: customPlay,),
          if(currentSong!=null && (userName!=admin && userName!=superAdmin))PlayerWidget(player: player,currentSong:currentSong),
          if(tracks.isNotEmpty)Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                return SongItem(
                  song:tracks[index],
                  update: updateCurrentSong,
                  addToPlaylist: (userName==admin || userName==superAdmin)? addToPlaylist : null,
                );
              },
            ),
          ),
          if(tracks.isEmpty && isTyping==false)Text("PlayList"),
          if(tracks.isEmpty && isTyping==false)Expanded(
            child: ListView.builder(
              itemCount: playlist.length,
              itemBuilder: (context, index) {
                return SongItem(
                  song:playlist[index],
                  update: (userName==admin || userName==superAdmin)?  updateCurrentSong  : null,
                  removeFromPlaylist: (userName==admin || userName==superAdmin)? removeFromPlaylist : null,
                );
              },
            ),
          ),
        ]
      )
    ));
  }
}

