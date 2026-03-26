class PaginatedResponse<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });
}
