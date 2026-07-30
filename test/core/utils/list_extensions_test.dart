import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListChunking extension', () {
    test('throws ArgumentError when size is 0 or negative', () {
      final list = [1, 2, 3];
      expect(() => list.chunk(0), throwsArgumentError);
      expect(() => list.chunk(-1), throwsArgumentError);
      expect(() => list.chunk(-10), throwsArgumentError);
    });

    test('returns empty list when target list is empty', () {
      final list = <int>[];
      expect(list.chunk(3), isEmpty);
    });

    test('chunks list correctly when length is an exact multiple of size', () {
      final list = [1, 2, 3, 4, 5, 6];
      final chunks = list.chunk(2);
      expect(
        chunks,
        equals([
          [1, 2],
          [3, 4],
          [5, 6],
        ]),
      );
    });

    test(
      'chunks list correctly when length is not an exact multiple of size',
      () {
        final list = [1, 2, 3, 4, 5];
        final chunks = list.chunk(2);
        expect(
          chunks,
          equals([
            [1, 2],
            [3, 4],
            [5],
          ]),
        );
      },
    );

    test(
      'returns single chunk when chunk size is greater than list length',
      () {
        final list = [1, 2, 3];
        final chunks = list.chunk(10);
        expect(
          chunks,
          equals([
            [1, 2, 3],
          ]),
        );
      },
    );
  });
}
