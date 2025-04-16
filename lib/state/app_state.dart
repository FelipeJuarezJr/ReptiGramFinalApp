import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/photo_data.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  List<PhotoData> _photos = [];
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  List<PhotoData> get photos => _photos;
  bool get isLoading => _isLoading;

  // Set current user
  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Add photo
  void addPhoto(PhotoData photo) {
    _photos.add(photo);
    notifyListeners();
  }

  // Update photo
  void updatePhoto(PhotoData photo) {
    final index = _photos.indexWhere((p) => p.id == photo.id);
    if (index != -1) {
      _photos[index] = photo;
      notifyListeners();
    }
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set all photos
  void setPhotos(List<PhotoData> photos) {
    _photos = photos;
    notifyListeners();
  }

  // Clear state on logout
  void clearState() {
    _currentUser = null;
    _photos = [];
    _isLoading = false;
    notifyListeners();
  }
} 