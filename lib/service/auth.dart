import 'package:authenticationapp/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseMethods _databaseMethods = DatabaseMethods();

  // Singleton pattern
  static final AuthMethods _instance = AuthMethods._internal();
  
  factory AuthMethods() {
    return _instance;
  }
  
  AuthMethods._internal();

  /// Get the current logged in user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // Start the Google sign-in process
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      
      if (googleSignInAccount == null) {
        // User canceled the sign-in
        throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      // Get authentication details
      final GoogleSignInAuthentication googleSignInAuthentication = 
          await googleSignInAccount.authentication;

      // Create credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      // Get user details
      final User? user = userCredential.user;
      
      if (user == null) {
        throw Exception('Failed to get user details after Google sign in');
      }

      // Get the Google profile photo URL
      final String? photoURL = googleSignInAccount.photoUrl;

      // Store user information in Firestore, including the Google profile photo
      await _storeUserData(user, googlePhotoURL: photoURL);

      // Navigate to home screen
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
      
      return user;
    } catch (e) {
      if (e is PlatformException) {
        rethrow;
      }
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  /// Sign in with Apple
  Future<User?> signInWithApple({
    required BuildContext context,
    List<Scope> scopes = const [Scope.email, Scope.fullName],
  }) async {
    try {
      // Check if Apple Sign In is available on this device
      final isAvailable = await TheAppleSignIn.isAvailable();
      if (!isAvailable) {
        throw PlatformException(
          code: 'ERROR_NOT_AVAILABLE',
          message: 'Apple Sign In is not available on this device',
        );
      }

      // Perform Apple Sign In request
      final result = await TheAppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: scopes)
      ]);

      switch (result.status) {
        case AuthorizationStatus.authorized:
          // Get Apple ID credential
          final appleIdCredential = result.credential!;
          
          // Create OAuthCredential for Firebase
          final oAuthProvider = OAuthProvider('apple.com');
          final credential = oAuthProvider.credential(
            idToken: String.fromCharCodes(appleIdCredential.identityToken!),
            accessToken: appleIdCredential.authorizationCode != null
                ? String.fromCharCodes(appleIdCredential.authorizationCode!)
                : null,
          );

          // Sign in to Firebase
          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user!;

          // Update user display name if not available
          if (user.displayName == null || user.displayName!.isEmpty) {
            final fullName = appleIdCredential.fullName;
            if (fullName != null && 
                fullName.givenName != null && 
                fullName.familyName != null) {
              final displayName = '${fullName.givenName} ${fullName.familyName}';
              await user.updateDisplayName(displayName);
            }
          }

          // Store user information in Firestore
          await _storeUserData(user);

          // Navigate to home screen
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
          
          return user;

        case AuthorizationStatus.error:
          throw PlatformException(
            code: 'ERROR_AUTHORIZATION_DENIED',
            message: result.error?.localizedDescription ?? 'Apple Sign In failed',
          );

        case AuthorizationStatus.cancelled:
          throw PlatformException(
            code: 'ERROR_ABORTED_BY_USER', 
            message: 'Sign in aborted by user',
          );
      }
    } catch (e) {
      if (e is PlatformException) {
        rethrow;
      }
      throw Exception('Apple sign in failed: ${e.toString()}');
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        
        // Update Firestore data as well
        if (displayName != null || photoURL != null) {
          final Map<String, dynamic> updateData = {};
          
          if (displayName != null) {
            updateData['name'] = displayName;
          }
          
          if (photoURL != null) {
            updateData['imgUrl'] = photoURL;
          }
          
          updateData['lastUpdated'] = FieldValue.serverTimestamp();
          await _databaseMethods.updateUser(user.uid, updateData);
        }
      } else {
        throw Exception('No user is signed in');
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Store user data in Firestore
  Future<void> _storeUserData(User user, {String? googlePhotoURL}) async {
    try {
      // Check if user document already exists
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      // If user exists and already has an imgUrl, don't overwrite it
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        
        // Only update fields that should be updated on login
        final Map<String, dynamic> updateData = {
          "email": user.email,
          "lastLogin": FieldValue.serverTimestamp(),
        };
        
        // If user doesn't have an image URL set already, use Google's
        if ((userData?['imgUrl'] == null || userData!['imgUrl'].isEmpty) && 
            (userData?['imgBase64'] == null || userData!['imgBase64'].isEmpty) && 
            (googlePhotoURL != null && googlePhotoURL.isNotEmpty)) {
          updateData["imgUrl"] = googlePhotoURL;
        }
        
        // If user name is null or empty, update it
        if (userData?['name'] == null || userData!['name'].isEmpty) {
          updateData["name"] = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        }
        
        await _databaseMethods.updateUser(user.uid, updateData);
      } else {
        // For new users, create a complete profile
        final Map<String, dynamic> userInfoMap = {
          "email": user.email,
          "name": user.displayName ?? user.email?.split('@')[0] ?? 'User',
          "imgUrl": googlePhotoURL ?? user.photoURL ?? "",
          "id": user.uid,
          "lastLogin": FieldValue.serverTimestamp(),
          "createdAt": FieldValue.serverTimestamp(),
        };
        
        await _databaseMethods.addUser(user.uid, userInfoMap);
      }
    } catch (e) {
      // Log error but don't throw - authentication still succeeded
      debugPrint('Error storing user data: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions with user-friendly messages
  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        message = 'Please provide a valid email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please use a stronger password.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many unsuccessful login attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        message = 'This sign-in method is not enabled.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      default:
        message = e.message ?? 'Authentication failed. Please try again.';
    }
    
    return Exception(message);
  }
}