import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../common/header.dart';
import '../screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/title_header.dart';
import '../widgets/nav_drawer.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: NavDrawer(
        userEmail: user?.email,
        userName: user?.displayName,
        userPhotoUrl: user?.photoURL,
      ),
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
                  child: Form(
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
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      // TODO: Implement post creation
                                    }
                                  },
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
              ),
            ],
          ),
        ),
      ),
    );
  }
} 