import '../error/failure.dart';

sealed class AsyncState<T> {
  const AsyncState();
}

class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();
}

class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading({this.previous});

  final T? previous;
}

class AsyncLoaded<T> extends AsyncState<T> {
  const AsyncLoaded(this.data, {this.message});

  final T data;
  final String? message;
}

class AsyncFailure<T> extends AsyncState<T> {
  const AsyncFailure(this.failure, {this.previous});

  final Failure failure;
  final T? previous;
}
