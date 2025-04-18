import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../common/header.dart';
import '../common/title_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/post_model.dart';

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
              const Header(initialIndex: 0),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Post Creation Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
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

                      // Posts List
                      const SizedBox(height: 24),
                      ..._posts.map((post) => Container(
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
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTimestamp(post.timestamp),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
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