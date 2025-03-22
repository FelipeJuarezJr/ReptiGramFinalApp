import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../common/header.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              const Header(initialIndex: 0),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: Image.asset(
                            'assets/img/reptiGramLogo.png',
                            height: 120,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Create Post',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.titleText,
                            shadows: [
                              Shadow(
                                color: AppColors.titleShadow,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.inputGradient,
                            borderRadius: AppColors.pillShape,
                          ),
                          child: TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Title',
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
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.inputGradient,
                            borderRadius: AppColors.pillShape,
                          ),
                          child: TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Description',
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
                                return 'Please enter a description';
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