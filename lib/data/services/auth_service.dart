import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/error/failure.dart';

/// Thin wrapper around FirebaseAuth + Google Sign-In. Repositories build on top
/// of this; UI never touches FirebaseAuth directly.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> sendEmailVerification() async =>
      _auth.currentUser?.sendEmailVerification();

  /// Google Sign-In using the v7+ singleton API.
  ///
  /// On Android the OAuth server-client id is read from google-services.json
  /// (R.string.default_web_client_id), so the google-services Gradle plugin must
  /// be applied and your signing SHA-1 registered in Firebase.
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final account = await googleSignIn.authenticate();
    final auth = account.authentication;
    if (auth.idToken == null) {
      throw const AuthFailure(
          'Google did not return an ID token. Check that Google sign-in is '
          'enabled in Firebase and your SHA-1 is registered.');
    }
    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
    return _auth.signInWithCredential(credential);
  }

  /// Phone OTP — step 1: trigger verification.
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(FirebaseAuthException e) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (cred) => onAutoVerified?.call(cred),
      verificationFailed: onError,
      codeSent: (verificationId, _) => codeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Phone OTP — step 2: confirm the 6-digit code.
  Future<UserCredential> confirmOtp(String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
