import 'package:flutter/material.dart';
import 'package:musicly/Objects/SongObject.dart';

class SongItem extends StatefulWidget {
  final Song song ;
  final ValueChanged<Song>? update;
  final Function(Song)? addToPlaylist;
  final Function(Song)? removeFromPlaylist;

  SongItem({
    required this.song,
    this.update,
    this.addToPlaylist,
    this.removeFromPlaylist
  });

  @override
  State<SongItem> createState() => _SongItemState();
}

class _SongItemState extends State<SongItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: Image.network(
          widget.song.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
        title: Text(
          widget.song.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.song.artist),
            Text(widget.song.album, style: TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: (widget.addToPlaylist != null || widget.removeFromPlaylist !=null)?PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'add_to_playlist') {
              widget.addToPlaylist!(widget.song);
            }
            if (value == 'remove_from__playlist') {
              widget.removeFromPlaylist!(widget.song);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            widget.addToPlaylist != null?PopupMenuItem<String>(
              value: 'add_to_playlist',
              child: Text('Add to Playlist'),
            )
            :
            PopupMenuItem<String>(
              value: 'remove_from__playlist',
              child: Text('Remove from Playlist'),
            ),
          ],
          icon: Icon(Icons.more_vert),
        ):null,
        onTap:(){
          if(widget.update != null)widget.update!(widget.song);
        }
      ),
    );
  }
}
