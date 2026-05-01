import 'exceptions.dart';

/// Result type for operations that can fail.
/// Forces callers to handle errors explicitly.
///
/// Usage:
/// ```dart
/// final result = await fetchFlights();
/// result.when(
///   success: (flights) => showFlights(flights),
///   failure: (error) => showError(error.message),
/// );
/// ```
sealed class Result<T> {
  const Result._();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(AirWatchException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  AirWatchException? get errorOrNull => switch (this) {
        Success() => null,
        Failure(error: final e) => e,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(AirWatchException error) failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      Failure(error: final e) => failure(e),
    };
  }

  /// Map success value, pass through failures
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final d) => Result.success(transform(d)),
      Failure(error: final e) => Result.failure(e),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data) : super._();
}

class Failure<T> extends Result<T> {
  final AirWatchException error;
  const Failure(this.error) : super._();
}

/// Helper to wrap async calls in Result
Future<Result<T>> runCatching<T>(Future<T> Function() block) async {
  try {
    return Result.success(await block());
  } catch (e, stack) {
    return Result.failure(wrapException(e, stack));
  }
}
