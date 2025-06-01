import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import '../widgets/google_sign_in_button.dart';
import '../styles/colors.dart';
import '../screens/post_screen.dart';
import 'post_screen.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _googleSignIn = GoogleSignIn();
  final _auth = FirebaseAuth.instance;

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      final userCredential = await _googleSignIn.signIn();
      if (userCredential == null) return;

      final googleAuth = await userCredential.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        // Update database and navigate
        await _updateUserData(user);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PostScreen(shouldLoadPosts: true),
            ),
          );
        }
      }
    } catch (e) {
      print('Google sign in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in with Google: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData(User user) async {
    final userRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(user.uid);

    await userRef.update({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastLogin': ServerValue.timestamp,
    });

    // Update AppState
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.initializeUser();
  }

  Future<void> _handleLogin() async {
    try {
      setState(() => _isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // Navigate to post screen and trigger post loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PostScreen(shouldLoadPosts: true),
          ),
        );
      }
    } catch (e) {
      String message = 'An error occurred';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Center(
                child: Image.asset(
                  'assets/img/reptiGramLogo.png',
                  height: 220,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ReptiGram',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoTitleText,
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.inputGradient,
                            borderRadius: AppColors.pillShape,
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: const TextStyle(
                                color: Colors.brown,
                              ),
                            ).applyDefaults(AppColors.inputDecorationTheme),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
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
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(
                                color: Colors.brown,
                              ),
                            ).applyDefaults(AppColors.inputDecorationTheme),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
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
                                  onPressed: _handleLogin,
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
                                        'Login',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 16),
                        Center(
                          child: GoogleSignInButton(
                            onSignedIn: () {
                              // Handle post-sign-in logic, e.g. navigate to home
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Don\'t have an account? Register',
                            style: TextStyle(
                              color: AppColors.titleText,
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 