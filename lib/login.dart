// ignore_for_file: use_build_context_synchronously

import 'package:authenticationapp/forgot_password.dart';
import 'package:authenticationapp/home.dart';
import 'package:authenticationapp/service/auth.dart';
import 'package:authenticationapp/signup.dart';
import 'package:authenticationapp/theme/app_theme.dart'; // Import the theme file
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email = "", password = "";
  bool isLoading = false;
  bool isPasswordVisible = false;

  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

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
        
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const Home())
        );
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
  void dispose() {
    mailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                      color: Colors.white.withAlpha(25),
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
                        TextFormField(
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
                        
                        const SizedBox(height: 20.0),
                        
                        // Password field
                        TextFormField(
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
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: isDarkMode ? const Color.fromARGB(255, 68, 202, 255) : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24.0),
                        
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : userLogin,
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
                                    "Sign In",
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
                
                // Social login
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
                
                // Sign up prompt
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
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUp()),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Colors.white,
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