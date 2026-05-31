import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/servant/domain/entities/servant.dart';

class ServantsPage {
  final List<Servant> servants;
  final PaginationCursor? lastDocument;
  final bool hasMore;

  const ServantsPage({
    required this.servants,
    this.lastDocument,
    required this.hasMore,
  });
}
