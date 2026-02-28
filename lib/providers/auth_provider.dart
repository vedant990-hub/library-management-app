import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserProfile? _currentUserProfile;
  bool _isLoading = true;

  AppAuthProvider() {
    _initAuthListener();
  }

  UserProfile? get currentUser => _currentUserProfile;
  bool get isAuthenticated => _currentUserProfile != null;
  bool get isLoading => _isLoading;
  String? get role => _currentUserProfile?.role;
  bool get isAdmin => _currentUserProfile?.isAdmin ?? false;

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        _isLoading = true;
        notifyListeners();
        await _fetchOrCreateUserProfile(user);
      } else {
        _currentUserProfile = null;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchOrCreateUserProfile(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        _currentUserProfile = UserProfile.fromMap(docSnap.data()!, docSnap.id);
      } else {
        final String name = user.displayName ?? (user.email != null && user.email!.contains('@') ? user.email!.split('@').first : 'User');
        final newUser = UserProfile(
          uid: user.uid,
          name: name,
          email: user.email ?? '',
          role: 'user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Perform creation in a neat batch
        final batch = _firestore.batch();
        batch.set(docRef, newUser.toMap());
        
        // Setup initial default wallet for the new user
        final walletRef = docRef.collection('wallet').doc('default');
        batch.set(walletRef, {
          'availableBalance': 0.0,
          'lockedDeposit': 0.0,
          'totalFinesPaid': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        await batch.commit();
        _currentUserProfile = newUser;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching/creating user profile: $e');
      }
      _currentUserProfile = null;
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Ensure we clear any previous login attempt which might be stuck
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return; 
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Clear profile immediately so UI shows login screen
      _currentUserProfile = null;
      notifyListeners();

      // Sign out from Google silently (don't block on failure)
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }
}
