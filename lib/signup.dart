// ignore_for_file: use_build_context_synchronously

import 'package:authenticationapp/home.dart';
import 'package:authenticationapp/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:authenticationapp/service/database.dart';
import 'package:authenticationapp/service/auth.dart';
import 'package:authenticationapp/theme/app_theme.dart'; // Import the theme file

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String name = "", email = "", password = "";
  bool isLoading = false;
  bool isPasswordVisible = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  userSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        name = nameController.text.trim();
        email = emailController.text.trim();
        password = passwordController.text;
      });

      try {
        // Create user with Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Store additional user info in database
        await DatabaseMethods().addUser(userCredential.user!.uid, {
          "email": email,
          "id": userCredential.user!.uid,
          "imgUrl": "https://lh3.googleusercontent.com/a/ACg8ocKFNOurMadbARiK365p1MYXFLlL0J47Y3xeGstTP83T82NTDw=s96-c",
          "name": name,
        });

        setState(() {
          isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Registration successful", 
              style: TextStyle(fontSize: 16)
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );

        // Navigate to home screen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const Home())
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          isLoading = false;
        });
        
        // Handle specific Firebase Auth errors
        String errorMessage = "Registration failed. Please try again.";
        
        if (e.code == 'weak-password') {
          errorMessage = "Password is too weak. Please use a stronger password.";
        } else if (e.code == "email-already-in-use") {
          errorMessage = "An account already exists with this email.";
        } else if (e.code == "invalid-email") {
          errorMessage = "Please provide a valid email address.";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        
        // Handle general errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}", style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );
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
              AppTheme.primaryRed.withAlpha(204), // 0.8 opacity converted to alpha
              AppTheme.primaryYellow.withAlpha(230), // 0.9 opacity converted to alpha
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header image
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Container(
                    height: size.height * 0.25,
                    width: size.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25), // Fixed: replaced withOpacity with withAlpha
                      borderRadius: BorderRadius.circular(20),
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
                
                // Header text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 4.0,
                          color: Colors.black.withAlpha(77), // Fixed: replaced withOpacity with withAlpha
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Signup form
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name field
                        TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            } else if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Full Name",
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFedf0f8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        ),
                        
                        const SizedBox(height: 20.0),
                        
                        // Email field
                        TextFormField(
                          controller: emailController,
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
                        
                        const SizedBox(height: 20.0),
                        
                        // Password field
                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            } else if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
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
                        ),
                        
                        const SizedBox(height: 30.0),
                        
                        // Sign up button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : userSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.buttonColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w600,
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
                          "Or sign up with",
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
                
                // Social signup
                GestureDetector(
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
                  child: Container(
                    width: size.width * 0.8,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
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
                
                const SizedBox(height: 32.0),
                
                // Login prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LogIn()),
                        );
                      },
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          color: isDarkMode ? const Color.fromARGB(255, 0, 187, 255) : const Color.fromARGB(255, 0, 187, 255),
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
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
    );
  }
}