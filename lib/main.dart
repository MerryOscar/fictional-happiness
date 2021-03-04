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
  final String audioURL = ''; // link to mp3 file stored on github in this repo

  // Download Audio File
  Future<File> _downloadAudioFile() async {
    http.Client _client = http.Client();
    var req = await _client.get(Uri.parse(audioURL));
    var bytes = req.bodyBytes;
    String dir = (await getApplicationDocumentsDirectory()).path;
    File audioFile = new File('$dir/audio.m4a');
    await audioFile.writeAsBytes(bytes);
    return audioFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Audioplayers Test')),
      body: Center(
        child: FutureBuilder(
          future: _downloadAudioFile(),
          builder: (context, AsyncSnapshot snapshot) {
            // Downloading Audio File
            if (snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
            // Downloaded Audio File
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
  AudioPlayer audioPlayer = AudioPlayer();
  bool _waiting = false;
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
      child: Column(
        children: [
          OutlinedButton.icon(
            icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
            label: Text(_playing ? 'PAUSE' : 'PLAY'),
            onPressed: _waiting
                ? null
                : () async {
                    // Pause
                    if (_playing) {
                      setState(() {
                        _waiting = true;
                      });
                      await audioPlayer.pause();
                      setState(() {
                        _waiting = false;
                        _playing = false;
                      });
                    }
                    // Play
                    else {
                      setState(() {
                        _waiting = true;
                      });
                      await audioPlayer.play(widget.audioFile.path, isLocal: true);
                      setState(() {
                        _playing = true;
                      });
                    }
                  },
          ),
          if (_waiting) CircularProgressIndicator(),
        ],
      ),
    ));
  }
}
