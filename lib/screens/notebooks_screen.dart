import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../common/header.dart';
import '../common/title_header.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/photo_data.dart';
import '../utils/photo_utils.dart';
import '../screens/photos_only_screen.dart';

class NotebooksScreen extends StatefulWidget {
  final String binderName;

  const NotebooksScreen({
    super.key,
    required this.binderName,
  });

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  List<String> notebooks = ['My Notebook'];
  final ImagePicker _picker = ImagePicker();
  Map<String, List<PhotoData>> notebookPhotos = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.initializeUser();
      _loadNotebookPhotos();
    });
  }

  Future<void> _loadNotebookPhotos() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
      if (currentUser == null) return;

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('photos')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        notebookPhotos.clear();

        // Initialize lists for each notebook
        for (var notebook in notebooks) {
          notebookPhotos[notebook] = [];
        }

        // Sort photos into notebooks
        data.forEach((key, value) {
          if (value['source'] == 'notebooks') {  // Filter locally
            final photo = PhotoData(
              id: key,
              file: null,
              firebaseUrl: value['url'],
              title: value['title'] ?? 'Photo Details',
              comment: value['comment'] ?? '',
              userId: currentUser.uid,
              isLiked: false,
              likesCount: 0,
            );

            final notebookName = value['notebookName'] ?? 'My Notebook';
            if (notebookPhotos.containsKey(notebookName)) {
              notebookPhotos[notebookName]!.add(photo);
            }
          }
        });

        setState(() {});
      }
    } catch (e) {
      print('Error loading notebook photos: $e');
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
              const Header(initialIndex: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60.0),
                      // Action Buttons at the top
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            'Create Notebook',
                            Icons.create_new_folder,
                            () {
                              _createNewNotebook();
                            },
                          ),
                          _buildActionButton(
                            'Add Image',
                            Icons.add_photo_alternate,
                            () async {
                              final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
                              print('Debug - Current User: ${currentUser?.uid}');

                              if (currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please log in to upload photos')),
                                );
                                return;
                              }

                              try {
                                final XFile? pickedFile = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                );

                                if (pickedFile == null) return;

                                // Show loading indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );

                                final String photoId = DateTime.now().millisecondsSinceEpoch.toString();
                                final storageRef = FirebaseStorage.instance
                                    .ref()
                                    .child('photos')
                                    .child(photoId);

                                print('Uploading to path: photos/$photoId');

                                if (kIsWeb) {
                                  final bytes = await pickedFile.readAsBytes();
                                  await storageRef.putData(
                                    bytes,
                                    SettableMetadata(contentType: 'image/jpeg'),
                                  );
                                } else {
                                  await storageRef.putFile(
                                    File(pickedFile.path),
                                    SettableMetadata(contentType: 'image/jpeg'),
                                  );
                                }

                                final downloadUrl = await storageRef.getDownloadURL();

                                // Save to Realtime Database with user ID
                                await FirebaseDatabase.instance
                                    .ref()
                                    .child('users')
                                    .child(currentUser.uid)
                                    .child('photos')
                                    .child(photoId)
                                    .set({
                                      'url': downloadUrl,
                                      'timestamp': ServerValue.timestamp,
                                      'notebookName': 'My Notebook',
                                      'userId': currentUser.uid,
                                      'source': 'notebooks',
                                    });

                                // Hide loading indicator
                                Navigator.pop(context);

                                // Add this line to reload photos
                                await _loadNotebookPhotos();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Photo uploaded successfully!')),
                                );
                              } catch (e) {
                                print('Error uploading photo: $e');
                                Navigator.pop(context); // Hide loading indicator
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to upload photo: ${e.toString()}')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 74),
                      // Notebooks Grid below
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,  // 3 items per row
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.75,  // Make items slightly taller than wide
                                ),
                                itemCount: notebooks.length + (notebookPhotos['My Notebook']?.length ?? 0),  // Show both notebooks and photos
                                itemBuilder: (context, index) {
                                  // First show notebooks
                                  if (index < notebooks.length) {
                                    return _buildNotebookCard(notebooks[index]);
                                  }
                                  // Then show photos
                                  else {
                                    final photoIndex = index - notebooks.length;
                                    final photo = notebookPhotos['My Notebook']![photoIndex];
                                    return _buildPhotoCard(photo);
                                  }
                                },
                              ),
                      ),
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

  void _createNewNotebook() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newNotebookName = '';
        return AlertDialog(
          backgroundColor: AppColors.dialogBackground,
          title: const Text(
            'Create New Notebook',
            style: TextStyle(color: AppColors.titleText),
          ),
          content: TextField(
            style: const TextStyle(color: AppColors.titleText),
            decoration: const InputDecoration(
              hintText: 'Enter notebook name',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onChanged: (value) {
              newNotebookName = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                if (newNotebookName.isNotEmpty) {
                  setState(() {
                    notebooks.add(newNotebookName);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotebookCard(String notebookName) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotosOnlyScreen(notebookName: notebookName),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.inputGradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book,
              size: 48,
              color: AppColors.titleText,
            ),
            const SizedBox(height: 8),
            Text(
              notebookName,
              style: const TextStyle(
                color: AppColors.titleText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.loginGradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.buttonText,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.buttonText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(PhotoData photo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photo.firebaseUrl!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
