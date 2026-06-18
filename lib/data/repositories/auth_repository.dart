import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Orchestrates authentication + the matching Firestore `users` document.
class AuthRepository {
  AuthRepository(this._authService, this._firestore);

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  Stream<User?> authStateChanges() => _authService.authStateChanges();
  User? get currentAuthUser => _authService.currentUser;

  Future<UserModel?> fetchUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Stream<UserModel?> userProfileStream(String uid) =>
      _users.doc(uid).snapshots().map((d) => d.exists ? UserModel.fromDoc(d) : null);

  Future<Result<UserModel>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final cred = await _authService.signUpWithEmail(email, password);
      final uid = cred.user!.uid;
      final user = UserModel(
        uid: uid,
        role: role,
        name: name,
        email: email,
        phone: phone,
        status: AccountStatus.active,
      );
      await _users.doc(uid).set(user.toMap());
      await _authService.sendEmailVerification();
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(_mapAuthError(e), code: e.code));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  Future<Result<UserModel>> signInWithEmail(
      String email, String password) async {
    try {
      final cred = await _authService.signInWithEmail(email, password);
      final profile = await fetchUserProfile(cred.user!.uid);
      if (profile == null) {
        return const Err(AuthFailure('Account profile not found.'));
      }
      return Success(profile);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(_mapAuthError(e), code: e.code));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  /// Signs in with Google, creating a default customer profile on first login.
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      final cred = await _authService.signInWithGoogle();
      final user = cred.user!;
      final existing = await fetchUserProfile(user.uid);
      if (existing != null) return Success(existing);
      final profile = UserModel(
        uid: user.uid,
        role: UserRole.customer,
        name: user.displayName ?? 'New User',
        email: user.email ?? '',
        phone: user.phoneNumber,
        profileImage: user.photoURL,
        status: AccountStatus.active,
      );
      await _users.doc(user.uid).set(profile.toMap());
      return Success(profile);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(_mapAuthError(e), code: e.code));
    } on GoogleSignInException catch (e) {
      // User dismissing the Google sheet is not an error worth shouting about.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Err(AuthFailure('Sign-in cancelled.', code: 'cancelled'));
      }
      return Err(AuthFailure('Google sign-in error: ${e.description ?? e.code.name}'));
    } on Failure catch (f) {
      return Err(f);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(_mapAuthError(e), code: e.code));
    }
  }

  /// Phone OTP step 1.
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(String error) onError,
  }) {
    return _authService.verifyPhone(
      phoneNumber: phoneNumber,
      codeSent: codeSent,
      onError: (e) => onError(_mapAuthError(e)),
    );
  }

  /// Phone OTP step 2 — confirms code and ensures a profile exists.
  Future<Result<UserModel>> confirmOtp({
    required String verificationId,
    required String smsCode,
    String? name,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final cred =
          await _authService.confirmOtp(verificationId, smsCode);
      final user = cred.user!;
      final existing = await fetchUserProfile(user.uid);
      if (existing != null) return Success(existing);
      final profile = UserModel(
        uid: user.uid,
        role: role,
        name: name ?? 'New User',
        email: user.email ?? '',
        phone: user.phoneNumber,
        status: AccountStatus.active,
      );
      await _users.doc(user.uid).set(profile.toMap());
      return Success(profile);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(_mapAuthError(e), code: e.code));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  Future<void> updateFcmToken(String uid, String token) =>
      _users.doc(uid).update({'fcmToken': token});

  Future<void> signOut() => _authService.signOut();

  String _mapAuthError(FirebaseAuthException e) => switch (e.code) {
        'user-not-found' => 'No account found for that email.',
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'That email is already registered.',
        'weak-password' => 'Password is too weak.',
        'invalid-email' => 'That email address is invalid.',
        'network-request-failed' => 'Network error. Check your connection.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        _ => e.message ?? 'Authentication failed.',
      };
}
