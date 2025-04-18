import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/photo_data.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  Map<String, String> _usernames = {};
  List<PhotoData> _photos = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, String> get usernames => _usernames;
  List<PhotoData> get photos => _photos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set error state
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Set current user
  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Username management
  Future<void> fetchUsername(String userId) async {
    if (_usernames.containsKey(userId)) return;

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('username')
          .get();

      if (snapshot.value != null) {
        _usernames[userId] = snapshot.value.toString();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching username: $e');
      setError('Error fetching username: $e');
    }
  }

  String? getUsernameById(String userId) {
    return _usernames[userId];
  }

  // Photo management
  void setPhotos(List<PhotoData> photos) {
    _photos = photos;
    notifyListeners();
  }

  void addPhoto(PhotoData photo) {
    _photos.add(photo);
    notifyListeners();
  }

  void removePhoto(String photoId) {
    _photos.removeWhere((photo) => photo.id == photoId);
    notifyListeners();
  }

  void updatePhoto(PhotoData updatedPhoto) {
    final index = _photos.indexWhere((photo) => photo.id == updatedPhoto.id);
    if (index != -1) {
      _photos[index] = updatedPhoto;
      notifyListeners();
    }
  }

  void togglePhotoLike(String photoId) {
    final index = _photos.indexWhere((photo) => photo.id == photoId);
    if (index != -1) {
      _photos[index].isLiked = !_photos[index].isLiked;
      notifyListeners();
    }
  }

  // Clear state
  void clearState() {
    _currentUser = null;
    _usernames.clear();
    _photos.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
} 