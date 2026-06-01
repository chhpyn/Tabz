import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // Store temporary Google user data for new users
  String? _tempGoogleName;
  String? _tempGoogleEmail;
  String? _tempGooglePhotoUrl;
  String? _tempGoogleUid;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  
  // Getters for temporary Google data
  String? get tempGoogleName => _tempGoogleName;
  String? get tempGoogleEmail => _tempGoogleEmail;
  String? get tempGooglePhotoUrl => _tempGooglePhotoUrl;
  String? get tempGoogleUid => _tempGoogleUid;
  
  bool get hasGooglePendingSignUp => _tempGoogleUid != null;

  /// Initialize authentication state (checks for existing Firebase session)
  Future<void> initializeAuth() async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentFirebaseUser = FirebaseAuth.instance.currentUser;
      
      if (currentFirebaseUser != null) {
        // User has an existing Firebase session, fetch their profile from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentFirebaseUser.uid)
            .get();

        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data()!);
          _isAuthenticated = true;
        } else {
          // Firebase session exists but no profile in Firestore, sign out
          await FirebaseAuth.instance.signOut();
          _isAuthenticated = false;
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication';
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Fetch user data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'User profile not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(
    String name,
    String email,
    String password,
    String username,
    String? profileImageUrl,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create Firebase Auth user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
      String? savedImagePath = profileImageUrl;

      // Save image to app documents if provided
      if (profileImageUrl != null && File(profileImageUrl).existsSync()) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final imageName = 'profile_${userCredential.user!.uid}.jpg';
          final savedImage =
              await File(profileImageUrl).copy('${appDir.path}/$imageName');
          savedImagePath = savedImage.path;
        } catch (e) {
          // If image save fails, continue without it
          savedImagePath = null;
        }
      }

      // Create user document in Firestore
      final newUser = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        username: cleanUsername,
        profileImageUrl: savedImagePath,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toMap());

      _currentUser = newUser;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(
    String name,
    String username, {
    String? imagePath,
  }) async {
    if (_currentUser == null) return false;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
      String? imageUrl = _currentUser!.profileImageUrl;

      // Save new image to app documents if provided
      if (imagePath != null && File(imagePath).existsSync()) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final imageName = 'profile_${_currentUser!.id}.jpg';
          final savedImage = await File(imagePath).copy('${appDir.path}/$imageName');
          imageUrl = savedImage.path;
        } catch (e) {
          // If image save fails, keep existing image
          imageUrl = _currentUser!.profileImageUrl;
        }
      }

      final updatedUser = UserModel(
        id: _currentUser!.id,
        name: name,
        email: _currentUser!.email,
        username: cleanUsername,
        profileImageUrl: imageUrl,
      );

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .update(updatedUser.toMap());

      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if user exists in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // User doesn't exist - store Google data for sign-up flow
        _tempGoogleName = googleUser.displayName ?? 'User';
        _tempGoogleEmail = googleUser.email;
        _tempGooglePhotoUrl = googleUser.photoUrl;
        _tempGoogleUid = userCredential.user!.uid;
        
        // Sign out from Firebase to allow re-authentication during sign-up
        await FirebaseAuth.instance.signOut();
        
        _errorMessage = 'Account not found. Please sign up first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Google sign-in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithGoogle(
    String name,
    String username,
    String? profileImageUrl,
  ) async {
    if (_tempGoogleUid == null || _tempGoogleEmail == null) {
      _errorMessage = 'Google sign-up data not found. Please try again.';
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
      String? savedImagePath = profileImageUrl ?? _tempGooglePhotoUrl;

      // Save image to app documents if provided
      if (profileImageUrl != null && File(profileImageUrl).existsSync()) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final imageName = 'profile_${_tempGoogleUid}.jpg';
          final savedImage =
              await File(profileImageUrl).copy('${appDir.path}/$imageName');
          savedImagePath = savedImage.path;
        } catch (e) {
          // If image save fails, continue without new image
          savedImagePath = _tempGooglePhotoUrl;
        }
      }

      // Create user document in Firestore using the stored Google UID
      final newUser = UserModel(
        id: _tempGoogleUid!,
        name: name,
        email: _tempGoogleEmail!,
        username: cleanUsername,
        profileImageUrl: savedImagePath,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_tempGoogleUid!)
          .set(newUser.toMap());

      // Now sign in with the stored Google credentials
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      _currentUser = newUser;
      _isAuthenticated = true;
      
      // Clear temporary Google data
      _tempGoogleName = null;
      _tempGoogleEmail = null;
      _tempGooglePhotoUrl = null;
      _tempGoogleUid = null;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete Google sign-up: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearGoogleSignUpData() {
    _tempGoogleName = null;
    _tempGoogleEmail = null;
    _tempGooglePhotoUrl = null;
    _tempGoogleUid = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      clearGoogleSignUpData();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to logout';
      notifyListeners();
    }
  }
}
