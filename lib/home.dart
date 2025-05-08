import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // User info
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isUpdatingProfile = false;
  late TabController _tabController;
  File? _imageFile;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  
  // Keys for form validation
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _urlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      try {
        setState(() => isLoading = true);
        
        // Get user data from Firestore
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        // Check if widget is still mounted before updating state
        if (!mounted) return;
        
        if (doc.exists) {
          setState(() {
            userData = doc.data() as Map<String, dynamic>?;
            _nameController.text = userData?['name'] ?? '';
            _emailController.text = userData?['email'] ?? '';
            isLoading = false;
          });
        } else {
          // Create user document if it doesn't exist
          // Make sure to use Google profile photo if user signed in with Google
          String photoURL = currentUser!.photoURL ?? '';
          
          await _firestore.collection('users').doc(currentUser!.uid).set({
            'name': currentUser!.displayName ?? 'User',
            'email': currentUser!.email ?? '',
            'imgUrl': photoURL,
            'id': currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          // Reload data
          _loadUserData();
        }
      } catch (e) {
        // Check if widget is still mounted before updating state
        if (!mounted) return;
        
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 400, // Smaller dimensions to avoid large base64 strings
        maxHeight: 400,
        imageQuality: 70, // Lower quality to reduce size
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          isUpdatingProfile = true;
        });
        
        // Convert image to base64
        final bytes = await _imageFile!.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Check if base64 string isn't too large for Firestore
        if (base64Image.length > 900000) { // ~900KB limit to be safe
          setState(() {
            isUpdatingProfile = false;
            _imageFile = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is too large. Please choose a smaller image or use an image URL instead.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // Update Firestore with the base64 image
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'imgBase64': base64Image,
          'imgUrl': '', // Clear any previous URL
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        // Refresh user data
        await _loadUserData();
        
        setState(() {
          isUpdatingProfile = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUpdatingProfile = false;
        _imageFile = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    try {
      // Show loading indicator
      setState(() => isUpdatingProfile = true);

      // Update Firestore document with timestamp
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'name': _nameController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Check if widget is still mounted before continuing
      if (!mounted) return;

      setState(() => isUpdatingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh user data
      _loadUserData();
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() => isUpdatingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    try {
      // Show loading indicator
      setState(() => isUpdatingProfile = true);

      // First, re-authenticate the user with their current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: _currentPasswordController.text,
      );

      await currentUser!.reauthenticateWithCredential(credential);

      // Then change the password
      await currentUser!.updatePassword(_newPasswordController.text);

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      // Clear the password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() => isUpdatingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() => isUpdatingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change password: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfileImageUrl() async {
    if (_urlController.text.isEmpty) return;
    
    try {
      setState(() => isUpdatingProfile = true);
      
      // Update Firestore with the image URL
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'imgUrl': _urlController.text.trim(),
        'imgBase64': null, // Clear any previous base64 image
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Refresh user data
      await _loadUserData();
      
      if (!mounted) return;
      setState(() => isUpdatingProfile = false);
      
      // Clear the URL field
      _urlController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image URL updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isUpdatingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageUrlDialog() {
    _urlController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the URL of your profile image:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                hintText: 'https://example.com/image.jpg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_urlController.text.isNotEmpty) {
                Navigator.pop(context);
                _updateProfileImageUrl();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Profile Picture',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Camera option
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Camera',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    
                    // Gallery option
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.photo_library,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gallery',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    
                    // URL option
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showImageUrlDialog();
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.link,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'URL',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if ((userData?['imgUrl'] != null && userData!['imgUrl'].isNotEmpty) ||
                    (userData?['imgBase64'] != null && userData!['imgBase64'].isNotEmpty))
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRemovePhotoConfirmation();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove Current Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemovePhotoConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Profile Photo?'),
          content: const Text('Are you sure you want to remove your profile photo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _removeProfilePhoto();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeProfilePhoto() async {
    try {
      setState(() => isUpdatingProfile = true);
      
      // Update Firestore to remove the image URL and base64
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'imgUrl': '',
        'imgBase64': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Refresh user data
      await _loadUserData();
      
      if (!mounted) return;
      setState(() => isUpdatingProfile = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image removed'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isUpdatingProfile = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove profile image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Use named route for navigation after logout
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  // Get profile image - checks for base64 image first, then URL
  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (userData?['imgBase64'] != null && userData!['imgBase64'].isNotEmpty) {
      return MemoryImage(base64Decode(userData!['imgBase64']));
    } else if (userData?['imgUrl'] != null && userData!['imgUrl'].isNotEmpty) {
      return CachedNetworkImageProvider(userData!['imgUrl']);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Profile image in app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Show profile section when image is tapped
                _showProfileBottomSheet();
              },
              child: Stack(
                children: [
                  Hero(
                    tag: 'profileImage',
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _getProfileImage(),
                      child: _getProfileImage() == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                  ),
                  if (isUpdatingProfile)
                    const Positioned.fill(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logOut();
              } else if (value == 'profile') {
                _showProfileBottomSheet();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadUserData,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getProfileImage(),
                            child: _getProfileImage() == null
                                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${userData?['name'] ?? 'User'}!',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userData?['email'] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (userData?['lastUpdated'] != null)
                                  Text(
                                    'Last updated: ${_formatTimestamp(userData!['lastUpdated'])}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Dashboard content would go here
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dashboard_customize,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your dashboard content would appear here',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.person),
                            label: const Text('Edit Profile'),
                            onPressed: () => _showProfileBottomSheet(),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
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

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Tab bar for profile sections
            Container(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.person),
                    text: 'Profile',
                  ),
                  Tab(
                    icon: Icon(Icons.lock),
                    text: 'Password',
                  ),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Profile tab
                  SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildProfileEditSection(),
                    ),
                  ),
                  
                  // Password tab
                  SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildPasswordSection(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEditSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Profile picture with edit option
              Center(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'profilePic',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _getProfileImage(),
                        child: _getProfileImage() == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _showImagePickerOptions,
                        ),
                      ),
                    ),
                    if (isUpdatingProfile)
                      const Positioned.fill(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Email field (read-only)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  helperText: 'Email cannot be modified',
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 30),
              // User ID display (read-only)
              if (currentUser != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'User ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              currentUser!.uid,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUpdatingProfile ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isUpdatingProfile
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Updating...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Text('Update Profile', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Current password
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // New password
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Password must be at least 6 characters',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Confirm password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUpdatingProfile ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isUpdatingProfile
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Text('Change Password', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}