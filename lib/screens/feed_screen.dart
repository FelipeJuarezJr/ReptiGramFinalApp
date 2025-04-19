import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../styles/colors.dart';
import '../common/header.dart';
import '../common/title_header.dart';
import '../models/photo_data.dart';
import '../state/app_state.dart';
import 'dart:math' as math;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<PhotoData> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllPhotos();
  }

  Future<void> _loadAllPhotos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final usersSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .get();

      if (!usersSnapshot.exists) return;

      final List<PhotoData> allPhotos = [];
      final usersData = usersSnapshot.value as Map<dynamic, dynamic>;
      final currentUser = Provider.of<AppState>(context, listen: false).currentUser;

      for (var entry in usersData.entries) {
        final userId = entry.key as String;
        final userData = entry.value as Map<dynamic, dynamic>;
        
        if (userData['photos'] != null) {
          final photos = userData['photos'] as Map<dynamic, dynamic>;
          photos.forEach((photoId, photoData) {
            // Get likes count
            final likes = (photoData['likes'] as Map<dynamic, dynamic>?) ?? {};
            final isLiked = currentUser != null && likes[currentUser.uid] == true;

            final photo = PhotoData(
              id: photoId.toString(),
              file: null,
              firebaseUrl: photoData['firebaseUrl'],
              title: photoData['title'] ?? 'Untitled',
              comment: photoData['comment'] ?? '',
              isLiked: isLiked,
              userId: userId,
              timestamp: photoData['timestamp'],
              likesCount: likes.length,
            );
            allPhotos.add(photo);
          });
        }
      }

      // Sort by timestamp
      allPhotos.sort((a, b) => b.timestamp?.compareTo(a.timestamp ?? 0) ?? 0);

      if (mounted) {
        setState(() {
          _photos = allPhotos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLike(PhotoData photo, StateSetter? fullScreenSetState) async {
    final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
    if (currentUser == null) return;

    try {
      final photoRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(photo.userId ?? '')
          .child('photos')
          .child(photo.id);

      final likesRef = photoRef.child('likes');
      final userLikeRef = likesRef.child(currentUser.uid);

      final snapshot = await userLikeRef.get();
      if (snapshot.exists) {
        // Unlike
        await userLikeRef.remove();
        setState(() {
          photo.isLiked = false;
          photo.likesCount = math.max(0, photo.likesCount - 1);
        });
        fullScreenSetState?.call(() {}); // Update full-screen view if open
      } else {
        // Like
        await userLikeRef.set(true);
        setState(() {
          photo.isLiked = true;
          photo.likesCount++;
        });
        fullScreenSetState?.call(() {}); // Update full-screen view if open
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: ${e.toString()}')),
      );
    }
  }

  Widget _buildGridItem(PhotoData photo) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: Colors.white.withOpacity(0.9),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => StatefulBuilder(
                builder: (context, fullScreenSetState) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      // Like button with count
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Row(
                          children: [
                            Text(
                              '${photo.likesCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                photo.isLiked ? Icons.favorite : Icons.favorite_border,
                                color: photo.isLiked ? Colors.red : Colors.white,
                                size: 28,
                              ),
                              onPressed: () => _toggleLike(photo, fullScreenSetState),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Hero(
                              tag: photo.id,
                              child: InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: photo.firebaseUrl != null
                                  ? Image.network(
                                      photo.firebaseUrl!,
                                      fit: BoxFit.contain,
                                    )
                                  : const Icon(Icons.image, size: 100, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.7),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String?>(
                                future: appState.fetchUsername(photo.userId ?? ''),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? 'Loading...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              if (photo.title.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    photo.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (photo.comment.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    photo.comment,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username at the top
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: FutureBuilder<String?>(
                future: appState.fetchUsername(photo.userId ?? ''),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Loading...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo.firebaseUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        photo.firebaseUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.image),
                    ),
                  // Like button overlay
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${photo.likesCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _toggleLike(photo, null),
                            child: Icon(
                              photo.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: photo.isLiked ? Colors.red : Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Comment preview at the bottom
            if (photo.comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  photo.comment,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const TitleHeader(),
              const Header(initialIndex: 2),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _photos.isEmpty
                        ? const Center(
                            child: Text(
                              'No photos available',
                              style: TextStyle(
                                color: AppColors.titleText,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAllPhotos,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(8.0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                                childAspectRatio: 0.8, // Slightly taller for username and comment
                              ),
                              itemCount: _photos.length,
                              itemBuilder: (context, index) => _buildGridItem(_photos[index]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 