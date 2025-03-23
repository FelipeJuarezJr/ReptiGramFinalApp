import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../screens/albums_screen.dart';
import '../screens/post_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Header extends StatefulWidget {
  final int initialIndex;
  
  const Header({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late int _selectedIndex;
  final GlobalKey<FeedState> _feedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Widget _buildNavItem(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PostScreen(),
            ),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AlbumsScreen(),
            ),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const FeedScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: MediaQuery.of(context).size.width / 3,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _selectedIndex == index ? AppColors.titleText : Colors.brown,
            fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCommonNavMenu() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem('Post', 0),
            _buildNavItem('Albums', 1),
            _buildNavItem('Feed', 2),
          ],
        ),
        Container(
          width: double.infinity,
          height: 2,
          child: Stack(
            children: [
              Positioned(
                left: _selectedIndex * (MediaQuery.of(context).size.width / 3),
                width: MediaQuery.of(context).size.width / 3,
                child: Container(
                  height: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        if (_selectedIndex == 2)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.grid_on),
                  color: const Color(0xFFf6e29b),
                  onPressed: () {
                    print('Grid icon pressed');
                    _feedKey.currentState?.setFeedType(FeedType.images);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.star),
                  color: const Color(0xFFf6e29b),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  color: const Color(0xFFf6e29b),
                  onPressed: () {
                    print('Video icon pressed');
                    _feedKey.currentState?.setFeedType(FeedType.videos);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  color: const Color(0xFFf6e29b),
                  onPressed: () {
                    print('People icon pressed');
                    _feedKey.currentState?.setFeedType(FeedType.groups);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCommonNavMenu();
  }
}

// Enum for feed types
enum FeedType {
  images,
  videos,
  groups,
}

// Feed state class (you'll need to implement this)
class FeedState extends State<Feed> {
  void setFeedType(FeedType type) {
    // Implement feed type switching logic
  }

  @override
  Widget build(BuildContext context) {
    // Implement feed widget
    return Container();
  }
}

class Feed extends StatefulWidget {
  const Feed({super.key});

  @override
  State<Feed> createState() => FeedState();
} 