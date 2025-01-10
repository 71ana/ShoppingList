class ShoppingItem {
  final String id;
  final String name;
  final String quantity;
  final bool isPurchased;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isPurchased,
    required this.createdAt,
  });
}
