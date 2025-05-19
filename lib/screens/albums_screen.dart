import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../common/header.dart';
import '../common/title_header.dart';
import '../screens/binders_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/photo_data.dart';
import '../utils/photo_utils.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List<String> albums = ['My Album'];
  final ImagePicker _picker = ImagePicker();
  Map<String, List<PhotoData>> albumPhotos = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.initializeUser();
      _loadAlbums();
      _loadAlbumPhotos();
    });
  }

  Future<void> _loadAlbums() async {
    try {
      final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
      if (currentUser == null) return;

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('albums')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          albums = ['My Album']; // Reset to default album
          data.forEach((key, value) {
            if (value['name'] != null) {
              albums.add(value['name']);
            }
          });
        });
      }
    } catch (e) {
      print('Error loading albums: $e');
    }
  }

  Future<void> _loadAlbumPhotos() async {
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
        albumPhotos.clear();
        
        // Initialize lists for each album
        for (var album in albums) {
          albumPhotos[album] = [];
        }

        // Sort photos into albums
        data.forEach((key, value) {
          if (value['source'] == 'albums') {  // Filter locally instead of in query
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
            
            final albumName = value['albumName'] ?? 'My Album';
            if (albumPhotos.containsKey(albumName)) {
              albumPhotos[albumName]!.add(photo);
            }
          }
        });

        setState(() {});
      }
    } catch (e) {
      print('Error loading album photos: $e');
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
                            'Create Album',
                            Icons.create_new_folder,
                            () {
                              _createNewAlbum();
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
                                      'albumName': 'My Album',
                                      'userId': currentUser.uid,
                                      'source': 'albums',
                                    });

                                // Hide loading indicator
                                Navigator.pop(context);

                                // Add this line to reload photos
                                await _loadAlbumPhotos();

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
                      // Albums Grid below
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
                              itemCount: albums.length + (albumPhotos['My Album']?.length ?? 0),  // Show both albums and photos
                              itemBuilder: (context, index) {
                                // First show albums
                                if (index < albums.length) {
                                  return _buildAlbumCard(albums[index]);
                                } 
                                // Then show photos
                                else {
                                  final photoIndex = index - albums.length;
                                  final photo = albumPhotos['My Album']![photoIndex];
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

  void _createNewAlbum() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newAlbumName = '';
        return AlertDialog(
          backgroundColor: AppColors.dialogBackground,
          title: const Text(
            'Create New Album',
            style: TextStyle(color: AppColors.titleText),
          ),
          content: TextField(
            style: const TextStyle(color: AppColors.titleText),
            decoration: const InputDecoration(
              hintText: 'Enter album name',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.brown),
              ),
            ),
            onChanged: (value) {
              newAlbumName = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.brown,
              ),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                if (newAlbumName.isNotEmpty) {
                  try {
                    final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to create albums')),
                      );
                      return;
                    }

                    // Create a unique ID for the album
                    final albumId = DateTime.now().millisecondsSinceEpoch.toString();

                    // Save to Firebase
                    await FirebaseDatabase.instance
                        .ref()
                        .child('users')
                        .child(currentUser.uid)
                        .child('albums')
                        .child(albumId)
                        .set({
                          'name': newAlbumName,
                          'createdAt': ServerValue.timestamp,
                          'userId': currentUser.uid,
                        });

                    // Update local state
                    setState(() {
                      albums.add(newAlbumName);
                    });

                    Navigator.of(context).pop();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Album created successfully!')),
                    );
                  } catch (e) {
                    print('Error creating album: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create album: ${e.toString()}')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.brown,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumCard(String albumName) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BindersScreen(
              binderName: albumName,
            ),
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
              Icons.folder,
              size: 48,
              color: AppColors.titleText,
            ),
            const SizedBox(height: 8),
            Text(
              albumName,
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