extension ListChunking<T> on List<T> {
  List<List<T>> chunk(int size) {
    if (size <= 0) throw ArgumentError.value(size, 'size', 'must be > 0');
    if (isEmpty) return [];
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}
