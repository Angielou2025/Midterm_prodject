import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign Up Logic
  Future<UserModel?> signUp(String email, String password, String username) async {
    if (password.length < 6) {
      throw FirebaseAuthException(code: 'weak-password', message: 'Kailangan 6 digits ang password.');
    }
    UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    UserModel userModel = UserModel(uid: result.user!.uid, email: email, username: username);

    // Save to Firestore
    await _db.collection('users').doc(result.user!.uid).set(userModel.toMap());
    return userModel;
  }

  // Login Logic
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot doc = await _db.collection('users').doc(result.user!.uid).get();
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } on FirebaseAuthException {
      throw FirebaseAuthException(code: 'invalid-auth', message: 'Invalid email or password. Try again.');
    }
  }

  // Forgot Password Logic
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Stream para malaman kung logged in ang user
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get current user model from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting current user model: $e');
    }
    return null;
  }

  Future<void> logout() async => await _auth.signOut();

  // Update user profile image in Firebase Auth
  Future<void> updateUserProfileImage(String imageUrl) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await currentUser.updatePhotoURL(imageUrl);
    }
  }
}