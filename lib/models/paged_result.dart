class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final bool hasNextPage;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasNextPage,
  });

  bool get hasPreviousPage => page > 0;
}
