import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../common/header.dart';
import '../common/title_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

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
    _loadInitialPosts();
  }

  void _loadInitialPosts() {
    // Sample initial posts
    final samplePosts = [
      PostModel(
        id: "6",
        userId: "user1",
        content: "Just tried the new ramen place downtown 🍜 The broth was absolutely incredible!",
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      PostModel(
        id: "5",
        userId: "user2",
        content: "Finally finished reading 'The Midnight Library' 📚 What a beautiful story!",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      // Add more sample posts as needed
    ];

    setState(() {
      _posts.addAll(samplePosts);
    });
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    final content = _descriptionController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final newPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        content: content,
        timestamp: DateTime.now(),
      );

      // Add to local list first (optimistic update)
      setState(() {
        _posts.insert(0, newPost);
        _descriptionController.clear();
      });

      // TODO: Add Firebase integration here when ready

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

      setState(() {
        post.isLiked = !post.isLiked;
        post.likeCount += post.isLiked ? 1 : -1;
      });

      // TODO: Update Firebase when ready
      // final postRef = FirebaseDatabase.instance
      //     .ref()
      //     .child('posts')
      //     .child(post.id);
      // await postRef.update({
      //   'isLiked': post.isLiked,
      //   'likeCount': post.likeCount,
      // });

    } catch (e) {
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

  void _addComment(PostModel post, String content) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      content: content,
      timestamp: DateTime.now(),
    );

    setState(() {
      post.comments.add(newComment);
    });

    // TODO: Add Firebase integration when ready
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