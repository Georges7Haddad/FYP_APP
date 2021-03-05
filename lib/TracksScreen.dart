import 'dart:io' as io;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'SettingsScreen.dart';
import 'package:http/http.dart' as http;

final originalTrackPlayer = AssetsAudioPlayer.newPlayer();
final vocalsTrackPlayer = AssetsAudioPlayer.newPlayer();
final drumsTrackPlayer = AssetsAudioPlayer.newPlayer();

Future<http.Response> splitAudio(String audioPath) async {
  // Set URI
  var uri;
  if (io.Platform.isIOS) {
    uri = Uri.parse('http://127.0.0.1:8000/api/split/');
  } else {
    uri = Uri.parse('http://10.0.2.2:8000/api/split/');
  }

  // Original Track File Bytes
  var originalFileBytes = io.File(audioPath).readAsBytesSync();

  // Set File Path
  io.Directory appDocDirectory = await getTemporaryDirectory();
  // Vocals File
  var vocalsFilePath = appDocDirectory.path + "/vocals.mp3";
  var vocalsFile = io.File(vocalsFilePath);
  // Drums File
  var drumsFilePath = appDocDirectory.path + "/drums.mp3";
  var drumsFile = io.File(drumsFilePath);

  // Post Original Track + Get Vocals Track
  var request = http.MultipartRequest('POST', uri)
    ..files.add(http.MultipartFile.fromBytes("file", originalFileBytes,
        filename: "file", contentType: MediaType('audio', 'mpeg')));
  var streamResponse = await request.send();
  var vocalsResponse = await http.Response.fromStream(streamResponse);

  // Get Drums Track
  var drumsResponse = await http.get(uri);

  // Write response files
  vocalsFile.writeAsBytesSync(vocalsResponse.bodyBytes);
  drumsFile.writeAsBytesSync(drumsResponse.bodyBytes);

  // Setting audio player
  if (streamResponse.statusCode == 201 && drumsResponse.statusCode == 200) {
    try {
      vocalsTrackPlayer.open(Audio.file(vocalsFilePath),
          autoStart: false,
          headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplug,
          showNotification: true,
          notificationSettings: NotificationSettings(
            nextEnabled: false,
          ));
    } catch (t) {
      print(t.toString());
    }
    try {
      drumsTrackPlayer.open(Audio.file(drumsFilePath),
          autoStart: false,
          headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplug,
          showNotification: true,
          notificationSettings: NotificationSettings(
            nextEnabled: false,
          ));
    } catch (t) {
      print(t.toString());
    }
  } else {
    throw Exception('Failed to split Track');
  }
}

void initializeOriginalTrack(audioPath) async {
  final audio = Audio.file(audioPath);
  var directories = audioPath.split('/');
  audioPath = directories[directories.length - 1];
  audioPath =
      audioPath.replaceRange(audioPath.length - 4, audioPath.length, "");
  var songDetails = audioPath.split('-');
  if (songDetails.length == 1) {
    songDetails.add(songDetails[0]);
    songDetails[0] = "";
  }
  audio.updateMetas(
      title: songDetails[1],
      artist: songDetails[0],
      image: MetasImage.network(
          "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/55f3c884-c0b1-4c93-8c44-6672fc24d25e/d1cws6j-9d889956-85ac-4064-9770-a0ec0c628905.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNTVmM2M4ODQtYzBiMS00YzkzLThjNDQtNjY3MmZjMjRkMjVlXC9kMWN3czZqLTlkODg5OTU2LTg1YWMtNDA2NC05NzcwLWEwZWMwYzYyODkwNS5qcGcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.nhqcdtd0PXLT1frWkwtA5HAjUD6OB-2NoZnq7NaEasM"));

  originalTrackPlayer.open(audio,
      autoStart: false,
      headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplug,
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
    super.initState();
    initializeOriginalTrack(widget.audioPath);
    splitAudio(widget.audioPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audit'),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            originalTrackPlayer.stop();
            vocalsTrackPlayer.stop();
            drumsTrackPlayer.stop();
          },
        ),
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
      body: Center(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            // Original Track Player
            originalTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(originalTrackPlayer, infos,
                  currentTimeInSeconds, "Original Track");
            }),

            // Vocals Track Player
            vocalsTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(vocalsTrackPlayer, infos,
                  currentTimeInSeconds, "  Vocals Track");
            }),
            // Drums Track Player
            drumsTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(drumsTrackPlayer, infos,
                  currentTimeInSeconds, "  Drums Track");
            }),
          ])),
    );
  }

  playerBuilder(audioPlayer, infos, currentTimeInSeconds, trackName) {
    return Column(
      children: [
        Row(children: [
          SizedBox(
            width: 20,
          ),
          Text("${infos.currentPosition.toString().split(".")[0]}"),
          SizedBox(
            width: 69,
          ),
          Text(
            trackName,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(
            width: 69,
          ),
          Text("${infos.duration.toString().split(".")[0]}"),
        ]),
        Slider.adaptive(
          value: currentTimeInSeconds.toDouble(),
          min: 0,
          max: infos.duration.inSeconds.toDouble(),
          activeColor: Colors.green[600],
          inactiveColor: Colors.grey,
          onChanged: (double value) {
            setState(() {
              audioPlayer.seek(Duration(seconds: value.toInt()));
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Icon(Icons.replay_10),
              onPressed: () {
                audioPlayer.seekBy(Duration(seconds: -10));
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                shape:
                    MaterialStateProperty.all<OutlinedBorder>(StadiumBorder()),
                minimumSize: MaterialStateProperty.all<Size>(
                  Size(50, 30),
                ),
              ),
            ),
            SizedBox(
              width: 12,
            ),
            FloatingActionButton(
                heroTag: trackName,
                backgroundColor: Colors.green,
                child: Icon(
                  infos.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                ),
                onPressed: () {
                  audioPlayer.playOrPause();
                  setState(() {});
                }),
            SizedBox(
              width: 12,
            ),
            ElevatedButton(
              child: Icon(Icons.forward_10),
              onPressed: () {
                audioPlayer.seekBy(Duration(seconds: 10));
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                shape:
                    MaterialStateProperty.all<OutlinedBorder>(StadiumBorder()),
                minimumSize: MaterialStateProperty.all<Size>(
                  Size(50, 30),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 30,
        )
      ],
    );
  }
}
