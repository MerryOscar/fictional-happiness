import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audioplayers Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AudioPlayersTest(),
    );
  }
}

class AudioPlayersTest extends StatelessWidget {
  // Audio URL for Testing
  final String audioURL = 'https://itsallwidgets.com/podcast/download/episode-40.mp3'; // Example MP3

  // Download Audio File
  Future<File> _downloadAudioFile() async {
    try {
      http.Client _client = http.Client();
      var req = await _client.get(Uri.parse(audioURL));
      var bytes = req.bodyBytes;
      String dir = (await getApplicationDocumentsDirectory()).path;
      File audioFile = new File('$dir/audio.mp3');
      await audioFile.writeAsBytes(bytes);
      return audioFile;
    } catch (error) {
      print('DOWNLOAD ERROR: $error');
      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Audioplayers Test')),
      body: Center(
        child: FutureBuilder(
          future: _downloadAudioFile(),
          builder: (context, AsyncSnapshot snapshot) {
            // Waiting
            if (snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
            // Error
            if (snapshot.hasError) return Column(children: [Text('DOWNLOAD ERROR:'), Text(snapshot.error.toString())]);
            // Done
            return PlayerWidget(audioFile: snapshot.data);
          },
        ),
      ),
    );
  }
}

class PlayerWidget extends StatefulWidget {
  final File audioFile;
  PlayerWidget({Key key, @required this.audioFile});
  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _error;

  // Play
  Future<void> _play() async {
    // Load and Play
    String url = widget.audioFile.path;
    int duration = await _player.setUrl(url, isLocal: true);
    _player.play(widget.audioFile.path, isLocal: true);

    // Set Notification
    _player.setNotification(
      title: 'Test Podcast',
      forwardSkipInterval: Duration(seconds: 30),
      backwardSkipInterval: Duration(seconds: 30),
      duration: Duration(seconds: duration),
      elapsedTime: Duration.zero,
    );

    setState(() {
      _playing = true;
      _duration = Duration(seconds: duration);
    });

    // Listen for Position
    _player.onAudioPositionChanged.listen((Duration position) {
      setState(() {
        _position = position;
      });
    });

    // Listen for Error
    _player.onPlayerError.listen((String message) {
      setState(() {
        _playing = false;
        _error = message;
      });
    });
  }

  // Pause
  Future<void> _pause() async {
    _player.pause();
    setState(() {
      _playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play / Pause
          OutlinedButton.icon(
            icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
            label: Text(_playing ? 'PAUSE' : 'PLAY'),
            onPressed: () => _playing ? _pause() : _play(),
          ),

          // Current Position
          Text('Position: $_position'),

          // Skip Forward / Back
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_30, size: 30),
                onPressed: () => _player.seek(Duration(seconds: math.max(0, _position.inSeconds - 30))),
              ),
              IconButton(
                icon: Icon(Icons.forward_30, size: 30),
                onPressed: () => _player.seek(Duration(seconds: math.max(_duration.inSeconds, _position.inSeconds + 30))),
              ),
            ],
          ),

          if (_error != null) Column(children: [Text('PLAY ERROR:'), Text(_error.toString())]),
        ],
      ),
    ));
  }
}
