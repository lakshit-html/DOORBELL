/// Domain-level error type. Repositories translate raw exceptions
/// (FirebaseException, PlatformException, SocketException…) into a [Failure]
/// so the UI layer never depends on Firebase types directly.
class Failure implements Exception {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}
