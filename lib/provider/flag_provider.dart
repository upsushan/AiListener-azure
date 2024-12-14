import 'package:flutter/material.dart';

class FlagImageProvider extends ChangeNotifier {
  String _imagePath = ''; // Initial value for the image path

  String get imagePath => _imagePath;

  String setImagePath(String path) {
    _imagePath = path;
    notifyListeners();
    return _imagePath;
    // Notify listeners about the change
  }
}
