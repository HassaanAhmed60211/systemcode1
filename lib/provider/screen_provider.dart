import 'package:flutter/material.dart';

class ScreenProvider with ChangeNotifier {
  int _currentScreen = 0;

  int get currentScreen => _currentScreen;

  void setCurrentScreen(int index) {
    _currentScreen = index;
    notifyListeners();
  }
}
