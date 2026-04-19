sealed class HttpResponseOutput<T> {}

class HttpValidResponseOutput<T> implements HttpResponseOutput<T> {
  final T value;

  const HttpValidResponseOutput(this.value);
}

class HttpInvalidResponseOutput<T> implements HttpResponseOutput<T> {
  final String? contents;
  const HttpInvalidResponseOutput({this.contents});
}
