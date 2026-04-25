extension ListChunking<T> on List<T> {
  List<List<T>> chunk(int size) {
    assert(size > 0);
    if (isEmpty) return [];
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}
