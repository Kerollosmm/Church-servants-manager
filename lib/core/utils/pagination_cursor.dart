/// Domain-level opaque pagination cursor.
/// The data layer maps this to/from Firestore's DocumentSnapshot internally.
class PaginationCursor {
  const PaginationCursor._(this._token);

  final Object _token; // implementation detail hidden

  Object get token => _token;

  static PaginationCursor fromToken(Object token) => PaginationCursor._(token);
}
