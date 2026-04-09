extension ListChunking<T> on List<T> {
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}
