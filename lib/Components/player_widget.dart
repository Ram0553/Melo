import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:musicly/Objects/SongObject.dart';

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;
  final Song? currentSong;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final Function(int)? customSeek;
  final Function()? customPlay;
  final Function()? customPause;


  const PlayerWidget({
    required this.player,
    required this.currentSong,
    this.onNext,
    this.onPrevious,
    this.customSeek,
    this.customPlay,
    this.customPause,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;

  String get _positionText {
    final position = _position ?? Duration.zero;
    final hours = position.inHours.remainder(60).toString().padLeft(2, '0');
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${hours == "00" ? '' : '$hours:'}$minutes:$seconds';
  }

  String get _durationText {
    final duration = _duration ?? Duration.zero;
    final hours = duration.inHours.remainder(60).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${hours == "00" ? '' : '$hours:'}$minutes:$seconds';
  }

  AudioPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();
    _playerState = player.state;
    player.getDuration().then((value) => setState(() {
          _duration = value;
        }));
    player.getCurrentPosition().then((value) => setState(() {
          _position = value;
        }));
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    final song = widget.currentSong;

    return Center(
      child: Card(
        elevation: 4.0, // Add a shadow effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0), // Rounded edges
        ),
        margin: EdgeInsets.all(16.0), // Margin around the card
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 10.0), // Padding inside the card
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (song != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                  child: Row(
                    children: [
                      // Left side: Song Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0), // Rounded image corners
                        child: Image.network(
                          song.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 5,),
                      // Right side: Song info and control buttons
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                                child: Text(
                              song.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                            Center(
                              child: Text(
                                song.artist,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Previous Button
                                IconButton(
                                  key: const Key('previous_button'),
                                  onPressed: widget.onPrevious,
                                  iconSize: 30.0,
                                  icon: const Icon(Icons.skip_previous),
                                  color: color,
                                ),
                                // Play/Pause Button
                                IconButton(
                                  key: const Key('play_pause_button'),
                                  onPressed: _isPlaying ? (widget.customPause??_pause) : (widget.customPlay??_play), // Toggle play/pause
                                  iconSize: 36.0,
                                  icon: Icon(
                                      _isPlaying ? Icons.pause : Icons.play_arrow),
                                  color: color,
                                ),
                                // Next Button
                                IconButton(
                                  key: const Key('next_button'),
                                  onPressed: widget.onNext,
                                  iconSize: 30.0,
                                  icon: const Icon(Icons.skip_next),
                                  color: color,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Customized seekbar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0), // Smaller thumb
                  trackHeight: 2.0, // Slimmer track
                ),
                child: Slider(
                  onChanged: (value) {
                    final duration = _duration;
                    if (duration == null) {
                      return;
                    }
                    final position = value * duration.inMilliseconds;
                    widget.customSeek==null?player.seek(Duration(milliseconds: position.round())):widget.customSeek!(position.round());
                  },
                  value: (_position != null &&
                          _duration != null &&
                          _position!.inMilliseconds > 0 &&
                          _position!.inMilliseconds < _duration!.inMilliseconds)
                      ? _position!.inMilliseconds / _duration!.inMilliseconds
                      : 0.0,
                ),
              ),
              // Row for current position and total duration
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _position != null ? _positionText : '0:00',
                      style: TextStyle(fontSize: 14.0),
                    ),
                    Text(
                      _duration != null ? _durationText : '0:00',
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription = player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> _play() async {
    if (player.source == null) return;
    await player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _pause() async {
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }
}
