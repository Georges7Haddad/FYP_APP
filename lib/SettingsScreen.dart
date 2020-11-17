import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  SharedPreferences prefs;
  static ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode themeMode) async {
    Get.changeThemeMode(themeMode);
    _themeMode = themeMode;
    update();
    prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', themeMode.toString().split('.')[1]);
  }

  getThemeModeFromPreferences() async {
    ThemeMode themeMode;
    prefs = await SharedPreferences.getInstance();
    String themeText = prefs.getString('theme') ?? 'system';
    try {
      themeMode =
          ThemeMode.values.firstWhere((e) => describeEnum(e) == themeText);
    } catch (e) {
      themeMode = ThemeMode.system;
    }
    setThemeMode(themeMode);
  }
}

bool dark_theme_on = ThemeController._themeMode == ThemeMode.dark ? true : false;

ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blueGrey,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark());

ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blueGrey,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light());

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(children: <Widget>[
        ListTile(
          title: Text('Dark Mode'),
          trailing: FutureBuilder(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                return Switch(
                  value: dark_theme_on,
                  onChanged: (toggle) {
                    setState(() {
                      dark_theme_on = toggle;
                      ThemeController.to.setThemeMode(
                          dark_theme_on ? ThemeMode.dark : ThemeMode.light);
                    });
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
                );
              }),
        ),
      ]),
    );
  }
}
