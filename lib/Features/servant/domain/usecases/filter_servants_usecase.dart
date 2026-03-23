import 'package:church_management_system/features/servant/data/models/servant_models.dart';

// FIX [P1]: extracted in-memory servant filtering/sorting behind a use case.
class FilterServantsUseCase {
  const FilterServantsUseCase();

  List<ServantModel> call({
    required List<ServantModel> servants,
    String? query,
  }) {
    final normalizedQuery = query?.trim().toLowerCase();
    final filtered = normalizedQuery == null || normalizedQuery.isEmpty
        ? List<ServantModel>.from(servants)
        : servants
              .where(
                (servant) =>
                    servant.name.toLowerCase().contains(normalizedQuery),
              )
              .toList(growable: false);
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }
}
