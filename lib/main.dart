import 'dart:io';
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
  final String audioURL = 'https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_1MG.mp3'; // Example MP3 File on Web

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
  String _error;

  // Play
  Future<void> _play() async {
    _player.play(widget.audioFile.path, isLocal: true);
    setState(() {
      _playing = true;
    });
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
          OutlinedButton.icon(
            icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
            label: Text(_playing ? 'PAUSE' : 'PLAY'),
            onPressed: () => _playing ? _pause() : _play(),
          ),
          if (_error != null) Column(children: [Text('PLAY ERROR:'), Text(_error.toString())]),
        ],
      ),
    ));
  }
}
