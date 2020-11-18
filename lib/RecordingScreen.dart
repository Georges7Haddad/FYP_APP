import 'dart:async';
import 'dart:io' as io;

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:fyp_app/TracksScreen.dart';
import 'package:path_provider/path_provider.dart';

import 'SettingsScreen.dart';

final assetsAudioPlayer = AssetsAudioPlayer();

class RecordingScreen extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  RecordingScreen({localFileSystem})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();

  @override
  State<StatefulWidget> createState() => new RecordingScreenState();
}

class RecordingScreenState extends State<RecordingScreen> {
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  @override
  void initState() {
    super.initState();
    _init();
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
        body: new Center(
          child: new Padding(
            padding: new EdgeInsets.all(8.0),
            child: new Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new FlatButton(
                          onPressed: () {
                            switch (_currentStatus) {
                              case RecordingStatus.Initialized:
                                {
                                  _start();
                                  break;
                                }
                              case RecordingStatus.Recording:
                                {
                                  _pause();
                                  break;
                                }
                              case RecordingStatus.Paused:
                                {
                                  _resume();
                                  break;
                                }
                              case RecordingStatus.Stopped:
                                {
                                  _init();
                                  break;
                                }
                              default:
                                break;
                            }
                          },
                          child: _buildText(_currentStatus),
                          color: Colors.lightBlue,
                        ),
                      ),
                      new FlatButton(
                        onPressed: _currentStatus != RecordingStatus.Unset
                            ? _stop
                            : null,
                        child: new Text("Stop",
                            style: TextStyle(color: Colors.white)),
                        color: Colors.blueAccent.withOpacity(0.5),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      assetsAudioPlayer.builderIsPlaying(
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
                      ),
                      RaisedButton(
                          child: Text("Submit"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TracksScreen(audioPath: _current.path)),
                            );
                            setState(() {});
                          }),
                    ],
                  ),
                  new Text(
                    "Status : $_currentStatus",
                    style: TextStyle(fontSize: 15, color: Colors.green),
                  ),
                  new Text(
                      "Audio recording duration : ${_current?.duration.toString()}",
                      style: TextStyle(fontSize: 15, color: Colors.green))
                ]),
          ),
        ));
  }

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/audit_recording_';
        io.Directory appDocDirectory;
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        var current = await _recorder.current(channel: 0);
        setState(() {
          _current = current;
          _currentStatus = current.status;
        });
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        setState(() {
          _current = current;
          _currentStatus = _current.status;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  _pause() async {
    await _recorder.pause();
    setState(() {});
  }

  _resume() async {
    await _recorder.resume();
    setState(() {});
  }

  _stop() async {
    var result = await _recorder.stop();
    File file = widget.localFileSystem.file(result.path);
    setState(() {
      _current = result;
      _currentStatus = _current.status;
      initializeAudio();
    });
  }

  Widget _buildText(RecordingStatus status) {
    var text = "";
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          text = 'Start';
          break;
        }
      case RecordingStatus.Recording:
        {
          text = 'Pause';
          break;
        }
      case RecordingStatus.Paused:
        {
          text = 'Resume';
          break;
        }
      case RecordingStatus.Stopped:
        {
          text = 'Init';
          break;
        }
      default:
        break;
    }
    return Text(text, style: TextStyle(color: Colors.white));
  }

// todo: I cant listen back to the audio more than once(audioPath is always correct)
// todo: when I need to record again, it saves the file but doesn't play it back (i think first issue solves this one too)
// todo: If we click on back music should stop
// todo: Add audio format specification in settings
  void initializeAudio() async {
    var audioPath = _current.path;
    final audio = Audio.file(audioPath);

    audio.updateMetas(
        title: "New Audio Recording",
        artist: "Recorder",
        image: MetasImage.network(
            "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/55f3c884-c0b1-4c93-8c44-6672fc24d25e/d1cws6j-9d889956-85ac-4064-9770-a0ec0c628905.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNTVmM2M4ODQtYzBiMS00YzkzLThjNDQtNjY3MmZjMjRkMjVlXC9kMWN3czZqLTlkODg5OTU2LTg1YWMtNDA2NC05NzcwLWEwZWMwYzYyODkwNS5qcGcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.nhqcdtd0PXLT1frWkwtA5HAjUD6OB-2NoZnq7NaEasM"));

    assetsAudioPlayer.open(audio,
        showNotification: true,
        notificationSettings: NotificationSettings(
          nextEnabled: false,
        ));
    assetsAudioPlayer.pause();
  }
}
