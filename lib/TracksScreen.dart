import 'dart:convert';
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
final pianoTrackPlayer = AssetsAudioPlayer.newPlayer();
final bassTrackPlayer = AssetsAudioPlayer.newPlayer();
final otherTrackPlayer = AssetsAudioPlayer.newPlayer();
var uri;
var rand;
Future myFuture;
var playerMap = {
  "vocals": vocalsTrackPlayer,
  "drums": drumsTrackPlayer,
  "piano": pianoTrackPlayer,
  "bass": bassTrackPlayer,
  "other": otherTrackPlayer,
};

openTrackInPlayer(trackPlayer, filePath) {
  try {
    trackPlayer.open(Audio.file(filePath),
        autoStart: false,
        headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplug,
        showNotification: true,
        notificationSettings: NotificationSettings(
          nextEnabled: false,
        ));
  } catch (t) {
    print(t.toString());
  }
}

setUri() {
  if (io.Platform.isIOS) {
    uri = 'http://127.0.0.1:8000/api/';
  } else {
    uri = 'http://10.0.2.2:8000/api/';
  }
}

Future<http.Response> sendOriginalTrack(String audioPath) async {
  // Original Track File Bytes
  var originalFileBytes = io.File(audioPath).readAsBytesSync();

  // Post Original Track + Get Vocals Track
  var request = http.MultipartRequest('POST', Uri.parse(uri + 'split/'))
    ..files.add(http.MultipartFile.fromBytes("file", originalFileBytes,
        filename: "file", contentType: MediaType('audio', 'mpeg')));
  var streamResponse = await request.send();
  final bodyStr = await streamResponse.stream.bytesToString();
  var valueMap = json.decode(bodyStr);
  rand = valueMap["rand"];
}

Future<http.Response> getTrack(instrument) async {
  // Set File Path
  io.Directory appDocDirectory = await getTemporaryDirectory();
  // Initialize Files
  var filePath = appDocDirectory.path + "/$instrument.wav";
  var file = io.File(filePath);

  // Get Tracks
  var response = await http.get(Uri.parse(uri + '$instrument/$rand/'));

  // Write response files
  file.writeAsBytesSync(response.bodyBytes);

  // Setting audio players
  openTrackInPlayer(playerMap[instrument], filePath);
  if (response.statusCode == 200) {
  } else {
    throw Exception('Failed to get $instrument track');
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
    setUri();
    super.initState();
    initializeOriginalTrack(widget.audioPath);
    myFuture = sendOriginalTrack(widget.audioPath);
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
              pianoTrackPlayer.stop();
              bassTrackPlayer.stop();
              otherTrackPlayer.stop();
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
        body: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
            ),
            Center(
              child: Text(
                "Original Track",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            // Original Track Player
            originalTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(
                  originalTrackPlayer, infos, currentTimeInSeconds);
            }),
            buttonsBuilder("vocals"),
            // Vocals Track Player
            vocalsTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(
                  vocalsTrackPlayer, infos, currentTimeInSeconds);
            }),
            buttonsBuilder("drums"),
            // Drums Track Player
            drumsTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(
                  drumsTrackPlayer, infos, currentTimeInSeconds);
            }),
            buttonsBuilder("piano"),
            // Piano Track Player
            pianoTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(
                  pianoTrackPlayer, infos, currentTimeInSeconds);
            }),
            buttonsBuilder("bass"),
            // Bass Track Player
            bassTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(
                  bassTrackPlayer, infos, currentTimeInSeconds);
            }),
            buttonsBuilder("other"),
            // Other Track Player
            otherTrackPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
              if (infos == null) {
                return SizedBox();
              }
              var currentTimeInSeconds = int.parse(
                  infos.currentPosition.inSeconds.toString().split(".")[0]);
              return playerBuilder(
                  otherTrackPlayer, infos, currentTimeInSeconds);
            })
          ],
        )));
  }

  buttonsBuilder(instrument) {
    return FutureBuilder(
        future: myFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    "${instrument[0].toUpperCase()}${instrument.substring(1)}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 30.0, bottom: 15.0),
                      // width: ,
                      child: ElevatedButton(
                        onPressed: () {
                          getTrack(instrument);
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Colors.blueAccent),
                        ),
                        child: Text("Audio Track"),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 20.0, bottom: 15.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Colors.green),
                        ),
                        child: Text("Midi Track"),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 20.0, bottom: 15.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Colors.blueAccent),
                        ),
                        child: Text("Music Sheet"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Center(child: CircularProgressIndicator())
              ],
            );
          }
        });
  }

  playerBuilder(audioPlayer, infos, currentTimeInSeconds) {
    return Column(
      children: [
        Row(children: [
          SizedBox(
            width: 20,
          ),
          Text("${infos.currentPosition.toString().split(".")[0]}"),
          SizedBox(
            width: 275,
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
                heroTag: infos.toString(),
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
