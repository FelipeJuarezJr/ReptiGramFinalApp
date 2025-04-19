import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../styles/colors.dart';
import '../common/header.dart';
import '../common/title_header.dart';
import '../models/photo_data.dart';
import '../models/comment_data.dart';
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.initializeUser();
      await _loadAllPhotos();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            // Get likes count and current user's like status
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
              likesCount: likes.length,  // Set the likes count
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
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUser = appState.currentUser;
    
    print('Current user: ${currentUser?.uid}');
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to like photos'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final photoRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(photo.userId ?? '')
          .child('photos')
          .child(photo.id)
          .child('likes')
          .child(currentUser.uid);

      print('Database path: ${photoRef.path}');

      final snapshot = await photoRef.get();
      
      if (mounted) {
        setState(() {
          if (snapshot.exists) {
            // Unlike
            photoRef.remove();
            photo.isLiked = false;
            photo.likesCount = math.max(0, photo.likesCount - 1);
          } else {
            // Like
            photoRef.set(true);
            photo.isLiked = true;
            photo.likesCount++;
          }
        });
        
        fullScreenSetState?.call(() {});
      }

    } catch (e) {
      print('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: ${e.toString()}')),
        );
      }
    }
  }

  void _showFullScreenImage(PhotoData photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenPhotoView(
          photo: photo,
          onLikeToggled: (photo, setState) => _toggleLike(photo, setState),
        ),
      ),
    );
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
        onTap: () => _showFullScreenImage(photo),
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
            // Image with like button
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
                    child: Material(
                      color: Colors.transparent,
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
                            InkWell(
                              onTap: () {
                                final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
                                if (currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please log in to like photos')),
                                  );
                                  return;
                                }
                                _toggleLike(photo, null);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  photo.isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: photo.isLiked ? Colors.red : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
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

// Create a separate StatefulWidget for the full-screen view
class FullScreenPhotoView extends StatefulWidget {
  final PhotoData photo;
  final Function(PhotoData, StateSetter) onLikeToggled;

  const FullScreenPhotoView({
    Key? key,
    required this.photo,
    required this.onLikeToggled,
  }) : super(key: key);

  @override
  _FullScreenPhotoViewState createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _postComment() async {
    final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment')),
      );
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    try {
      final newCommentRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(widget.photo.userId ?? '')
          .child('photos')
          .child(widget.photo.id)
          .child('comments')
          .push();

      await newCommentRef.set({
        'userId': currentUser.uid,
        'content': comment,
        'timestamp': ServerValue.timestamp,
      });

      _commentController.clear();
      
      // Scroll to bottom to see new comment at the end
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  '${widget.photo.likesCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                IconButton(
                  icon: Icon(
                    widget.photo.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.photo.isLiked ? Colors.red : Colors.white,
                    size: 28,
                  ),
                  onPressed: () => widget.onLikeToggled(widget.photo, setState),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: widget.photo.id,
                  child: widget.photo.firebaseUrl != null
                    ? Image.network(
                        widget.photo.firebaseUrl!,
                        fit: BoxFit.contain,
                      )
                    : const Icon(Icons.image, size: 100, color: Colors.white),
                ),
              ),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // ... Photo info section ...
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance
                        .ref()
                        .child('users')
                        .child(widget.photo.userId ?? '')
                        .child('photos')
                        .child(widget.photo.id)
                        .child('comments')
                        .onValue,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading comments'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                        return const Center(
                          child: Text('No comments yet'),
                        );
                      }

                      final commentsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      final comments = commentsMap.entries.map((entry) {
                        return CommentData.fromMap(
                          entry.key.toString(),
                          entry.value as Map<dynamic, dynamic>,
                        );
                      }).toList();

                      // Sort by timestamp ascending (oldest first)
                      comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return FutureBuilder<String?>(
                            future: Provider.of<AppState>(context, listen: false)
                                .fetchUsername(comment.userId),
                            builder: (context, usernameSnapshot) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        usernameSnapshot.data ?? 'Loading...',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimestamp(comment.timestamp),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                // Comment input
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _postComment(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _postComment,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 