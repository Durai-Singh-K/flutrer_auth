// ignore_for_file: use_build_context_synchronously

import 'package:authenticationapp/forgot_password.dart';
import 'package:authenticationapp/service/auth.dart';
import 'package:authenticationapp/signup.dart';
import 'package:authenticationapp/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> with SingleTickerProviderStateMixin {
  String email = "", password = "";
  bool isLoading = false;
  bool isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    mailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  userLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        email = mailController.text.trim();
        password = passwordController.text;
      });

      try {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        
        setState(() {
          isLoading = false;
        });
        
        // Navigate using named route for consistency
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        setState(() {
          isLoading = false;
        });
        
        String errorMessage = "An error occurred. Please try again.";
        
        if (e.code == 'user-not-found') {
          errorMessage = "No user found for that email";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Incorrect password";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email format";
        } else if (e.code == 'user-disabled') {
          errorMessage = "This account has been disabled";
        } else if (e.code == 'too-many-requests') {
          errorMessage = "Too many attempts. Please try again later";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            errorMessage,
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryRed,
              AppTheme.primaryRed.withAlpha(204),
              AppTheme.primaryYellow.withAlpha(230),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header image with animation
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Hero(
                      tag: 'appLogo',
                      child: Container(
                        height: size.height * 0.25,
                        width: size.width * 0.8,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "images/car.PNG",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Welcome text
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 4.0,
                            color: Colors.black.withAlpha(77),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Login form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field
                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(16),
                            child: TextFormField(
                              controller: mailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: "Email",
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFedf0f8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20.0),
                          
                          // Password field with improved visibility toggle
                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(16),
                            child: TextFormField(
                              controller: passwordController,
                              obscureText: !isPasswordVisible,
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: "Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                    child: Icon(
                                      isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      key: ValueKey<bool>(isPasswordVisible),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isPasswordVisible = !isPasswordVisible;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFedf0f8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                              ),
                              onFieldSubmitted: (_) => userLogin(),
                            ),
                          ),
                          
                          const SizedBox(height: 12.0),
                          
                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => const ForgotPassword())
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: isDarkMode ? const Color.fromARGB(255, 68, 202, 255) : Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24.0),
                          
                          // Login button with animation
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : userLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.buttonColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 3,
                                shadowColor: AppTheme.buttonColor.withOpacity(0.5),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDarkMode ? Colors.grey[700] : Colors.white.withAlpha(180),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Or continue with",
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.white,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDarkMode ? Colors.grey[700] : Colors.white.withAlpha(180),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Social login with ripple effect
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          isLoading = true;
                        });
                        
                        try {
                          await AuthMethods().signInWithGoogle(context);
                        } finally {
                          if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.grey.withOpacity(0.3),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          width: size.width * 0.8,
                          height: 54,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "images/google.png",
                                height: 24,
                                width: 24,
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                "Continue with Google",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32.0),
                  
                  // Sign up prompt with enhanced touch feedback
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUp()),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}