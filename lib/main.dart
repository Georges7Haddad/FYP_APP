import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'SettingsScreen.dart';
import 'TracksScreen.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  Get.lazyPut<ThemeController>(() => ThemeController());
  runApp(AuditApp());
}

class AuditApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ThemeController.to.getThemeModeFromPreferences();
    return GetMaterialApp(
      title: 'Audit',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
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
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Text('Upload a Track', textScaleFactor: 1.2)),
            SizedBox(height: 10),
            Opacity(
                opacity: 0.7,
                child: Center(
                    child: Text(
                  'Record or import the track you wish to process',
                  textScaleFactor: 1,
                ))),
            SizedBox(height: 35),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TracksScreen()),
                  );
                }, // todo: record audio
                child: Text('Record'),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                      StadiumBorder()),
                  minimumSize: MaterialStateProperty.all<Size>(
                    Size(130, 40),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final String path = await FilePicker.getFilePath(type: FileType.audio);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TracksScreen(audioPath: path,)),
                  );
                },
                child: Text('Import Audio'),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                      StadiumBorder()),
                  minimumSize: MaterialStateProperty.all<Size>(
                    Size(130, 40),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}