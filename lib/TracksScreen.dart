import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'SettingsScreen.dart';

final assetsAudioPlayer = AssetsAudioPlayer();

void initializeAudio(audioPath) async {
  final audio = Audio.file(audioPath);
  var directories = audioPath.split('/');
  audioPath = directories[directories.length - 1];
  audioPath =
      audioPath.replaceRange(audioPath.length - 4, audioPath.length, "");
  var songDetails = audioPath.split('-');
  try {
    songDetails[1] = songDetails[1];
  } on RangeError catch (_) {
    songDetails.add(songDetails[0]);
    songDetails[0] = "";
  }
  audio.updateMetas(
      title: songDetails[1],
      artist: songDetails[0],
      // album: "Continuum",
      image: MetasImage.network(
          "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/55f3c884-c0b1-4c93-8c44-6672fc24d25e/d1cws6j-9d889956-85ac-4064-9770-a0ec0c628905.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNTVmM2M4ODQtYzBiMS00YzkzLThjNDQtNjY3MmZjMjRkMjVlXC9kMWN3czZqLTlkODg5OTU2LTg1YWMtNDA2NC05NzcwLWEwZWMwYzYyODkwNS5qcGcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.nhqcdtd0PXLT1frWkwtA5HAjUD6OB-2NoZnq7NaEasM"));

  assetsAudioPlayer.open(audio,
      showNotification: true,
      notificationSettings: NotificationSettings(
        nextEnabled: false,
      ));
}

class TracksScreen extends StatefulWidget {
  final String audioPath;

  const TracksScreen({Key key, this.audioPath}) : super(key: key);

  @override
  _TracksScreenState createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen> {
  @override
  void initState() {
    initializeAudio(widget.audioPath);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Audit'),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.settings,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            )
          ],
        ),
        body: assetsAudioPlayer.builderIsPlaying(
          builder: (context, isPlaying) {
            return RaisedButton(
                child: Text(
                  isPlaying ? "pause" : "play",
                ),
                onPressed: () {
                  assetsAudioPlayer.playOrPause();
                  setState(() {});
                });
          },
        ));
  }
}