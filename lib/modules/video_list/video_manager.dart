import 'package:flutter/material.dart';

class VideoPlayerManager extends ChangeNotifier {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();
  factory VideoPlayerManager() => _instance;
  VideoPlayerManager._internal();

  String? _currentlyPlayingUrl;

  String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  void playVideo(String url) {
    if (_currentlyPlayingUrl != url) {
      _currentlyPlayingUrl = url;
      notifyListeners();
    }
  }

  void stopAll() {
    _currentlyPlayingUrl = null;
    notifyListeners();
  }
}