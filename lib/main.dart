import 'package:authenticationapp/home.dart';
import 'package:authenticationapp/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:authenticationapp/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authentication App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      // Define named routes for navigation
      routes: {
        '/login': (context) => const LogIn(),
        '/home': (context) => const Home(),
        // Add more routes as needed
      },
      home: const AuthenticationWrapper(),
    );
  }
}

/// This wrapper widget checks if a user is already logged in
/// and directs them to the appropriate screen
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
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
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
        
        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, navigate to home
          return const Home();
        } else {
          // User is not logged in, navigate to login
          return const LogIn();
        }
      },
    );
  }
}