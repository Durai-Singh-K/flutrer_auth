import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userCollection = "User";
  
  // Singleton pattern
  static final DatabaseMethods _instance = DatabaseMethods._internal();
  
  factory DatabaseMethods() {
    return _instance;
  }
  
  DatabaseMethods._internal();

  /// Add or update a user in the database
  Future<void> addUser(String userId, Map<String, dynamic> userInfoMap) async {
    try {
      // First check if user already exists
      final docSnapshot = await _firestore.collection(_userCollection).doc(userId).get();
      
      if (docSnapshot.exists) {
        // If user exists, update only new fields without overwriting existing data
        return await _firestore.collection(_userCollection).doc(userId).update({
          ...userInfoMap,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // If user doesn't exist, create new document
        return await _firestore.collection(_userCollection).doc(userId).set({
          ...userInfoMap,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add user: ${e.toString()}');
    }
  }

  /// Update specific user fields
  Future<void> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      return await _firestore.collection(_userCollection).doc(userId).update({
        ...updateData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  /// Get user data by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      DocumentSnapshot documentSnapshot = 
          await _firestore.collection(_userCollection).doc(userId).get();
      
      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  /// Get user data by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_userCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by email: ${e.toString()}');
    }
  }

  /// Delete user data
  Future<void> deleteUser(String userId) async {
    try {
      return await _firestore.collection(_userCollection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

    /// Add custom data to user document
  Future<DocumentReference<Map<String, dynamic>>> addCustomDataToUser(
    String userId,
    String collectionName,
    Map<String, dynamic> data
  ) async {
    try {
      return await _firestore
        .collection(_userCollection)
        .doc(userId)
        .collection(collectionName)
        .add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      throw Exception('Failed to add custom data: ${e.toString()}');
    }
  }

  /// Get users by query
  Future<List<Map<String, dynamic>>> queryUsers({
    required String field,
    required dynamic value,
    int limit = 10,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_userCollection)
          .where(field, isEqualTo: value)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to query users: ${e.toString()}');
    }
  }

  /// Update user field with array operations
  Future<void> updateUserArray({
    required String userId,
    required String field,
    required List<dynamic> elements,
    required bool add, // true for add, false for remove
  }) async {
    try {
      return await _firestore.collection(_userCollection).doc(userId).update({
        field: add ? FieldValue.arrayUnion(elements) : FieldValue.arrayRemove(elements),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update array field: ${e.toString()}');
    }
  }

  /// Batch write operation for multiple users
  Future<void> batchUpdateUsers(
    List<String> userIds,
    Map<String, dynamic> updateData
  ) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (String userId in userIds) {
        DocumentReference docRef = _firestore.collection(_userCollection).doc(userId);
        batch.update(docRef, {
          ...updateData,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      return await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update users: ${e.toString()}');
    }
  }

  /// Listen to real-time updates for a user
  Stream<DocumentSnapshot> userStream(String userId) {
    return _firestore.collection(_userCollection).doc(userId).snapshots();
  }
}