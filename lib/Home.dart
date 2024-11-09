// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:musicly/Components/JoinRoomPopup.dart';
import 'package:musicly/Components/SongListItem.dart';
import 'package:musicly/Components/player_widget.dart';
import 'package:musicly/Objects/SongObject.dart';
import 'package:musicly/Room.dart';
import 'package:musicly/SignIn.dart';

import 'Components/CreateRoomPopup.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var tracks = [];
  List<Song> playlist = [];

  String query = "";
  Song? currentSong;
  bool isTyping = false;
  int currentIndex = -1;

  late AudioPlayer player = AudioPlayer();

  TextEditingController roomNameController = TextEditingController();
  Map<String, String> createdRooms = {}; // For created rooms
  Map<String, String> joinedRooms = {}; // For joined rooms
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  String userName = FirebaseAuth.instance.currentUser!.displayName!;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Create the audio player.
    player = AudioPlayer();

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);

    player.onPlayerComplete.listen((event) {
      onNextSong();
    });

    // Fetch the user's created and joined rooms
    fetchCreatedRooms();
    fetchJoinedRooms();
    fetchPlaylist();
  }

  @override
  void dispose() {
    // Release all sources and dispose the player.
    player.dispose();

    super.dispose();
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

  void navigateToRoom(String roomCode) {
    player.stop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RoomPage(roomCode: roomCode)),
    );
  }

  void fetchCreatedRooms() {
    ref.child("Users").child(userName).child("Created Rooms").onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value !="") {
        Map<dynamic, dynamic> roomsMap = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          createdRooms = roomsMap.cast<String, String>(); // Cast to Map<String, String>
        });
      } else {
        setState(() {
          createdRooms = {}; // Reset if no created rooms
        });
      }
    });
  }

  void fetchJoinedRooms() {
    ref.child("Users").child(userName).child("Joined Rooms").onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value != "") {
        Map<dynamic, dynamic> roomsMap = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          joinedRooms = roomsMap.cast<String, String>(); // Cast to Map<String, String>
        });
      } else {
        setState(() {
          joinedRooms = {}; // Reset if no joined rooms
        });
      }
    });
  }

  void fetchPlaylist() {
    ref.child("Users").child(userName).child("Playlist").once().then((event) {
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

  void addToPlaylist(Song song){
    const int paddingWidth = 4;
    ref.child("Users").child(userName).child("Playlist").update({ 
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
    setState(() {
      playlist.add(song);
    });
  }

  void removeFromPlaylist(Song song){
    playlist.remove(song);
    currentIndex++;
    updatePlaylist();
    uploadPlaylist();
    setState((){});
  }

  void updateCurrentSong(Song newSong){
    currentIndex=-1;
    currentSong = newSong;
    isTyping=false;
    for(int i=0;i<playlist.length; i++){
      if(playlist[i].downloadUrl==newSong.downloadUrl){
        setState(() {
          currentIndex = i;
        });
        updatePlaylist();
        break;
      }
    }
    setState((){});
    player.play(UrlSource(newSong.downloadUrl));
  }

  void onNextSong() {
    if(currentSong==null)return;
    if(playlist.isEmpty || playlist.length==1){
      player.seek(Duration(milliseconds: 0));
      setState(() {
        currentIndex = -1;
      });
      return;
    }
    if(currentIndex<0 || currentIndex >= playlist.length-1){
      currentIndex = 0;
    }else{
      currentIndex ++;

    }
    setState(() {
      currentSong = playlist[currentIndex];
    });
    updatePlaylist();
    player.play(UrlSource(playlist[currentIndex].downloadUrl));
  }

  void onPreviousSong() {
    if(currentSong==null)return;
    if(playlist.isEmpty  || playlist.length==1){
      player.seek(Duration(milliseconds: 0));
      setState(() {
        currentIndex = -1;
      });
      return;
    }
    if(currentIndex<=0 || currentIndex > playlist.length-1){
      currentIndex = playlist.length-1;
    }else{
      currentIndex --;

    }
    setState(() {
      currentSong = playlist[currentIndex];
    });
    updatePlaylist();
    player.play(UrlSource(playlist[currentIndex].downloadUrl));
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
    playlist = updatedPlaylist;
    playlist = updatedPlaylist;
    currentIndex = 0;
    currentSong = playlist[currentIndex];
    setState(() {});
    uploadPlaylist();
  }

  void uploadPlaylist() {
    const int paddingWidth = 4;
    Map<String, Map<String, dynamic>> playlistMap = {}; // Create a map to hold the songs

    // Loop through the playlist and store each song with a padded index
    for (int i = 0; i < playlist.length; i++) {
      Song song = playlist[i];

      // Add the song details to the map
      playlistMap[i.toString().padLeft(paddingWidth, '0')] = {
        "Order": i,
        "ImageUrl": song.imageUrl,
        "Title": song.title,
        "Artist": song.artist,
        "Album": song.album,
        "DownloadUrl": song.downloadUrl,
      };
    }

    // Now set the entire playlist map at once
    ref.child("Users").child(userName).child("Playlist").set(playlistMap);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Melo'),
        bottom:PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              readOnly: !isTyping,
              controller: searchController,
              onChanged: (value) {
                query = value;
                fetchTracks(query);
              },
              onTap: (){
                setState(() {
                  isTyping=true;
                });
              },
              onSubmitted: (value){
                setState(() {
                  isTyping=false;
                });
              },
              onTapOutside: (value){
                setState(() {
                  isTyping=false;
                });
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
        ),

         leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer(); // Open the drawer
          },
        );}),
      ),
       drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 237, 219, 250),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/ic_launcher.png', // Update with your logo asset path
                        width: 100, // Set width for the logo
                        height: 100, // Set height for the logo
                        fit: BoxFit.cover, // Cover the entire area
                      ),
                    ),
                  ),
                  SizedBox(width: 16), 
                  Text(
                    userName, // Replace this with the actual username variable
                    style: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              title: Text('Created Rooms'),
              dense: true,
            ),
            // Display created rooms
            for (String roomCode in createdRooms.keys)
              ListTile(
                title: Text(createdRooms[roomCode]!),
                subtitle: Text('Room Code: $roomCode'),
                onTap: () {
                  navigateToRoom(roomCode);
                },
              ),
            Divider(),
            ListTile(
              title: Text('Joined Rooms'),
              dense: true,
            ),
            // Display joined rooms
            for (String roomCode in joinedRooms.keys)
              ListTile(
                title: Text(joinedRooms[roomCode]!),
                subtitle: Text('Room Code: $roomCode'),
                onTap: () {
                  navigateToRoom(roomCode);
                },
              ),
            Divider(),
            ListTile(
              title: Text('Logout'),
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                var signout = await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SignIn()),
                  (Route<dynamic> route) => false, // Removes all previous routes
                );
              },
            ),
          ],
        ),
      ),
      body:Column(
      children: [
        if(currentSong!=null && isTyping==false)PlayerWidget(player: player,currentSong:currentSong, onNext: onNextSong , onPrevious: onPreviousSong),
        if(tracks.isNotEmpty)Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              return SongItem(
                song:tracks[index],
                update: updateCurrentSong,
                addToPlaylist: addToPlaylist,
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
                update: updateCurrentSong,
                removeFromPlaylist: removeFromPlaylist,
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => JoinRoomPopup(),
                  );
                },
                child: Text('Join Room'),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CreateRoomPopup(),
                  );
                },
                child: Text('Create Room'),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}
