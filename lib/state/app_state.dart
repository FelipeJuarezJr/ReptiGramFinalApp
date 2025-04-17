import 'package:flutter/foundation.dart';
import '../models/photo_data.dart';

class AppState extends ChangeNotifier {
  List<PhotoData> _photos = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PhotoData> get photos => _photos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set photos
  void setPhotos(List<PhotoData> photos) {
    _photos = photos;
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

  // Remove photo
  void removePhoto(String photoId) {
    _photos.removeWhere((p) => p.id == photoId);
    notifyListeners();
  }

  // Set error
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 