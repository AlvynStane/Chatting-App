import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DarkThemeProvider with ChangeNotifier {
  final ThemeData light = ThemeData(
      cardColor: Colors.white70,
      primarySwatch: Colors.green,
      brightness: Brightness.light,
      sliderTheme: const SliderThemeData(
        thumbShape: RoundSliderThumbShape(disabledThumbRadius: 0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
        disabledActiveTrackColor: Colors.green,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Colors.white70,
      ));

  final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,
    sliderTheme: const SliderThemeData(
      thumbShape: RoundSliderThumbShape(disabledThumbRadius: 0),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
      disabledActiveTrackColor: Colors.greenAccent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.greenAccent,
      unselectedItemColor: Colors.grey,
    ),
  );

  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;

  set darkMode(bool value) {
    _darkTheme = value;
    notifyListeners();
  }
}
