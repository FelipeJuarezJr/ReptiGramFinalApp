import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TitleHeader extends StatelessWidget {
  const TitleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          const Expanded(
            child: Center(
              child: Text(
                'ReptiGram',
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: AppColors.titleText,
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 