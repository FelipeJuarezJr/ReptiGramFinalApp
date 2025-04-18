import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../common/header.dart';
import '../common/title_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class PostScreen extends StatefulWidget {
  final bool shouldLoadPosts;
  
  const PostScreen({
    super.key,
    this.shouldLoadPosts = false,
  });

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final List<PostModel> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldLoadPosts) {
      // Load posts when coming from login
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    try {
      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Reference to posts node and order by timestamp (newest first)
      final postsRef = FirebaseDatabase.instance
          .ref()
          .child('posts')
          .orderByChild('timestamp');

      final snapshot = await postsRef.get();

      setState(() {
        _posts.clear();
        if (snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            // Check if the post has likes
            Map<dynamic, dynamic> likesMap = {};
            if (value['likes'] != null) {
              likesMap = value['likes'] as Map<dynamic, dynamic>;
            }
            final isLiked = likesMap.containsKey(userId);
            final likeCount = likesMap.length;

            // Parse comments
            final List<CommentModel> comments = [];
            if (value['comments'] != null) {
              (value['comments'] as Map<dynamic, dynamic>).forEach((commentKey, commentValue) {
                comments.add(CommentModel(
                  id: commentKey,
                  userId: commentValue['userId'] ?? '',
                  content: commentValue['content'] ?? '',
                  timestamp: DateTime.fromMillisecondsSinceEpoch(
                    commentValue['timestamp'] is int 
                        ? commentValue['timestamp'] 
                        : int.parse(commentValue['timestamp'].toString())
                  ),
                ));
              });
            }

            // Create post model
            final post = PostModel(
              id: key,
              userId: value['userId'] ?? '',
              content: value['content'] ?? '',
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                value['timestamp'] is int 
                    ? value['timestamp'] 
                    : int.parse(value['timestamp'].toString())
              ),
              isLiked: isLiked,
              likeCount: likeCount,
              comments: comments,
            );
            _posts.add(post);
          });

          // Sort posts by timestamp (newest first)
          _posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      });

    } catch (e) {
      print('Error loading posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load posts: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final content = _descriptionController.text.trim();
      final postId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create post data
      final postData = {
        'userId': userId,
        'content': content,
        'timestamp': ServerValue.timestamp,
        'likes': {},
        'comments': {},
      };

      // Save to Firebase
      await FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(postId)
          .set(postData);

      _descriptionController.clear();
      await _loadPosts(); // Reload posts

    } catch (e) {
      print('Error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(PostModel post) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final postRef = FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(post.id)
          .child('likes')
          .child(userId);

      // Optimistic update
      setState(() {
        post.isLiked = !post.isLiked;
        post.likeCount += post.isLiked ? 1 : -1;
      });

      if (post.isLiked) {
        await postRef.set(true);
      } else {
        await postRef.remove();
      }

    } catch (e) {
      // Revert on error
      setState(() {
        post.isLiked = !post.isLiked;
        post.likeCount += post.isLiked ? 1 : -1;
      });
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: ${e.toString()}')),
      );
    }
  }

  void _showCommentDialog(PostModel post) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppColors.pillShape,
        ),
        title: const Text(
          'Add Comment',
          style: TextStyle(color: Colors.brown),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: AppColors.pillShape,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Show existing comments
            if (post.comments.isNotEmpty) ...[
              const Text(
                'Comments:',
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: post.comments.length,
                  itemBuilder: (context, index) {
                    final comment = post.comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        comment.content,
                        style: const TextStyle(color: Colors.brown),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.trim().isNotEmpty) {
                _addComment(post, commentController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
            ),
            child: const Text('Comment'),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(PostModel post, String content) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final commentId = DateTime.now().millisecondsSinceEpoch.toString();
      final commentData = {
        'userId': userId,
        'content': content,
        'timestamp': ServerValue.timestamp,
      };

      // Add comment to Firebase
      await FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(post.id)
          .child('comments')
          .child(commentId)
          .set(commentData);

      // Optimistic update
      final newComment = CommentModel(
        id: commentId,
        userId: userId,
        content: content,
        timestamp: DateTime.now(),
      );

      setState(() {
        post.comments.add(newComment);
      });

    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final postWidth = screenWidth - 32;

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
              const Header(initialIndex: 0),
              
              // Fixed Post Creation Form
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: postWidth,
                        decoration: BoxDecoration(
                          gradient: AppColors.inputGradient,
                          borderRadius: AppColors.pillShape,
                        ),
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'What\'s happening in the ReptiWorld?',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppColors.pillShape,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppColors.pillShape,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppColors.pillShape,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a Post';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: ElevatedButton(
                                onPressed: _createPost,
                                style: AppColors.pillButtonStyle,
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.loginGradient,
                                    borderRadius: AppColors.pillShape,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Create Post',
                                      style: TextStyle(
                                        color: AppColors.buttonText,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),

              // Scrollable Posts List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Container(
                      width: postWidth,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.inputGradient,
                        borderRadius: AppColors.pillShape,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.content,
                              style: const TextStyle(
                                color: Colors.brown,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Like button
                                IconButton(
                                  icon: Icon(
                                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: post.isLiked ? Colors.red : Colors.grey[400],
                                  ),
                                  onPressed: () => _toggleLike(post),
                                ),
                                Text(
                                  '${post.likeCount} likes',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Comment button
                                IconButton(
                                  icon: Icon(
                                    Icons.comment_outlined,
                                    color: Colors.grey[400],
                                  ),
                                  onPressed: () => _showCommentDialog(post),
                                ),
                                Text(
                                  '${post.comments.length} comments',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTimestamp(post.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            // Show latest comment if exists
                            if (post.comments.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.brown.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Latest: ${post.comments.last.content}',
                                  style: const TextStyle(
                                    color: Colors.brown,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
} 