class PhotoData {
  final String id;
  final dynamic file;
  final String? firebaseUrl;
  String title;
  bool isLiked;
  String comment;
  final String? userId;
  final int? timestamp;

  PhotoData({
    required this.id,
    required this.file,
    this.firebaseUrl,
    this.title = 'Photo Details',
    this.isLiked = false,
    this.comment = '',
    this.userId,
    this.timestamp,
  }) : assert(id.isNotEmpty, 'Photo ID cannot be empty');
} 