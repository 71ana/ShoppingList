class ShoppingItem {
  final String id;
  final String name;
  final bool isPurchased;
  final double price;

  ShoppingItem({ required this.id, required this.name, this.isPurchased = false, this.price = 0.0});
}
