import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_model.dart';

/// Raw FirebaseAuth state — null when signed out.
final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// ── STABLE UID PROVIDER ──
/// This emits only the UID string. It does NOT depend on the Firestore profile,
/// so downstream providers that only need the UID won't rebuild when profile
/// fields change (name, phone, fcmToken, etc.).
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// The signed-in user's Firestore profile (role, name, status). Drives routing.
/// This still watches the full profile stream, but providers that only need
/// UID should use [currentUidProvider] instead.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).userProfileStream(uid);
});

/// Convenience: current role (defaults to customer while loading).
final currentRoleProvider = Provider<UserRole?>(
    (ref) => ref.watch(currentUserProvider).value?.role);

/// Imperative auth actions with a shared loading/error state for the UI.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signUpWithEmail(
        name: name, email: email, password: password, role: role, phone: phone);
    return _handle(result);
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result =
        await ref.read(authRepositoryProvider).signInWithEmail(email, password);
    return _handle(result);
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    return _handle(result);
  }

  Future<bool> confirmOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).confirmOtp(
        verificationId: verificationId, smsCode: smsCode, name: name);
    return _handle(result);
  }

  Future<String?> sendPasswordReset(String email) async {
    final result = await ref.read(authRepositoryProvider).sendPasswordReset(email);
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  /// Maps a [Result] into [state], returning true on success.
  bool _handle(dynamic result) {
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f, StackTrace.current);
        return false;
      },
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
