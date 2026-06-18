import 'failure.dart';

/// Lightweight sealed Result type used by repositories so callers can handle
/// success/failure without try/catch sprawling through the UI.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    return failure((self as Err<T>).failure);
  }

  /// Returns the data on success or null on failure.
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
