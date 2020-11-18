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
                  new Text("${_current?.duration.toString().split(".")[0]}",
                      style: TextStyle(fontSize: 40, color: Colors.green)),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new FloatingActionButton(
                          heroTag: "B2",
                          child: _buildRecordIcon(_currentStatus),
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
                          backgroundColor: Colors.white,
                        ),
                      ),
                      new SizedBox(
                        width: 50,
                      ),
                      new FloatingActionButton(
                        heroTag: "B1",
                        child: _buildStopIcon(_currentStatus),
                        onPressed: _currentStatus != RecordingStatus.Unset
                            ? _stop
                            : null,
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                  assetsAudioPlayer.builderIsPlaying(
                    builder: (context, isPlaying) {
                      return ElevatedButton(
                        child: Text(
                          isPlaying ? "pause" : "play",
                        ),
                        onPressed: () {
                          assetsAudioPlayer.playOrPause();
                          setState(() {});
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.green),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                              StadiumBorder()),
                          minimumSize: MaterialStateProperty.all<Size>(
                            Size(130, 40),
                          ),
                        ),
                      );
                    },
                  ),
                  ElevatedButton(
                      child: Text('Process Recording'),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.green),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                            StadiumBorder()),
                        minimumSize: MaterialStateProperty.all<Size>(
                          Size(130, 40),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  TracksScreen(audioPath: _current.path)),
                        );
                        setState(() {});
                      }),
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

  // Update the record icon based on the recording status
  Widget _buildRecordIcon(RecordingStatus status) {
    var icon2 = Icons.fiber_manual_record_rounded;
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        break;
      case RecordingStatus.Recording:
        icon2 = Icons.pause;
        break;
      case RecordingStatus.Paused:
        icon2 = Icons.play_circle_fill;
        break;
      case RecordingStatus.Stopped:
        icon2 = Icons.fiber_new_outlined;
        break;
      default:
        break;
    }
    return Icon(icon2, size: 40, color: Colors.green);
  }

  // Update the stop icon color to show if recording
  Widget _buildStopIcon(RecordingStatus status) {
    if (_currentStatus == RecordingStatus.Initialized ||
        _currentStatus == RecordingStatus.Stopped ||
        _currentStatus == RecordingStatus.Paused)
      return Icon(Icons.stop_rounded, size: 35, color: Colors.blueGrey);
    return Icon(Icons.stop_rounded, size: 35, color: Colors.green);
  }

// todo: If we click on back music should stop
// todo: Add audio format specification in settings
  // Initializing audio so the user can hear their recording
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
  }
}
